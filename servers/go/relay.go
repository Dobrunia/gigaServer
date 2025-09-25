package main

import (
	"context"
	"encoding/json"
	"fmt"
	"log"
	"net/http"
	"strconv"
	"time"

	"regexp"
	"strings"

	"golang.org/x/crypto/ssh"
)

type SSHConfig struct {
    Host     string `json:"host"`
    User     string `json:"user"`
    Port     int    `json:"port"`
    Password string `json:"password,omitempty"`
}

type SSHExecuteReq struct {
    Command string `json:"command"`
}

var lastSSH SSHConfig
var sshClient *ssh.Client
var keepAliveStop chan struct{}
var lastActivity time.Time
var currentWorkingDir string = ""

// For network speed calculation
type NetworkStats struct {
    RxBytes int64
    TxBytes int64
    Timestamp time.Time
}
var lastNetworkStats NetworkStats

func withCORS(next http.Handler) http.Handler {
    return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
        w.Header().Set("Access-Control-Allow-Origin", "*")
        w.Header().Set("Access-Control-Allow-Headers", "Content-Type")
        w.Header().Set("Access-Control-Allow-Methods", "GET,POST,OPTIONS")
        if r.Method == http.MethodOptions {
            log.Printf("http %s %s preflight from %s", r.Method, r.URL.Path, clientIP(r))
            w.WriteHeader(http.StatusNoContent)
            return
        }
        next.ServeHTTP(w, r)
    })
}

// withLogging — простой логгер запросов
func withLogging(name string, next http.Handler) http.Handler {
    return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
        started := time.Now()
        next.ServeHTTP(w, r)
        log.Printf("http %s %s %s %s (%s)", r.Method, r.URL.Path, name, clientIP(r), time.Since(started))
    })
}

func clientIP(r *http.Request) string {
    if xf := r.Header.Get("X-Forwarded-For"); xf != "" { return xf }
    if xr := r.Header.Get("X-Real-Ip"); xr != "" { return xr }
    return r.RemoteAddr
}

func sshConnectHandler(w http.ResponseWriter, r *http.Request) {
    if r.Method != http.MethodPost {
        http.Error(w, "method not allowed", http.StatusMethodNotAllowed)
        return
    }
    log.Printf("ssh_connect request from %s", clientIP(r))
    var cfg SSHConfig
    if err := json.NewDecoder(r.Body).Decode(&cfg); err != nil {
        log.Printf("ssh_connect decode error: %v", err)
        http.Error(w, err.Error(), http.StatusBadRequest)
        return
    }
    if cfg.Port == 0 { cfg.Port = 22 }
    lastSSH = cfg
    log.Printf("received SSH config: host=%s user=%s port=%d pwd_set=%t", cfg.Host, cfg.User, cfg.Port, cfg.Password != "")
    // Тестовое подключение
    connected := false
    msg := ""
    if err := testSSH(cfg); err != nil {
        msg = err.Error()
        log.Printf("ssh test failed: %v", err)
    } else {
        connected = true
        msg = "ok"
        log.Printf("ssh test success: %s@%s:%d", cfg.User, cfg.Host, cfg.Port)
    }
    if connected {
        // establish persistent client and keepalive
        _ = establishSSH(lastSSH)
    }
    w.Header().Set("Content-Type", "application/json")
    _ = json.NewEncoder(w).Encode(map[string]any{"ok": true, "connected": connected, "message": msg})
}

// WS полностью отключён в pull-модели

func healthHandler(w http.ResponseWriter, r *http.Request) {
    w.Header().Set("Content-Type", "application/json")
    fmt.Fprint(w, `{"ok":true}`)
}

func sshStatusHandler(w http.ResponseWriter, r *http.Request) {
    w.Header().Set("Content-Type", "application/json")
    connected := sshClient != nil
    host := ""
    if connected && lastSSH.Host != "" {
        host = lastSSH.Host
    }
    _ = json.NewEncoder(w).Encode(map[string]any{
        "connected": connected,
        "host": host,
        "user": lastSSH.User,
        "current_dir": currentWorkingDir,
    })
}

