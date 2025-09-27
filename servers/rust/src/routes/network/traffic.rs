use axum::{http::StatusCode, response::Json};
use serde::{Deserialize, Serialize};
use serde_json::{json, Value};
use std::process::Command;

// ---------- Instant throughput (global) ----------
pub async fn get_instant() -> Result<Json<Value>, StatusCode> {
    #[cfg(target_os = "windows")]
    {
        // Bytes Received/sec and Bytes Sent/sec (sum across interfaces)
        let rx = Command::new("powershell")
            .arg("-NoProfile").arg("-NonInteractive").arg("-Command")
            .arg("(Get-Counter '\\Network Interface(*)\\Bytes Received/sec' -MaxSamples 1).CounterSamples | Measure-Object CookedValue -Sum | Select -Expand Sum")
            .output();
        let tx = Command::new("powershell")
            .arg("-NoProfile").arg("-NonInteractive").arg("-Command")
            .arg("(Get-Counter '\\Network Interface(*)\\Bytes Sent/sec' -MaxSamples 1).CounterSamples | Measure-Object CookedValue -Sum | Select -Expand Sum")
            .output();
        let rx_bps: f64 = rx.ok().and_then(|o| String::from_utf8(o.stdout).ok()).and_then(|s| s.trim().parse::<f64>().ok()).unwrap_or(0.0);
        let tx_bps: f64 = tx.ok().and_then(|o| String::from_utf8(o.stdout).ok()).and_then(|s| s.trim().parse::<f64>().ok()).unwrap_or(0.0);
        return Ok(Json(json!({
            "download_mbps": (rx_bps * 8.0) / 1_000_000.0,
            "upload_mbps": (tx_bps * 8.0) / 1_000_000.0
        })));
    }

    #[cfg(not(target_os = "windows"))]
    {
        let out = Command::new("cat").arg("/proc/net/dev").output();
        let s = out.ok().map(|o| String::from_utf8_lossy(&o.stdout).to_string()).unwrap_or_default();
        let mut rx: u64 = 0; let mut tx: u64 = 0;
        for line in s.lines() {
            if let Some(pos) = line.find(':') {
                let iface = line[..pos].trim();
                if iface == "lo" { continue; }
                let rest = line[pos+1..].trim();
                let cols: Vec<&str> = rest.split_whitespace().collect();
                if cols.len() >= 16 { if let (Ok(r), Ok(t)) = (cols[0].parse::<u64>(), cols[8].parse::<u64>()) { rx += r; tx += t; } }
            }
        }
        // Report as MBps (bytes per second) converted to Mbps (approx snapshot)
        return Ok(Json(json!({
            "download_mbps": (rx as f64 * 8.0) / 1_000_000.0,
            "upload_mbps": (tx as f64 * 8.0) / 1_000_000.0
        })));
    }
}

// ---------- Flow aggregation (best-effort) ----------
#[derive(Serialize, Deserialize, Clone)]
struct FlowRow {
    proto: String,
    local_ip: String,
    local_port: u16,
    remote_ip: String,
    remote_port: u16,
    state: String,
    count: u32,
}

