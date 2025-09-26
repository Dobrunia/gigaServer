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

type ProcessActionReq struct {
    PID    string `json:"pid"`
    Action string `json:"action"` // "kill", "restart"
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
    mux.Handle("/go/process/action", withLogging("process_action", withCORS(http.HandlerFunc(processActionHandler))))
    mux.Handle("/go/data/services", withLogging("services", withCORS(http.HandlerFunc(servicesHandler))))
    mux.Handle("/go/data/disk-usage", withLogging("disk_usage", withCORS(http.HandlerFunc(diskUsageHandler))))
    mux.Handle("/go/data/users", withLogging("users", withCORS(http.HandlerFunc(usersHandler))))
    mux.Handle("/go/data/system-info", withLogging("system_info", withCORS(http.HandlerFunc(systemInfoHandler))))
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
    rows := parseListenPorts(out)
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

func parseListenPorts(out string) []map[string]any {
    lines := strings.Split(out, "\n")
    res := make([]map[string]any, 0, len(lines))
    log.Printf("parseListenPorts input: %s", out) // Debug
    
    for _, ln := range lines {
        ln = strings.TrimSpace(ln)
        if ln == "" { continue }
        
        // Skip header line if present
        if strings.HasPrefix(ln, "Netid") || strings.HasPrefix(ln, "Proto") { continue }
        
        // ss -lntup output format: Proto Recv-Q Send-Q Local-Address:Port Peer-Address:Port Process
        f := strings.Fields(ln)
        log.Printf("parseListenPorts fields: %v", f) // Debug
        
        if len(f) < 5 { continue }
        
        proto := strings.ToUpper(f[0])
        local := f[4]
        pid := ""
        proc := ""
        
        // Process info is in the last field(s), format: users:(("process",pid=1234,fd=5))
        if len(f) > 5 {
            processField := strings.Join(f[5:], " ")
            log.Printf("parseListenPorts processField: %s", processField) // Debug
            
            if m := rePid.FindStringSubmatch(processField); len(m) > 1 { 
                pid = m[1] 
            }
            if m := reName.FindStringSubmatch(processField); len(m) > 1 { 
                proc = m[1] 
            }
        }
        
        res = append(res, map[string]any{
            "proto": proto, 
            "local": local, 
            "pid": pid, 
            "proc": proc,
        })
    }
    log.Printf("parseListenPorts result: %v", res) // Debug
    return res
}

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

func processActionHandler(w http.ResponseWriter, r *http.Request) {
    if r.Method != http.MethodPost {
        http.Error(w, "method not allowed", http.StatusMethodNotAllowed)
        return
    }
    
    var req ProcessActionReq
    if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
        http.Error(w, err.Error(), http.StatusBadRequest)
        return
    }
    
    log.Printf("process_action: pid=%s action=%s", req.PID, req.Action)
    
    var cmd string
    switch req.Action {
    case "kill":
        cmd = fmt.Sprintf("kill -9 %s", req.PID)
    case "restart":
        // Get process command first, then kill and restart
        getCmdOut, err := runSSH(fmt.Sprintf("ps -p %s -o cmd --no-headers", req.PID), 3*time.Second)
        if err != nil {
            http.Error(w, fmt.Sprintf("failed to get process command: %v", err), http.StatusBadGateway)
            return
        }
        processCmd := strings.TrimSpace(getCmdOut)
        if processCmd == "" {
            http.Error(w, "process not found or no command available", http.StatusNotFound)
            return
        }
        
        // Kill the process
        if _, err := runSSH(fmt.Sprintf("kill %s", req.PID), 3*time.Second); err != nil {
            http.Error(w, fmt.Sprintf("failed to kill process: %v", err), http.StatusBadGateway)
            return
        }
        
        // Wait a moment
        time.Sleep(1 * time.Second)
        
        // Restart the process in background
        cmd = fmt.Sprintf("nohup %s > /dev/null 2>&1 &", processCmd)
    default:
        http.Error(w, "invalid action, use 'kill' or 'restart'", http.StatusBadRequest)
        return
    }
    
    output, err := runSSH(cmd, 5*time.Second)
    if err != nil {
        http.Error(w, fmt.Sprintf("command failed: %v", err), http.StatusBadGateway)
        return
    }
    
    w.Header().Set("Content-Type", "application/json")
    result := map[string]any{
        "success": true,
        "action": req.Action,
        "pid": req.PID,
        "output": output,
    }
    _ = json.NewEncoder(w).Encode(result)
}