func registerRoutes(mux *http.ServeMux) {
    mux.Handle("/go/ssh/connect", withLogging("ssh_connect", withCORS(http.HandlerFunc(sshConnectHandler))))
    mux.Handle("/go/ssh/disconnect", withLogging("ssh_disconnect", withCORS(http.HandlerFunc(sshDisconnectHandler))))
    mux.Handle("/go/ssh/execute", withLogging("ssh_execute", withCORS(http.HandlerFunc(sshExecuteHandler))))
    mux.Handle("/go/data/processes", withLogging("processes", withCORS(http.HandlerFunc(processesHandler))))
    mux.Handle("/go/data/ports", withLogging("ports", withCORS(http.HandlerFunc(portsHandler))))
    mux.Handle("/go/data/connections", withLogging("connections", withCORS(http.HandlerFunc(connectionsHandler))))
    mux.Handle("/go/data/client-ips", withLogging("client_ips", withCORS(http.HandlerFunc(clientIpsHandler))))
    mux.Handle("/go/data/process-logs", withLogging("process_logs", withCORS(http.HandlerFunc(processLogsHandler))))
    mux.Handle("/go/data/resources", withLogging("resources", withCORS(http.HandlerFunc(resourcesHandler))))
    mux.Handle("/go/data/network", withLogging("network", withCORS(http.HandlerFunc(networkHandler))))
    mux.Handle("/health", withLogging("health", withCORS(http.HandlerFunc(healthHandler))))
    mux.Handle("/go/ssh/status", withLogging("ssh_status", withCORS(http.HandlerFunc(sshStatusHandler))))
}

// testSSH — пробует выполнить короткое SSH-подключение и команду 'echo ok'
func testSSH(cfg SSHConfig) error {
    var auths []ssh.AuthMethod
    if cfg.Password != "" {
        auths = append(auths, ssh.Password(cfg.Password))
    } else {
        return fmt.Errorf("no password provided")
    }
    conf := &ssh.ClientConfig{
        User:            cfg.User,
        Auth:            auths,
        HostKeyCallback: ssh.InsecureIgnoreHostKey(),
        Timeout:         5 * time.Second,
    }
    addr := fmt.Sprintf("%s:%d", cfg.Host, cfg.Port)
    client, err := ssh.Dial("tcp", addr, conf)
    if err != nil {
        return err
    }
    defer client.Close()
    session, err := client.NewSession()
    if err != nil { return err }
    defer session.Close()
    if err := session.Run("echo ok"); err != nil { return err }
    return nil
}

func sshDisconnectHandler(w http.ResponseWriter, r *http.Request) {
    if r.Method != http.MethodPost {
        http.Error(w, "method not allowed", http.StatusMethodNotAllowed)
        return
    }
    if keepAliveStop != nil { close(keepAliveStop); keepAliveStop = nil }
    if sshClient != nil { _ = sshClient.Close(); sshClient = nil }
    currentWorkingDir = "" // Reset working directory
    lastNetworkStats = NetworkStats{} // Reset network stats
    log.Printf("ssh disconnect requested")
    w.Header().Set("Content-Type", "application/json")
    _ = json.NewEncoder(w).Encode(map[string]any{"ok": true, "connected": false})
}

func sshExecuteHandler(w http.ResponseWriter, r *http.Request) {
    if r.Method != http.MethodPost {
        http.Error(w, "method not allowed", http.StatusMethodNotAllowed)
        return
    }
    var req SSHExecuteReq
    if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
        http.Error(w, err.Error(), http.StatusBadRequest)
        return
    }
    output, err := runSSH(req.Command, 10*time.Second)
    if err != nil {
        http.Error(w, err.Error(), http.StatusBadGateway)
        return
    }
    w.Header().Set("Content-Type", "text/plain")
    fmt.Fprint(w, output)
}