pub async fn get_flows() -> Result<Json<Value>, StatusCode> {
    let mut rows: Vec<FlowRow> = Vec::new();

    #[cfg(target_os = "windows")]
    {
        let out = Command::new("netstat").arg("-ano").output().map_err(|_| StatusCode::INTERNAL_SERVER_ERROR)?;
        let s = String::from_utf8_lossy(&out.stdout);
        for line in s.lines() {
            let t = line.trim();
            if !(t.starts_with("TCP") || t.starts_with("UDP")) { continue; }
            let parts: Vec<&str> = t.split_whitespace().collect();
            if parts.len() < 4 { continue; }
            let proto = parts[0].to_string();
            let (local, remote, state) = if proto == "UDP" { (parts[1], parts[2], "-".to_string()) } else { (parts[1], parts[2], parts.get(3).unwrap_or(&"").to_string()) };
            let (li, lp) = split_host_port(local);
            let (ri, rp) = split_host_port(remote);
            if lp==0 && rp==0 { continue; }
            add_or_inc(&mut rows, FlowRow{ proto, local_ip: li, local_port: lp, remote_ip: ri, remote_port: rp, state, count:1 });
        }
    }

    #[cfg(not(target_os = "windows"))]
    {
        let out = Command::new("ss").arg("-tunap").output().unwrap_or_else(|_| Default::default());
        let s = String::from_utf8_lossy(&out.stdout);
        for line in s.lines() {
            let t = line.trim();
            if !(t.starts_with("tcp") || t.starts_with("udp")) { continue; }
            let parts: Vec<&str> = t.split_whitespace().collect();
            if parts.len() < 5 { continue; }
            let proto = parts[0].to_uppercase();
            let local = parts[4]; let remote = parts[5];
            let (li, lp) = split_host_port(local);
            let (ri, rp) = split_host_port(remote);
            add_or_inc(&mut rows, FlowRow{ proto, local_ip: li, local_port: lp, remote_ip: ri, remote_port: rp, state: parts.get(1).unwrap_or(&"").to_string(), count:1 });
        }
    }

    Ok(Json(json!({"flows": rows})))
}

fn split_host_port(s: &str) -> (String, u16) {
    // IPv4: a.b.c.d:port, may include [::]:port; fall back to 0
    if let Some(idx) = s.rfind(':') {
        let host = s[..idx].trim_matches(['[',']']).to_string();
        let port = s[idx+1..].parse::<u16>().unwrap_or(0);
        (host, port)
    } else { (s.to_string(), 0) }
}

fn add_or_inc(rows: &mut Vec<FlowRow>, r: FlowRow) {
    if let Some(existing) = rows.iter_mut().find(|e| e.proto==r.proto && e.local_ip==r.local_ip && e.local_port==r.local_port && e.remote_ip==r.remote_ip && e.remote_port==r.remote_port && e.state==r.state) {
        existing.count += 1;
    } else { rows.push(r); }
}

// ---------- Summary (top protocols/ports, hostnames from DNS cache) ----------
pub async fn get_summary() -> Result<Json<Value>, StatusCode> {
    let flows = get_flows().await.ok().and_then(|j| j.0.get("flows").cloned()).unwrap_or(json!([]));
    let flows: Vec<FlowRow> = serde_json::from_value(flows).unwrap_or_default();

    let mut proto_counts: std::collections::HashMap<String,u32> = std::collections::HashMap::new();
    let mut port_counts: std::collections::HashMap<u16,u32> = std::collections::HashMap::new();
    for f in &flows { *proto_counts.entry(f.proto.clone()).or_insert(0) += f.count; *port_counts.entry(f.remote_port).or_insert(0) += f.count; }

    // Hostnames best-effort (Windows DNS cache)
    let mut hosts: Vec<String> = Vec::new();
    #[cfg(target_os = "windows")]
    {
        if let Ok(out) = Command::new("ipconfig").arg("/displaydns").output() {
            let s = String::from_utf8_lossy(&out.stdout);
            for line in s.lines() { let l=line.trim(); if l.to_lowercase().starts_with("record name") { if let Some(name)=l.split(':').nth(1) { hosts.push(name.trim().to_string()); } } }
        }
    }

    Ok(Json(json!({
        "top_protocols": map_to_sorted(proto_counts),
        "top_ports": mapu16_to_sorted(port_counts),
        "hosts": hosts
    })))
}

fn map_to_sorted(m: std::collections::HashMap<String,u32>) -> Vec<Value> {
    let mut v: Vec<(String,u32)> = m.into_iter().collect(); v.sort_by(|a,b| b.1.cmp(&a.1));
    v.into_iter().map(|(k,c)| json!({"name": k, "count": c})).collect()
}
fn mapu16_to_sorted(m: std::collections::HashMap<u16,u32>) -> Vec<Value> {
    let mut v: Vec<(u16,u32)> = m.into_iter().collect(); v.sort_by(|a,b| b.1.cmp(&a.1));
    v.into_iter().map(|(k,c)| json!({"port": k, "count": c})).collect()
}