// Services management (systemctl)
func servicesHandler(w http.ResponseWriter, r *http.Request) {
    // Try different commands for getting running services
    commands := []string{
        "systemctl list-units --type=service --state=running --no-pager --no-legend | head -15",
        "systemctl list-units --type=service --state=running --no-pager | head -15", 
        "/etc/init.d/* status 2>/dev/null | grep running | head -10", // SysV init scripts
        "ls /etc/init.d/ | head -10", // List available init scripts
        "ps aux | grep -E '[s]shd|[n]ginx|[a]pache|[m]ysql|[p]ostgres' | head -10", // Common services (bracket notation prevents grep from finding itself)
        "ps aux | grep -v grep | grep -E 'root.*[[:space:]]/.*' | head -15", // Root processes with full paths
        "ps -eo pid,user,comm | grep -v grep | head -15", // Simple process list
    }
    
    var out string
    var err error
    var usedCmd string
    
    for _, cmd := range commands {
        out, err = runSSH(cmd, 3*time.Second)
        if err == nil && strings.TrimSpace(out) != "" && 
           !strings.Contains(out, "System has") && !strings.Contains(out, "Failed to") &&
           !strings.Contains(out, "Can't operate") && !strings.Contains(out, "Host is down") {
            usedCmd = cmd
            break
        }
        log.Printf("servicesHandler cmd '%s' failed or returned error: %v, output: %s", cmd, err, out)
    }
    
    if err != nil || strings.TrimSpace(out) == "" { 
        log.Printf("servicesHandler all commands failed, last error: %v", err)
        // Return empty but valid response instead of error
        w.Header().Set("Content-Type", "application/json")
        _ = json.NewEncoder(w).Encode(map[string]any{"services": []map[string]any{}})
        return 
    }
    log.Printf("servicesHandler used cmd: %s", usedCmd)
    log.Printf("servicesHandler output: %s", out) // Debug
    
    services := parseServices(out, usedCmd)
    
    // If no services found, try to get at least some processes
    if len(services) == 0 {
        log.Printf("servicesHandler no services parsed, trying process fallback")
        if procOut, err := runSSH("ps aux | grep -E 'sshd|nginx|apache|mysql|postgres|redis|docker' | grep -v grep | head -10", 3*time.Second); err == nil {
            procServices := parseProcessAsServices(procOut)
            if len(procServices) > 0 {
                services = procServices
            }
        }
    }
    
    w.Header().Set("Content-Type", "application/json")
    _ = json.NewEncoder(w).Encode(map[string]any{"services": services})
}