// establish persistent ssh client and keepalive pinger
func establishSSH(cfg SSHConfig) error {
    if sshClient != nil { _ = sshClient.Close(); sshClient = nil }
    // Reset working directory for new connection
    currentWorkingDir = ""
    // Reset network stats for new connection
    lastNetworkStats = NetworkStats{}
    conf := &ssh.ClientConfig{
        User: cfg.User,
        Auth: buildAuth(cfg),
        HostKeyCallback: ssh.InsecureIgnoreHostKey(),
        Timeout: 5 * time.Second,
    }
    c, err := ssh.Dial("tcp", fmt.Sprintf("%s:%d", cfg.Host, cfg.Port), conf)
    if err != nil { return err }
    sshClient = c
    if keepAliveStop != nil { close(keepAliveStop) }
    keepAliveStop = make(chan struct{})
    lastActivity = time.Now()
    go func() {
        t := time.NewTicker(25 * time.Second)
        defer t.Stop()
        for {
            select {
            case <-keepAliveStop:
                return
            case <-t.C:
                // Check for inactivity timeout (1 minute)
                if time.Since(lastActivity) > 60*time.Second {
                    log.Printf("ssh connection idle timeout, disconnecting")
                    if sshClient != nil { _ = sshClient.Close(); sshClient = nil }
                    return
                }
                // Send keepalive ping (but don't update lastActivity for this)
                tempActivity := lastActivity
                if _, err := runSSH("echo ping", 3*time.Second); err != nil {
                    log.Printf("ssh keepalive failed: %v", err)
                }
                lastActivity = tempActivity // Restore original activity time
            }
        }
    }()
    return nil
}

func buildAuth(cfg SSHConfig) []ssh.AuthMethod {
    var auths []ssh.AuthMethod
    if cfg.Password != "" { 
        auths = append(auths, ssh.Password(cfg.Password)) 
    }
    return auths
}

func runSSH(cmd string, timeout time.Duration) (string, error) {
    if sshClient == nil { return "", fmt.Errorf("ssh not connected") }
    lastActivity = time.Now() // Update activity timestamp
    
    // Handle cd command specially
    if strings.HasPrefix(strings.TrimSpace(cmd), "cd ") {
        return handleCdCommand(cmd, timeout)
    }
    
    // Prepend cd to current working directory if set
    fullCmd := cmd
    
    // Handle pwd command to show current directory
    if strings.TrimSpace(cmd) == "pwd" {
        if currentWorkingDir != "" {
            return currentWorkingDir, nil
        }
        // else: fullCmd is already "pwd", continue with normal execution
    }
    if currentWorkingDir != "" {
        fullCmd = fmt.Sprintf("cd %s && %s", currentWorkingDir, cmd)
    }
    
    ctx, cancel := context.WithTimeout(context.Background(), timeout)
    defer cancel()
    session, err := sshClient.NewSession()
    if err != nil { return "", err }
    defer session.Close()
    type result struct{ out []byte; err error }
    ch := make(chan result, 1)
    go func(){ out, err := session.CombinedOutput(fullCmd); ch <- result{out, err} }()
    select {
    case <-ctx.Done():
        _ = session.Signal(ssh.SIGKILL)
        return "", fmt.Errorf("ssh command timeout")
    case r := <-ch:
        return string(r.out), r.err
    }
}

