package main

import (
	"encoding/json"
	"fmt"
	"net"
	"net/http"
	"os/exec"
	"runtime"
	"strings"
	"time"

	"github.com/google/gopacket"
	"github.com/google/gopacket/pcap"
)

type NetDevice struct {
    IP         string `json:"ip"`
    MAC        string `json:"mac"`
    Vendor     string `json:"vendor"`
    Hostname   string `json:"hostname"`
    DeviceType string `json:"device_type"`
}

type NetPacket struct {
    Time        string `json:"time"`
    Source      string `json:"source"`
    Destination string `json:"destination"`
    Protocol    string `json:"protocol"`
    Size        int    `json:"size"`
    Info        string `json:"info"`
}

func init() {
}

func networkDevicesHandler(w http.ResponseWriter, r *http.Request) {
    devs := discoverDevices()
    if devs == nil { devs = []NetDevice{} }
    w.Header().Set("Content-Type", "application/json")
    _ = json.NewEncoder(w).Encode(devs)
}

func networkPacketsHandler(w http.ResponseWriter, r *http.Request) {
    ip := strings.TrimSpace(r.URL.Query().Get("ip"))
    if ip == "" {
        http.Error(w, "missing ip", http.StatusBadRequest)
        return
    }
    packets, err := capturePackets(ip, 10, 3*time.Second)
    if err != nil {
        http.Error(w, err.Error(), http.StatusBadGateway)
        return
    }
    w.Header().Set("Content-Type", "application/json")
    _ = json.NewEncoder(w).Encode(packets)
}

// Discover network devices (scanning network like an attacker)
func discoverDevices() []NetDevice {
    var res []NetDevice
    
    // Scan ARP table for devices in network (like an attacker would)
    out := ""
    if runtime.GOOS == "windows" {
        b, _ := exec.Command("arp", "-a").CombinedOutput()
        out = string(b)
    } else if runtime.GOOS == "darwin" {
        b, _ := exec.Command("arp", "-an").CombinedOutput()
        out = string(b)
    } else {
        // linux - try JSON first, fallback to plain
        if b, err := exec.Command("ip", "-j", "neigh").CombinedOutput(); err == nil && len(b) > 0 {
            type neigh struct{ Dst, Lladdr, Dev, State string }
            var ns []neigh
            if json.Unmarshal(b, &ns) == nil {
                for _, n := range ns {
                    // Only include reachable/active devices (targets for packet capture)
                    if strings.Contains(strings.ToLower(n.State), "reachable") || 
                       strings.Contains(strings.ToLower(n.State), "stale") ||
                       strings.Contains(strings.ToLower(n.State), "delay") {
                        res = append(res, NetDevice{
                            IP: n.Dst, 
                            MAC: n.Lladdr, 
                            Vendor: "Unknown", 
                            Hostname: n.Dst, 
                            DeviceType: n.Dev,
                        })
                    }
                }
                return res
            }
        }
        b, _ := exec.Command("ip", "neigh").CombinedOutput()
        out = string(b)
    }

    // Parse ARP table output to find network devices (potential targets)
    for _, ln := range strings.Split(out, "\n") {
        ln = strings.TrimSpace(ln)
        if ln == "" { continue }
        
        ip := ""; mac := ""; dev := ""
        f := strings.Fields(ln)
        
        // Parse different ARP output formats:
        // Windows: 192.168.1.100    aa-bb-cc-dd-ee-ff     dynamic
        // Linux: 192.168.1.100 dev eth0 lladdr aa:bb:cc:dd:ee:ff REACHABLE
        // macOS: 192.168.1.100 (192.168.1.100) at aa:bb:cc:dd:ee:ff on en0
        
        for i := 0; i < len(f); i++ {
            // Find IP address
            if ip == "" {
                testIP := strings.Trim(f[i], "()")
                if net.ParseIP(testIP) != nil {
                    ip = testIP
                }
            }
            // Find MAC address patterns
            if mac == "" {
                if strings.Contains(f[i], ":") && len(f[i]) >= 17 { // aa:bb:cc:dd:ee:ff
                    mac = f[i]
                } else if strings.Contains(f[i], "-") && len(f[i]) >= 17 { // aa-bb-cc-dd-ee-ff
                    mac = strings.ReplaceAll(f[i], "-", ":")
                }
            }
            // Find device/interface
            if f[i] == "dev" && i+1 < len(f) { dev = f[i+1] }
            if f[i] == "on" && i+1 < len(f) { dev = f[i+1] }
        }
        
        // Only add devices with valid IP and MAC (real network targets)
        // Skip localhost and invalid entries
        if ip != "" && mac != "" && ip != "127.0.0.1" && !strings.Contains(ip, "169.254") {
            res = append(res, NetDevice{ 
                IP: ip, 
                MAC: mac, 
                Vendor: "Unknown", 
                Hostname: ip, 
                DeviceType: dev,
            })
        }
    }
    return res
}

