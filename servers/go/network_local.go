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

// register local-only routes alongside existing ones
func init() {
    // augment existing registerRoutes via default mux only if main uses it
}

// Handler: GET /go/network/devices (local machine)
func networkDevicesLocalHandler(w http.ResponseWriter, r *http.Request) {
    devs := discoverDevicesLocal()
    if devs == nil { devs = []NetDevice{} }
    w.Header().Set("Content-Type", "application/json")
    _ = json.NewEncoder(w).Encode(devs)
}

// Handler: GET /go/network/packets?ip=1.2.3.4 (local capture)
func networkPacketsLocalHandler(w http.ResponseWriter, r *http.Request) {
    ip := strings.TrimSpace(r.URL.Query().Get("ip"))
    if ip == "" {
        http.Error(w, "missing ip", http.StatusBadRequest)
        return
    }
    packets, err := capturePacketsLocal(ip, 10, 3*time.Second)
    if err != nil {
        http.Error(w, err.Error(), http.StatusBadGateway)
        return
    }
    w.Header().Set("Content-Type", "application/json")
    _ = json.NewEncoder(w).Encode(packets)
}

// Discover devices using OS tools (ARP table)
func discoverDevicesLocal() []NetDevice {
    out := ""
    if runtime.GOOS == "windows" {
        b, _ := exec.Command("arp", "-a").CombinedOutput()
        out = string(b)
    } else if runtime.GOOS == "darwin" {
        b, _ := exec.Command("arp", "-an").CombinedOutput()
        out = string(b)
    } else {
        // linux
        if b, err := exec.Command("ip", "-j", "neigh").CombinedOutput(); err == nil && len(b) > 0 {
            type neigh struct{ Dst, Lladdr, Dev, State string }
            var ns []neigh
            if json.Unmarshal(b, &ns) == nil {
                var res []NetDevice
                for _, n := range ns {
                    res = append(res, NetDevice{IP: n.Dst, MAC: n.Lladdr, Vendor: "Unknown", Hostname: n.Dst, DeviceType: n.Dev})
                }
                return res
            }
        }
        b, _ := exec.Command("ip", "neigh").CombinedOutput()
        out = string(b)
    }

    var res []NetDevice
    for _, ln := range strings.Split(out, "\n") {
        ln = strings.TrimSpace(ln)
        if ln == "" { continue }
        // crude parse ip/mac
        ip := ""; mac := ""; dev := ""
        f := strings.Fields(ln)
        for i := 0; i < len(f); i++ {
            if ip == "" && (net.ParseIP(strings.Trim(f[i], "()")) != nil) { ip = strings.Trim(f[i], "()") }
            if f[i] == "lladdr" && i+1 < len(f) { mac = f[i+1] }
            if f[i] == "dev" && i+1 < len(f) { dev = f[i+1] }
        }
        if ip == "" && len(f) > 0 && net.ParseIP(f[0]) != nil { ip = f[0] }
        if ip != "" {
            res = append(res, NetDevice{ IP: ip, MAC: mac, Vendor: "Unknown", Hostname: ip, DeviceType: dev })
        }
    }
    return res
}

func capturePacketsLocal(ip string, count int, timeout time.Duration) ([]NetPacket, error) {
    // Pick first device that has the IP in addresses; else first device
    devices, err := pcap.FindAllDevs()
    if err != nil { return nil, fmt.Errorf("pcap devices: %w", err) }
    if len(devices) == 0 { return nil, fmt.Errorf("no pcap devices") }

    devName := devices[0].Name
    for _, d := range devices {
        for _, addr := range d.Addresses {
            if addr.IP != nil && addr.IP.String() == ip { devName = d.Name; break }
        }
    }

    handle, err := pcap.OpenLive(devName, 65535, true, pcap.BlockForever)
    if err != nil { return nil, fmt.Errorf("open %s: %w", devName, err) }
    defer handle.Close()
    if err := handle.SetBPFFilter(fmt.Sprintf("host %s", ip)); err != nil {
        return nil, fmt.Errorf("bpf: %w", err)
    }

    src := gopacket.NewPacketSource(handle, handle.LinkType())
    packets := make([]NetPacket, 0, count)
    deadline := time.Now().Add(timeout)
    for pkt := range src.Packets() {
        if time.Now().After(deadline) || len(packets) >= count { break }
        n := NetPacket{ Time: time.Now().Format(time.RFC3339Nano), Size: len(pkt.Data()) }
        if net := pkt.NetworkLayer(); net != nil {
            n.Source = net.NetworkFlow().Src().String()
            n.Destination = net.NetworkFlow().Dst().String()
            n.Protocol = net.LayerType().String()
        } else if tl := pkt.TransportLayer(); tl != nil {
            n.Protocol = tl.LayerType().String()
        } else {
            n.Protocol = "Unknown"
        }
        n.Info = pkt.String()
        packets = append(packets, n)
        if len(packets) >= count { break }
    }
    return packets, nil
}