func handleCdCommand(cmd string, timeout time.Duration) (string, error) {
    // Extract directory from cd command
    parts := strings.Fields(strings.TrimSpace(cmd))
    if len(parts) < 2 {
        // cd without arguments - go to home directory
        currentWorkingDir = ""
        return "Changed to home directory", nil
    }
    
    targetDir := parts[1]
    
    // Handle relative paths
    var testCmd string
    if strings.HasPrefix(targetDir, "/") {
        // Absolute path
        testCmd = fmt.Sprintf("cd %s && pwd", targetDir)
    } else {
        // Relative path
        if currentWorkingDir != "" {
            testCmd = fmt.Sprintf("cd %s && cd %s && pwd", currentWorkingDir, targetDir)
        } else {
            testCmd = fmt.Sprintf("cd %s && pwd", targetDir)
        }
    }
    
    // Test if directory exists and get absolute path
    ctx, cancel := context.WithTimeout(context.Background(), timeout)
    defer cancel()
    session, err := sshClient.NewSession()
    if err != nil { return "", err }
    defer session.Close()
    
    type result struct{ out []byte; err error }
    ch := make(chan result, 1)
    go func(){ out, err := session.CombinedOutput(testCmd); ch <- result{out, err} }()
    
    select {
    case <-ctx.Done():
        _ = session.Signal(ssh.SIGKILL)
        return "", fmt.Errorf("ssh command timeout")
    case r := <-ch:
        if r.err != nil {
            return "", fmt.Errorf("cd: %s: No such file or directory", targetDir)
        }
        // Update current working directory to the absolute path
        currentWorkingDir = strings.TrimSpace(string(r.out))
        return fmt.Sprintf("Changed directory to: %s", currentWorkingDir), nil
    }
}

func processesHandler(w http.ResponseWriter, r *http.Request) {
    out, err := runSSH("ps -eo pid,user,comm,pcpu,rss --sort=-pcpu | head -n 15", 2*time.Second)
    if err != nil { http.Error(w, err.Error(), http.StatusBadGateway); return }
    rows := parsePs(out)
    w.Header().Set("Content-Type", "application/json")
    _ = json.NewEncoder(w).Encode(map[string]any{"rows": rows})
}

func portsHandler(w http.ResponseWriter, r *http.Request) {
    out, err := runSSH("ss -lntup", 2*time.Second)
    if err != nil { http.Error(w, err.Error(), http.StatusBadGateway); return }
    rows := parseSs(out)
    w.Header().Set("Content-Type", "application/json")
    _ = json.NewEncoder(w).Encode(map[string]any{"rows": rows})
}

func parsePs(out string) []map[string]any {
    lines := strings.Split(out, "\n")
    res := make([]map[string]any, 0, len(lines))
    for i, ln := range lines {
        if i == 0 || strings.TrimSpace(ln) == "" { continue }
        f := strings.Fields(ln)
        if len(f) < 5 { continue }
        
        pid := f[0]; user := f[1]; name := f[2]; cpu := f[3]; rss := f[4]
        
        // Validate and sanitize data
        cpuVal := "0.0"
        if cpuFloat, err := strconv.ParseFloat(cpu, 64); err == nil {
            if cpuFloat >= 0 && cpuFloat <= 999 {
                cpuVal = fmt.Sprintf("%.1f", cpuFloat)
            }
        }
        
        rssVal := "0"
        if rssInt, err := strconv.ParseInt(rss, 10, 64); err == nil {
            if rssInt >= 0 && rssInt <= 1024*1024*1024 { // Max 1GB RSS
                rssVal = fmt.Sprintf("%d", rssInt/1024) // Convert to MB
            }
        }
        
        // Sanitize strings
        if len(pid) > 10 { pid = pid[:10] }
        if len(user) > 20 { user = user[:20] }
        if len(name) > 30 { name = name[:30] }
        
        res = append(res, map[string]any{
            "pid": pid, 
            "user": user, 
            "name": name, 
            "cmd": name, 
            "cpu": cpuVal, 
            "rss": rssVal,
        })
    }
    return res
}

var rePid = regexp.MustCompile(`pid=(\d+)`)
var reName = regexp.MustCompile(`"([^"]+)"`)