func parseServices(out string, cmd string) []map[string]any {
    lines := strings.Split(out, "\n")
    res := make([]map[string]any, 0, len(lines))
    log.Printf("parseServices input: %s", out) // Debug
    log.Printf("parseServices cmd: %s", cmd) // Debug
    
    for _, ln := range lines {
        ln = strings.TrimSpace(ln)
        if ln == "" { continue }
        
        // Different parsing based on command used
        if strings.Contains(cmd, "systemctl") {
            // Skip headers and error messages
            if strings.HasPrefix(ln, "UNIT") || strings.HasPrefix(ln, "●") || strings.Contains(ln, "LOAD") ||
               strings.Contains(ln, "System has") || strings.Contains(ln, "Failed to") || 
               strings.Contains(ln, "systemd as init") || strings.Contains(ln, "Can't operate") ||
               strings.Contains(ln, "bus:") || strings.Contains(ln, "Host is down") {
                continue
            }
            
            // systemctl output: UNIT LOAD ACTIVE SUB DESCRIPTION
            f := strings.Fields(ln)
            log.Printf("parseServices systemctl fields: %v", f) // Debug
            
            if len(f) < 4 { continue }
            
            name := f[0]
            load := f[1] 
            active := f[2]
            sub := f[3]
            description := ""
            if len(f) > 4 {
                description = strings.Join(f[4:], " ")
            }
            
            // Only add if it looks like a real service
            if strings.HasSuffix(name, ".service") || strings.Contains(name, "service") {
                res = append(res, map[string]any{
                    "name": name,
                    "load": load,
                    "active": active,
                    "sub": sub,
                    "description": description,
                })
            }
            
        } else if strings.Contains(cmd, "/etc/init.d") && strings.Contains(cmd, "status") {
            // /etc/init.d/* status output
            if strings.Contains(ln, "running") || strings.Contains(ln, "active") {
                parts := strings.Fields(ln)
                if len(parts) >= 1 {
                    serviceName := parts[0]
                    if strings.Contains(serviceName, "/") {
                        pathParts := strings.Split(serviceName, "/")
                        serviceName = pathParts[len(pathParts)-1]
                    }
                    res = append(res, map[string]any{
                        "name": serviceName,
                        "load": "loaded",
                        "active": "active", 
                        "sub": "running",
                        "description": "SysV init service",
                    })
                }
            }
            
        } else if strings.Contains(cmd, "ls /etc/init.d") {
            // List of init scripts
            if ln != "" && !strings.Contains(ln, "README") && !strings.Contains(ln, "skeleton") {
                res = append(res, map[string]any{
                    "name": ln,
                    "load": "available",
                    "active": "unknown",
                    "sub": "init-script", 
                    "description": "Available init script",
                })
            }
            
        } else if strings.Contains(cmd, "ps -eo") {
            // ps -eo pid,user,comm output
            f := strings.Fields(ln)
            if len(f) >= 3 && !strings.Contains(ln, "PID") {
                pid := f[0]
                user := f[1] 
                command := f[2]
                
                res = append(res, map[string]any{
                    "name": command,
                    "load": "loaded",
                    "active": "active",
                    "sub": "running",
                    "description": fmt.Sprintf("Process PID %s, User %s", pid, user),
                })
            }
            
        } else if strings.Contains(cmd, "ps aux") {
            // Process output - extract process names
            f := strings.Fields(ln)
            if len(f) < 11 { continue }
            
            // Skip header
            if strings.Contains(ln, "PID") { continue }
            
            user := f[0]
            pid := f[1]
            processName := f[10] // Command column
            command := strings.Join(f[10:], " ")
            
            // Extract service name from path
            serviceName := processName
            if strings.Contains(serviceName, "/") {
                parts := strings.Split(serviceName, "/")
                serviceName = parts[len(parts)-1]
            }
            
            // Skip some common non-service processes
            if strings.Contains(serviceName, "grep") || strings.Contains(serviceName, "awk") || 
               strings.Contains(serviceName, "head") || serviceName == "ps" {
                continue
            }
            
            res = append(res, map[string]any{
                "name": serviceName,
                "load": "loaded", 
                "active": "active",
                "sub": "running",
                "description": fmt.Sprintf("Process %s (PID %s, User %s)", command, pid, user),
            })
        }
    }
    log.Printf("parseServices result: %v", res) // Debug
    return res
}

func parseProcessAsServices(out string) []map[string]any {
    lines := strings.Split(out, "\n")
    res := make([]map[string]any, 0, len(lines))
    log.Printf("parseProcessAsServices input: %s", out) // Debug
    
    for _, ln := range lines {
        if strings.TrimSpace(ln) == "" { continue }
        f := strings.Fields(ln)
        if len(f) < 11 { continue }
        
        // Skip header
        if strings.Contains(ln, "PID") { continue }
        
        user := f[0]
        pid := f[1]
        command := strings.Join(f[10:], " ")
        
        // Extract service name from command
        serviceName := f[10]
        if strings.Contains(serviceName, "/") {
            parts := strings.Split(serviceName, "/")
            serviceName = parts[len(parts)-1]
        }
        
        res = append(res, map[string]any{
            "name": serviceName,
            "load": "loaded",
            "active": "active", 
            "sub": "running",
            "description": fmt.Sprintf("Process %s (PID %s, User %s)", command, pid, user),
        })
    }
    
    log.Printf("parseProcessAsServices result: %v", res) // Debug
    return res
}

// Disk usage by directories
func diskUsageHandler(w http.ResponseWriter, r *http.Request) {
    // Try common directories, ignore errors for individual dirs
    dirs := []string{"/var", "/tmp", "/home", "/opt", "/usr", "/etc", "/root"}
    var results []string
    
    for _, dir := range dirs {
        if out, err := runSSH(fmt.Sprintf("du -sh %s 2>/dev/null", dir), 2*time.Second); err == nil && strings.TrimSpace(out) != "" {
            results = append(results, strings.TrimSpace(out))
        }
    }
    
    if len(results) == 0 {
        // Fallback: just get root filesystem usage
        if out, err := runSSH("du -sh /* 2>/dev/null | head -10", 4*time.Second); err == nil {
            results = strings.Split(strings.TrimSpace(out), "\n")
        }
    }
    
    usage := parseDiskUsage(strings.Join(results, "\n"))
    w.Header().Set("Content-Type", "application/json")
    _ = json.NewEncoder(w).Encode(map[string]any{"directories": usage})
}