// Capture packets from target device (like an attacker intercepting traffic)
func capturePackets(targetIP string, count int, timeout time.Duration) ([]NetPacket, error) {
    // Find network interfaces
    devices, err := pcap.FindAllDevs()
    if err != nil { return nil, fmt.Errorf("pcap devices: %w", err) }
    if len(devices) == 0 { return nil, fmt.Errorf("no pcap devices") }

    // Find the best interface for capturing target's traffic
    var devName string
    for _, d := range devices {
        // Skip loopback
        if strings.Contains(strings.ToLower(d.Name), "loopback") { continue }
        
        // Check if this interface is on the same network as target
        for _, addr := range d.Addresses {
            if addr.IP != nil && addr.Netmask != nil {
                network := addr.IP.Mask(addr.Netmask)
                targetIPNet := net.ParseIP(targetIP)
                if targetIPNet != nil {
                    targetNetwork := targetIPNet.Mask(addr.Netmask)
                    if network.Equal(targetNetwork) {
                        devName = d.Name
                        break
                    }
                }
            }
        }
        if devName != "" { break }
    }
    
    // Fallback to first non-loopback interface
    if devName == "" {
        for _, d := range devices {
            if !strings.Contains(strings.ToLower(d.Name), "loopback") {
                devName = d.Name
                break
            }
        }
    }
    
    if devName == "" {
        return nil, fmt.Errorf("no suitable network interface found")
    }

    // Open interface in promiscuous mode (to capture other devices' traffic)
    handle, err := pcap.OpenLive(devName, 65535, true, pcap.BlockForever)
    if err != nil { return nil, fmt.Errorf("open %s (try running as admin/root): %w", devName, err) }
    defer handle.Close()
    
    // Set filter to capture packets to/from target IP
    filter := fmt.Sprintf("host %s", targetIP)
    if err := handle.SetBPFFilter(filter); err != nil {
        return nil, fmt.Errorf("bpf filter '%s': %w", filter, err)
    }

    src := gopacket.NewPacketSource(handle, handle.LinkType())
    packets := make([]NetPacket, 0, count)
    deadline := time.Now().Add(timeout)
    
    for pkt := range src.Packets() {
        if time.Now().After(deadline) || len(packets) >= count { break }
        
        n := NetPacket{ 
            Time: time.Now().Format("15:04:05.000"), 
            Size: len(pkt.Data()),
            Protocol: "Unknown",
            Source: "Unknown",
            Destination: "Unknown",
            Info: "Raw packet",
        }
        
        // Parse network layer (IP)
        if netLayer := pkt.NetworkLayer(); netLayer != nil {
            n.Source = netLayer.NetworkFlow().Src().String()
            n.Destination = netLayer.NetworkFlow().Dst().String()
            n.Protocol = netLayer.LayerType().String()
        }
        
        // Parse transport layer (TCP/UDP)
        if transLayer := pkt.TransportLayer(); transLayer != nil {
            n.Protocol = transLayer.LayerType().String()
            // Add port info
            if n.Source != "Unknown" {
                n.Source += ":" + transLayer.TransportFlow().Src().String()
            }
            if n.Destination != "Unknown" {
                n.Destination += ":" + transLayer.TransportFlow().Dst().String()
            }
        }
        
        // Parse application layer for more info
        if appLayer := pkt.ApplicationLayer(); appLayer != nil {
            payload := appLayer.Payload()
            if len(payload) > 0 {
                // Try to identify protocol by payload
                payloadStr := string(payload[:min(50, len(payload))])
                if strings.Contains(payloadStr, "HTTP") {
                    n.Info = "HTTP traffic"
                } else if strings.Contains(payloadStr, "DNS") {
                    n.Info = "DNS query/response"
                } else {
                    n.Info = fmt.Sprintf("Data: %d bytes", len(payload))
                }
            }
        }
        
        packets = append(packets, n)
        if len(packets) >= count { break }
    }
    return packets, nil
}

func min(a, b int) int {
    if a < b { return a }
    return b
}