func parseSs(out string) []map[string]any {
    lines := strings.Split(out, "\n")
    res := make([]map[string]any, 0, len(lines))
    for i, ln := range lines {
        if i == 0 || strings.TrimSpace(ln) == "" { continue }
        // columns end with local address:port ... users:(("proc",pid=1234, ...))
        f := strings.Fields(ln)
        if len(f) < 5 { continue }
        proto := f[0]
        // try find Local Address:Port: usually f[4]
        local := f[4]
        pid := ""
        proc := ""
        if m := rePid.FindStringSubmatch(ln); len(m) > 1 { pid = m[1] }
        if m := reName.FindStringSubmatch(ln); len(m) > 1 { proc = m[1] }
        res = append(res, map[string]any{"proto": strings.ToUpper(proto), "local": local, "pid": pid, "proc": proc})
    }
    return res
}

func connectionsHandler(w http.ResponseWriter, r *http.Request) {
    out, err := runSSH("ss -tuanp | head -n 20", 2*time.Second)
    if err != nil { http.Error(w, err.Error(), http.StatusBadGateway); return }
    rows := parseConnections(out)
    w.Header().Set("Content-Type", "application/json")
    _ = json.NewEncoder(w).Encode(rows)
}

func clientIpsHandler(w http.ResponseWriter, r *http.Request) {
    out, err := runSSH("ss -tuanp | awk '{print $5}' | cut -d: -f1 | sort | uniq | grep -v '^$\\|^127\\|^\\*\\|^::1'", 2*time.Second)
    if err != nil { http.Error(w, err.Error(), http.StatusBadGateway); return }
    lines := strings.Split(strings.TrimSpace(out), "\n")
    ips := make([]string, 0, len(lines))
    for _, ip := range lines {
        if ip != "" { ips = append(ips, ip) }
    }
    w.Header().Set("Content-Type", "application/json")
    _ = json.NewEncoder(w).Encode(ips)
}

func processLogsHandler(w http.ResponseWriter, r *http.Request) {
    out, err := runSSH("journalctl --no-pager -n 20 --output=short", 3*time.Second)
    if err != nil { http.Error(w, err.Error(), http.StatusBadGateway); return }
    logs := map[string][]string{"system": strings.Split(out, "\n")}
    w.Header().Set("Content-Type", "application/json")
    _ = json.NewEncoder(w).Encode(logs)
}