func parseDiskUsage(out string) []map[string]any {
    lines := strings.Split(out, "\n")
    res := make([]map[string]any, 0, len(lines))
    for _, ln := range lines {
        if strings.TrimSpace(ln) == "" { continue }
        f := strings.Fields(ln)
        if len(f) < 2 { continue }
        
        size := f[0]
        path := f[1]
        
        res = append(res, map[string]any{
            "size": size,
            "path": path,
        })
    }
    return res
}

// Active users
func usersHandler(w http.ResponseWriter, r *http.Request) {
    // Try multiple commands to get user info
    commands := []string{
        "who",
        "w -h", 
        "users",
        "cat /etc/passwd | grep -E '/bin/(bash|sh|zsh|fish)$' | cut -d: -f1,5 | head -10", // Real users with shells
        "getent passwd | grep -E '/bin/(bash|sh|zsh|fish)$' | cut -d: -f1,5 | head -10", // Alternative passwd lookup
        "loginctl list-sessions 2>/dev/null | grep -v SESSION", // Systemd login sessions
        "ps aux | awk '$1 != \"root\" && $6 ~ /pts|tty/ {print $1, $6}' | sort -u | head -5", // Non-root terminal users
        "netstat -tnp 2>/dev/null | grep :22 | awk '{print $5}' | cut -d: -f1 | sort -u | head -5", // SSH connections
    }
    
    var out string
    var err error
    var usedCmd string
    
    for _, cmd := range commands {
        out, err = runSSH(cmd, 2*time.Second)
        if err == nil && strings.TrimSpace(out) != "" {
            usedCmd = cmd
            break
        }
        log.Printf("usersHandler cmd '%s' failed or empty: %v", cmd, err)
    }
    
    if err != nil || strings.TrimSpace(out) == "" { 
        log.Printf("usersHandler all commands failed")
        w.Header().Set("Content-Type", "application/json")
        _ = json.NewEncoder(w).Encode(map[string]any{"users": []map[string]any{}})
        return 
    }
    log.Printf("usersHandler used cmd: %s", usedCmd)
    log.Printf("usersHandler output: %s", out) // Debug
    
    users := parseUsers(out, usedCmd)
    
    // Log if no users found but don't create mock data
    if len(users) == 0 {
        log.Printf("usersHandler no users parsed from output")
    }
    
    w.Header().Set("Content-Type", "application/json")
    _ = json.NewEncoder(w).Encode(map[string]any{"users": users})
}

func parseUsers(out string, cmd string) []map[string]any {
    lines := strings.Split(out, "\n")
    res := make([]map[string]any, 0, len(lines))
    log.Printf("parseUsers input: %s", out) // Debug
    log.Printf("parseUsers cmd: %s", cmd) // Debug
    
    for _, ln := range lines {
        if strings.TrimSpace(ln) == "" { continue }
        f := strings.Fields(ln)
        log.Printf("parseUsers fields: %v", f) // Debug
        
        if strings.Contains(cmd, "who") || strings.Contains(cmd, "w -h") {
            if len(f) < 2 { continue }
            
            user := f[0]
            tty := ""
            time := ""
            ip := ""
            
            if len(f) >= 2 { tty = f[1] }
            if len(f) >= 4 {
                time = f[2] + " " + f[3]
            }
            if len(f) >= 5 && strings.Contains(f[4], "(") {
                ip = strings.Trim(f[4], "()")
            }
            
            res = append(res, map[string]any{
                "user": user,
                "tty": tty,
                "time": time,
                "ip": ip,
            })
            
        } else if strings.Contains(cmd, "users") {
            // 'users' command just lists usernames
            for _, user := range f {
                if user != "" {
                    res = append(res, map[string]any{
                        "user": user,
                        "tty": "unknown",
                        "time": "active",
                        "ip": "",
                    })
                }
            }
            
        } else if strings.Contains(cmd, "last") {
            // last command output: username tty from time
            if len(f) < 3 { continue }
            if strings.Contains(ln, "reboot") || strings.Contains(ln, "wtmp") { continue }
            
            user := f[0]
            tty := f[1]
            from := ""
            time := ""
            
            if len(f) >= 3 { from = f[2] }
            if len(f) >= 5 { time = f[3] + " " + f[4] }
            
            res = append(res, map[string]any{
                "user": user,
                "tty": tty,
                "time": time,
                "ip": from,
            })
            
        } else if strings.Contains(cmd, "cat /etc/passwd") || strings.Contains(cmd, "getent passwd") {
            // passwd output: username:gecos
            parts := strings.Split(ln, ":")
            if len(parts) >= 2 {
                username := parts[0]
                description := ""
                if len(parts) > 1 {
                    description = parts[1]
                }
                res = append(res, map[string]any{
                    "user": username,
                    "tty": "system",
                    "time": "account",
                    "ip": description,
                })
            }
            
        } else if strings.Contains(cmd, "loginctl") {
            // loginctl output: SESSION UID USER SEAT TTY
            if len(f) >= 4 {
                session := f[0]
                user := f[2]
                tty := ""
                if len(f) >= 5 {
                    tty = f[4]
                }
                res = append(res, map[string]any{
                    "user": user,
                    "tty": tty,
                    "time": "session",
                    "ip": session,
                })
            }
            
        } else if strings.Contains(cmd, "ps aux | awk") {
            // awk output: user tty
            if len(f) >= 2 {
                user := f[0]
                tty := f[1]
                res = append(res, map[string]any{
                    "user": user,
                    "tty": tty,
                    "time": "active",
                    "ip": "terminal",
                })
            }
            
        } else if strings.Contains(cmd, "netstat") {
            // netstat output: IP addresses of SSH connections
            if ln != "" && !strings.Contains(ln, "127.0.0.1") {
                res = append(res, map[string]any{
                    "user": "ssh-client",
                    "tty": "remote",
                    "time": "connected",
                    "ip": ln,
                })
            }
            
        } else if strings.Contains(cmd, "ps aux") {
            // Process output with terminal info
            if len(f) < 11 { continue }
            if strings.Contains(ln, "PID") { continue }
            
            user := f[0]
            tty := f[6] // TTY column
            command := strings.Join(f[10:], " ")
            
            // Only include if it's a terminal process
            if strings.Contains(tty, "pts") || strings.Contains(tty, "tty") {
                res = append(res, map[string]any{
                    "user": user,
                    "tty": tty,
                    "time": "active",
                    "ip": command,
                })
            }
        }
    }
    log.Printf("parseUsers result: %v", res) // Debug
    return res
}

// System information
func systemInfoHandler(w http.ResponseWriter, r *http.Request) {
    // Get uptime
    uptime, _ := runSSH("uptime", 2*time.Second)
    
    // Get kernel info
    kernel, _ := runSSH("uname -r", 2*time.Second)
    arch, _ := runSSH("uname -m", 2*time.Second)
    
    // Try to get distro info with fallbacks
    distro, err := runSSH("cat /etc/os-release | grep PRETTY_NAME | cut -d'=' -f2 | tr -d '\"'", 2*time.Second)
    if err != nil || strings.TrimSpace(distro) == "" {
        // Fallback methods
        if lsb, err := runSSH("lsb_release -d | cut -f2", 2*time.Second); err == nil && strings.TrimSpace(lsb) != "" {
            distro = lsb
        } else if redhat, err := runSSH("cat /etc/redhat-release 2>/dev/null", 2*time.Second); err == nil && strings.TrimSpace(redhat) != "" {
            distro = redhat
        } else if debian, err := runSSH("cat /etc/debian_version 2>/dev/null", 2*time.Second); err == nil && strings.TrimSpace(debian) != "" {
            distro = "Debian " + strings.TrimSpace(debian)
        } else {
            distro = "Unknown Linux"
        }
    }
    
    info := map[string]any{
        "uptime": strings.TrimSpace(uptime),
        "distro": strings.TrimSpace(distro),
        "kernel": strings.TrimSpace(kernel),
        "arch": strings.TrimSpace(arch),
    }
    
    w.Header().Set("Content-Type", "application/json")
    _ = json.NewEncoder(w).Encode(info)
}