func resourcesHandler(w http.ResponseWriter, r *http.Request) {
    // Get memory info - more accurate calculation
    memOut, _ := runSSH("free -m | awk 'NR==2{printf \"%.2f %.2f\", ($2-$7)/1024, $2/1024}'", 2*time.Second)
    log.Printf("Memory output: '%s'", memOut)

    // Compute CPU usage using two /proc/stat snapshots (delta method)
    cpuUsage := func() float64 {
        first, err1 := runSSH("grep '^cpu ' /proc/stat", 1*time.Second)
        if err1 != nil { return 0 }
        time.Sleep(250 * time.Millisecond)
        second, err2 := runSSH("grep '^cpu ' /proc/stat", 1*time.Second)
        if err2 != nil { return 0 }
        parse := func(s string) ([]int64, bool) {
            f := strings.Fields(strings.TrimSpace(s))
            if len(f) < 5 { return nil, false }
            vals := make([]int64, 0, len(f)-1)
            for _, x := range f[1:] {
                v, err := strconv.ParseInt(x, 10, 64)
                if err != nil { return nil, false }
                vals = append(vals, v)
            }
            return vals, true
        }
        v1, ok1 := parse(first)
        v2, ok2 := parse(second)
        if !ok1 || !ok2 { return 0 }
        sum := func(a []int64) int64 { t := int64(0); for _, v := range a { t += v }; return t }
        total1 := sum(v1)
        total2 := sum(v2)
        if total2 <= total1 { return 0 }
        idle1 := v1[3]
        idle2 := v2[3]
        if len(v1) > 4 { idle1 += v1[4] }
        if len(v2) > 4 { idle2 += v2[4] }
        totald := total2 - total1
        idled := idle2 - idle1
        if totald <= 0 { return 0 }
        usage := float64(totald-idled) * 100 / float64(totald)
        if usage < 0 { usage = 0 }
        if usage > 100 { usage = 100 }
        return usage
    }()

    // Get disk usage - more robust
    diskOut, _ := runSSH("df / | awk 'NR==2{printf \"%.0f\", $5}' | tr -d '%'", 2*time.Second)
    if strings.TrimSpace(diskOut) == "" {
        // Fallback method
        diskOut, _ = runSSH("df -h / | tail -n 1 | awk '{print $5}' | tr -d '%'", 2*time.Second)
    }
    
    // Get load average for additional CPU info
    loadOut, _ := runSSH("uptime | grep -oE 'load average: [0-9.]+' | grep -oE '[0-9.]+' | head -1", 2*time.Second)
    if strings.TrimSpace(loadOut) == "" {
        // Alternative method
        loadOut, _ = runSSH("cat /proc/loadavg | awk '{print $1}'", 2*time.Second)
    }
    
    // Try to get GPU usage (nvidia-smi if available), fallback to AMD counter if present
    gpuOut, _ := runSSH("nvidia-smi --query-gpu=utilization.gpu --format=csv,noheader,nounits 2>/dev/null | head -1", 2*time.Second)
    if strings.TrimSpace(gpuOut) == "" {
        // AMD ROCm fallback (if exposed)
        gpuOut, _ = runSSH("cat /sys/class/drm/card0/device/gpu_busy_percent 2>/dev/null | head -1", 1*time.Second)
    }
    
    memParts := strings.Fields(strings.TrimSpace(memOut))
    // CPU usage already computed
    disk := strings.TrimSpace(diskOut)
    load := strings.TrimSpace(loadOut)
    gpu := strings.TrimSpace(gpuOut)
    
    var ramUsed, ramTotal float64 = 0, 8
    if len(memParts) >= 2 {
        if u, err := strconv.ParseFloat(memParts[0], 64); err == nil { 
            ramUsed = u
            // Clamp to reasonable bounds
            if ramUsed < 0 { ramUsed = 0 }
        }
        if t, err := strconv.ParseFloat(memParts[1], 64); err == nil { 
            ramTotal = t
            // Ensure minimum total memory
            if ramTotal < 0.1 { ramTotal = 8 }
            // Clamp to reasonable maximum (1TB)
            if ramTotal > 1024 { ramTotal = 1024 }
        }
    }
    // Ensure used doesn't exceed total
    if ramUsed > ramTotal { ramUsed = ramTotal }
    
    // cpuUsage already clamped in computation above
    
    var diskUsage float64 = 0
    if disk != "" {
        if d, err := strconv.ParseFloat(disk, 64); err == nil { 
            diskUsage = d
            // Clamp disk usage to reasonable bounds
            if diskUsage < 0 { diskUsage = 0 }
            if diskUsage > 100 { diskUsage = 100 }
        }
    }
    
    var loadAvg float64 = 0
    if load != "" {
        if l, err := strconv.ParseFloat(load, 64); err == nil { 
            loadAvg = l
            // Clamp load average to reasonable bounds (0-20 is typical)
            if loadAvg < 0 { loadAvg = 0 }
            if loadAvg > 50 { loadAvg = 50 }
        }
    }
    
    var gpuUsage float64 = 0
    if gpu != "" {
        if g, err := strconv.ParseFloat(gpu, 64); err == nil { 
            gpuUsage = g
            // Clamp GPU usage to reasonable bounds
            if gpuUsage < 0 { gpuUsage = 0 }
            if gpuUsage > 100 { gpuUsage = 100 }
        }
    }
    
    res := map[string]any{
        "cpu": map[string]float64{"usage": cpuUsage, "load": loadAvg},
        "gpu": map[string]float64{"usage": gpuUsage},
        "ram": map[string]float64{"used": ramUsed, "total": ramTotal},
        "vram": map[string]float64{"used": 0, "total": 0},
        "ssd": map[string]any{"util": diskUsage, "read": 0, "write": 0},
    }
    w.Header().Set("Content-Type", "application/json")
    _ = json.NewEncoder(w).Encode(res)
}

func networkHandler(w http.ResponseWriter, r *http.Request) {
    out, err := runSSH("cat /proc/net/dev | tail -n +3 | awk '{print $1, $2, $10}'", 2*time.Second)
    if err != nil { http.Error(w, err.Error(), http.StatusBadGateway); return }
    
    // Parse actual network data
    lines := strings.Split(strings.TrimSpace(out), "\n")
    totalRx, totalTx := int64(0), int64(0)
    
    for _, line := range lines {
        fields := strings.Fields(line)
        if len(fields) >= 3 {
            // Skip loopback interface
            if strings.HasPrefix(fields[0], "lo:") {
                continue
            }
            if rx, err := strconv.ParseInt(fields[1], 10, 64); err == nil {
                totalRx += rx
            }
            if tx, err := strconv.ParseInt(fields[2], 10, 64); err == nil {
                totalTx += tx
            }
        }
    }
    
    now := time.Now()
    var rxMbps, txMbps float64 = 0, 0
    
    // Calculate speed based on difference from last measurement
    if !lastNetworkStats.Timestamp.IsZero() {
        timeDiff := now.Sub(lastNetworkStats.Timestamp).Seconds()
        if timeDiff > 0 {
            rxBytesDiff := totalRx - lastNetworkStats.RxBytes
            txBytesDiff := totalTx - lastNetworkStats.TxBytes
            
            // Convert bytes per second to Mbps
            rxMbps = float64(rxBytesDiff) / timeDiff / (1024 * 1024) * 8
            txMbps = float64(txBytesDiff) / timeDiff / (1024 * 1024) * 8
            
            // Ensure non-negative values
            if rxMbps < 0 { rxMbps = 0 }
            if txMbps < 0 { txMbps = 0 }
        }
    }
    
    // Update last measurement
    lastNetworkStats = NetworkStats{
        RxBytes: totalRx,
        TxBytes: totalTx,
        Timestamp: now,
    }
    
    // Create data points with current speed
    points := make([]map[string]any, 60)
    for i := 0; i < 60; i++ {
        // Add some realistic variation for visualization
        rxVar := rxMbps * (0.9 + 0.2*float64(i%5)/5)
        txVar := txMbps * (0.8 + 0.4*float64(i%7)/7)
        
        points[i] = map[string]any{
            "t": i, 
            "rx": rxVar, 
            "tx": txVar,
        }
    }
    
    w.Header().Set("Content-Type", "application/json")
    _ = json.NewEncoder(w).Encode(points)
}

func parseConnections(out string) []map[string]any {
    lines := strings.Split(out, "\n")
    res := make([]map[string]any, 0, len(lines))
    for i, ln := range lines {
        if i == 0 || strings.TrimSpace(ln) == "" { continue }
        f := strings.Fields(ln)
        if len(f) < 5 { continue }
        
        proto := strings.ToUpper(f[0])
        state := f[1]
        local := f[4]
        peer := f[5]
        
        // Parse users field which contains process info
        pid := ""
        proc := ""
        if len(f) > 6 {
            usersField := f[6]
            // Extract PID and process name from users field
            // Format: users:(("process",pid=1234,fd=5))
            if m := rePid.FindStringSubmatch(usersField); len(m) > 1 { 
                pid = m[1] 
            }
            if m := reName.FindStringSubmatch(usersField); len(m) > 1 { 
                proc = m[1] 
            }
        }
        
        res = append(res, map[string]any{
            "proto": proto, 
            "local": local, 
            "peer": peer, 
            "state": state, 
            "pid": pid, 
            "proc": proc,
        })
    }
    return res
}


