use axum::{http::StatusCode, response::Json};
use serde_json::{json, Value};
use serde::{Serialize, Deserialize};
use std::process::Command;
use std::time::{SystemTime, UNIX_EPOCH, Duration, Instant};
use std::net::{UdpSocket, Ipv4Addr};
use std::collections::HashMap;

pub async fn discover_devices() -> Result<Json<Value>, StatusCode> {
    // Optional extra CIDRs to probe to populate ARP (comma-separated), e.g. "192.168.0.0/24,192.168.1.0/24"
    for cidr in extra_cidrs_from_env() { let _ = prime_arp_with_ping(&cidr).await; }

    let mut devices = scan_network_devices().await?;

    // SSDP enrichment (UPnP devices across routed subnets often reply unicast)
    if let Ok(ssdp_devices) = scan_ssdp_devices().await { merge_devices(&mut devices, ssdp_devices); }

    // mDNS (best-effort via external tool if present) – non-fatal
    if let Ok(mdns_devices) = scan_mdns_devices().await { merge_devices(&mut devices, mdns_devices); }

    enrich_devices(&mut devices).await;
    Ok(Json(json!({ "devices": devices })))
}

pub async fn get_device_inventory() -> Result<Json<Value>, StatusCode> {
    let devices = get_cached_devices().await?;
    Ok(Json(json!({ 
        "devices": devices,
        "total_count": devices.len(),
        "online_count": devices.iter().filter(|d| d.status == "online").count(),
        "last_scan": SystemTime::now().duration_since(UNIX_EPOCH).unwrap().as_secs()
    })))
}

async fn scan_network_devices() -> Result<Vec<NetworkDevice>, StatusCode> {
    let mut devices = Vec::new();
    
    // 1. ARP scan
    if let Ok(arp_devices) = scan_arp().await {
        devices.extend(arp_devices);
    }
    
    // 2. DHCP leases (if available)
    if let Ok(dhcp_devices) = scan_dhcp_leases().await {
        merge_devices(&mut devices, dhcp_devices);
    }
    
    Ok(devices)
}

// ---------- SSDP (UPnP) ----------
async fn scan_ssdp_devices() -> Result<Vec<NetworkDevice>, StatusCode> {
    let mut devices = Vec::new();
    let socket = UdpSocket::bind((Ipv4Addr::new(0,0,0,0), 0)).map_err(|_| StatusCode::INTERNAL_SERVER_ERROR)?;
    socket.set_read_timeout(Some(Duration::from_millis(1200))).ok();
    let dest = (Ipv4Addr::new(239,255,255,250), 1900);
    let msg = concat!(
        "M-SEARCH * HTTP/1.1\r\n",
        "HOST: 239.255.255.250:1900\r\n",
        "MAN: \"ssdp:discover\"\r\n",
        "MX: 1\r\n",
        "ST: ssdp:all\r\n\r\n");
    let _ = socket.send_to(msg.as_bytes(), dest);

    let start = Instant::now();
    let mut buf = [0u8; 2048];
    while start.elapsed() < Duration::from_millis(1200) {
        match socket.recv_from(&mut buf) {
            Ok((n, src)) => {
                let text = String::from_utf8_lossy(&buf[..n]).to_string();
                let headers = parse_http_headers(&text);
                let ip = match src { std::net::SocketAddr::V4(v4) => v4.ip().to_string(), _ => continue };
                let mut dev = NetworkDevice {
                    ip: ip.clone(),
                    mac: String::new(),
                    hostname: String::new(),
                    vendor: headers.get("server").cloned().unwrap_or_else(|| "Unknown".to_string()),
                    device_type: guess_type_from_ssdp(&headers),
                    first_seen: now_secs(),
                    last_seen: now_secs(),
                    status: "online".to_string(),
                    tags: vec![],
                    notes: String::new(),
                    os: extract_os_from_server(headers.get("server")),
                };
                if let Some(loc) = headers.get("location") {
                    if let Ok(body) = http_get_quick(loc) {
                        if let Some(name) = extract_xml_tag(&body, "friendlyName") { dev.hostname = name; }
                        if dev.os.is_empty() { if let Some(p) = extract_xml_tag(&body, "modelDescription") { dev.os = p; } }
                        if dev.os.is_empty() { if let Some(p) = extract_xml_tag(&body, "manufacturer") { dev.os = p; } }
                    }
                }
                devices.push(dev);
            }
            Err(_) => break,
        }
    }
    Ok(devices)
}

fn parse_http_headers(s: &str) -> HashMap<String,String> {
    let mut map = HashMap::new();
    for line in s.lines() {
        if let Some(i) = line.find(':') {
            map.insert(line[..i].trim().to_lowercase(), line[i+1..].trim().to_string());
        }
    }
    map
}

fn http_get_quick(url: &str) -> Result<String, ()> {
    // Use curl if present (1s timeout)
    if let Ok(out) = Command::new("curl").arg("-m").arg("1").arg("-s").arg(url).output() {
        if out.status.success() { return Ok(String::from_utf8_lossy(&out.stdout).to_string()); }
    }
    Err(())
}

fn extract_xml_tag(xml: &str, tag: &str) -> Option<String> {
    let open = format!("<{}>", tag);
    let close = format!("</{}>", tag);
    if let (Some(i), Some(j)) = (xml.find(&open), xml.find(&close)) { if j>i { return Some(xml[i+open.len()..j].trim().to_string()); } }
    None
}

fn guess_type_from_ssdp(h: &HashMap<String,String>) -> String {
    let combined = format!("{} {} {}", h.get("st").unwrap_or(&String::new()), h.get("usn").unwrap_or(&String::new()), h.get("server").unwrap_or(&String::new())).to_lowercase();
    if combined.contains("printer") || combined.contains("ipp") { return "Printer".to_string(); }
    if combined.contains("camera") { return "Camera".to_string(); }
    if combined.contains("tv") || combined.contains("dlna") || combined.contains("media") { return "TV".to_string(); }
    if combined.contains("igd") || combined.contains("gateway") || combined.contains("router") { return "Router".to_string(); }
    "Unknown".to_string()
}

fn extract_os_from_server(server: Option<&String>) -> String {
    if let Some(s) = server {
        let low = s.to_lowercase();
        if low.contains("android") { return "Android".to_string(); }
        if low.contains("darwin") || low.contains("mac os") || low.contains("macos") { return "macOS".to_string(); }
        if low.contains("ios") { return "iOS".to_string(); }
        if low.contains("windows") { return "Windows".to_string(); }
        if low.contains("linux") { return "Linux".to_string(); }
        return s.clone();
    }
    String::new()
}

// ---------- mDNS (best-effort via dns-sd) ----------
async fn scan_mdns_devices() -> Result<Vec<NetworkDevice>, StatusCode> {
    let devices = Vec::new();
    let out = Command::new("dns-sd").arg("-B").arg("_services._dns-sd._udp").arg("local.").arg("-t").arg("2").output();
    if let Ok(o) = out {
        if o.status.success() {
            let s = String::from_utf8_lossy(&o.stdout);
            for _line in s.lines() {
                // Extension point: resolve specific services to hosts if needed
            }
        }
    }
    Ok(devices)
}

// ---------- Helpers ----------

fn extra_cidrs_from_env() -> Vec<String> {
    std::env::var("EXTRA_CIDRS").ok().map(|s| s.split(',').map(|v| v.trim().to_string()).filter(|v| !v.is_empty()).collect()).unwrap_or_default()
}

async fn prime_arp_with_ping(cidr: &str) -> Result<(), ()> {
    // Only supports /24 for simplicity
    if !cidr.ends_with("/24") { return Err(()); }
    let base = cidr.trim_end_matches("/24");
    let parts: Vec<&str> = base.split('.').collect();
    if parts.len()!=4 { return Err(()); }
    let prefix = format!("{}.{}.{}.", parts[0], parts[1], parts[2]);
    for host in 1..=254u16 {
        let ip = format!("{}{}", prefix, host);
        let _ = ping_once(&ip).await;
    }
    Ok(())
}

async fn ping_once(ip: &str) -> bool {
    let out = if cfg!(target_os = "windows") {
        Command::new("ping").arg("-n").arg("1").arg("-w").arg("80").arg(ip).output()
    } else {
        Command::new("ping").arg("-c").arg("1").arg("-W").arg("1").arg(ip).output()
    };
    matches!(out, Ok(o) if o.status.success())
}

fn now_secs() -> u64 { SystemTime::now().duration_since(UNIX_EPOCH).unwrap().as_secs() }

async fn enrich_devices(devices: &mut Vec<NetworkDevice>) {
    for device in devices.iter_mut() {
        if device.hostname.is_empty() {
            if let Some(name) = reverse_dns(&device.ip).await { device.hostname = name; }
            if device.hostname.is_empty() {
                if let Some(name) = netbios_name(&device.ip).await { device.hostname = name; }
            }
        }

        if device.vendor == "Unknown" {
            device.vendor = lookup_vendor_map(&device.mac);
        }

        if device.device_type == "Unknown" {
            device.device_type = guess_device_type(&device.ip, &device.vendor);
        }
    }
}

async fn scan_arp() -> Result<Vec<NetworkDevice>, StatusCode> {
    let mut devices = Vec::new();
    
    let output = if cfg!(target_os = "windows") {
        Command::new("arp").arg("-a").output()
    } else {
        Command::new("arp").arg("-a").output()
    };
    
    if let Ok(result) = output {
        let output_str = String::from_utf8_lossy(&result.stdout);
        
        for line in output_str.lines() {
            if let Some(device) = parse_arp_line(line) {
                devices.push(device);
            }
        }
    }
    
    Ok(devices)
}

async fn scan_dhcp_leases() -> Result<Vec<NetworkDevice>, StatusCode> {
    let mut devices = Vec::new();
    
    if cfg!(target_os = "windows") {
        // Try to get DHCP client info
        let output = Command::new("ipconfig").arg("/all").output();
        if let Ok(result) = output {
            let output_str = String::from_utf8_lossy(&result.stdout);
            if let Some(device) = parse_ipconfig_dhcp(&output_str) {
                devices.push(device);
            }
        }
    }
    
    Ok(devices)
}

fn parse_arp_line(line: &str) -> Option<NetworkDevice> {
    let line = line.trim();
    // Skip obvious headers in any locale: lines containing dashes, words like Interface/Тип/Type, etc.
    if line.is_empty()
        || line.contains("---")
        || line.to_lowercase().contains("interface")
        || line.to_lowercase().contains("интерфейс")
        || line.to_lowercase().contains("internet")
        || line.to_lowercase().contains("адрес")
        || line.to_lowercase().contains("address")
        || line.to_lowercase().contains("type")
        || line.to_lowercase().contains("статический")
        || line.to_lowercase().contains("динамический")
    {
        return None;
    }
    
    let parts: Vec<&str> = line.split_whitespace().collect();
    if parts.len() >= 2 {
        let ip_candidate = parts[0];
        let mac_candidate = parts[1];

        // Validate formats to avoid parsing localized headers as entries
        if !is_valid_ipv4(ip_candidate) || !is_valid_mac(mac_candidate) {
            return None;
        }

        let ip = ip_candidate.to_string();
        let mac = mac_candidate.to_string();
        
        // Skip invalid entries
        if ip.starts_with("224.") || ip.starts_with("239.") || mac == "ff-ff-ff-ff-ff-ff" {
            return None;
        }
        
        // Skip entries with invalid MAC format
        if mac.is_empty() || mac == "N/A" || mac.len() < 8 {
            return None;
        }
        
        let normalized_mac = normalize_mac(&mac);
        
        Some(NetworkDevice {
            ip,
            mac: normalized_mac.clone(),
            hostname: String::new(),
            vendor: get_vendor_from_mac(&normalized_mac),
            device_type: "Unknown".to_string(),
            first_seen: SystemTime::now().duration_since(UNIX_EPOCH).unwrap().as_secs(),
            last_seen: SystemTime::now().duration_since(UNIX_EPOCH).unwrap().as_secs(),
            status: "online".to_string(),
            tags: vec![],
            notes: String::new(),
            os: String::new(),
        })
    } else {
        None
    }
}

fn parse_ipconfig_dhcp(output: &str) -> Option<NetworkDevice> {
    // Extract local machine info from ipconfig /all
    let mut ip = String::new();
    let mut mac = String::new();
    let mut hostname = String::new();
    
    for line in output.lines() {
        let line_lower = line.trim().to_lowercase();
        if line_lower.contains("ipv4 address") || line_lower.contains("ip address") {
            if let Some(colon_pos) = line.find(':') {
                ip = line[colon_pos + 1..].trim().to_string();
            }
        } else if line_lower.contains("physical address") || line_lower.contains("mac") {
            if let Some(colon_pos) = line.find(':') {
                mac = line[colon_pos + 1..].trim().to_string();
            }
        } else if line_lower.contains("host name") {
            if let Some(colon_pos) = line.find(':') {
                hostname = line[colon_pos + 1..].trim().to_string();
            }
        }
    }
    
    if !ip.is_empty() && !mac.is_empty() && mac.len() >= 8 {
        let normalized_mac = normalize_mac(&mac);
        Some(NetworkDevice {
            ip,
            mac: normalized_mac.clone(),
            hostname,
            vendor: get_vendor_from_mac(&normalized_mac),
            device_type: "Computer".to_string(),
            first_seen: SystemTime::now().duration_since(UNIX_EPOCH).unwrap().as_secs(),
            last_seen: SystemTime::now().duration_since(UNIX_EPOCH).unwrap().as_secs(),
            status: "online".to_string(),
            tags: vec!["local".to_string()],
            notes: String::new(),
            os: String::new(),
        })
    } else {
        None
    }
}

fn normalize_mac(mac: &str) -> String {
    mac.replace("-", ":").to_lowercase()
}

fn is_valid_ipv4(s: &str) -> bool {
    let parts: Vec<&str> = s.split('.').collect();
    if parts.len() != 4 { return false; }
    for p in parts {
        if p.is_empty() { return false; }
        if let Ok(v) = p.parse::<u8>() { let _ = v; } else { return false; }
    }
    true
}

fn is_valid_mac(s: &str) -> bool {
    let m = normalize_mac(s);
    let parts: Vec<&str> = m.split(':').collect();
    if parts.len() != 6 { return false; }
    for seg in parts {
        if seg.len() != 2 { return false; }
        if !seg.chars().all(|c| c.is_ascii_hexdigit()) { return false; }
    }
    true
}

fn get_vendor_from_mac(mac: &str) -> String {
    // Ensure MAC has at least 8 characters for first 3 octets (xx:xx:xx)
    if mac.len() < 8 {
        return "Unknown".to_string();
    }
    
    let oui = &mac[..8]; // First 3 octets
    match oui {
        "00:50:56" => "VMware".to_string(),
        "08:00:27" => "VirtualBox".to_string(),
        "00:15:5d" => "Microsoft".to_string(),
        "00:1c:42" => "Parallels".to_string(),
        "ac:de:48" => "Apple".to_string(),
        "00:23:df" => "Apple".to_string(),
        "28:cf:e9" => "Apple".to_string(),
        "a4:83:e7" => "Apple".to_string(),
        _ => "Unknown".to_string(),
    }
}

// Lightweight vendor map for common prefixes beyond OUI list above
fn lookup_vendor_map(mac: &str) -> String {
    let m = normalize_mac(mac);
    let oui = if m.len() >= 8 { &m[..8] } else { return "Unknown".to_string(); };
    match oui {
        // Routers / NICs (examples; extend as needed)
        "f4:f5:e8" => "TP-Link".to_string(),
        "b8:27:eb" => "Raspberry Pi".to_string(),
        "3c:84:6a" => "Ubiquiti".to_string(),
        "fc:ec:da" => "Xiaomi".to_string(),
        "d4:6a:6a" => "ASUSTek".to_string(),
        "1c:bf:c0" => "Samsung".to_string(),
        _ => get_vendor_from_mac(oui),
    }
}

// Best-effort type guess using trivial heuristics
fn guess_device_type(_ip: &str, vendor: &str) -> String {
    let v = vendor.to_lowercase();
    if v.contains("vmware") || v.contains("virtualbox") || v.contains("parallels") || v.contains("microsoft") {
        return "Computer".to_string();
    }
    if v.contains("apple") || v.contains("samsung") || v.contains("xiaomi") {
        return "Phone".to_string();
    }
    if v.contains("tp-link") || v.contains("ubiquiti") || v.contains("asus") {
        return "Router".to_string();
    }
    "Unknown".to_string()
}

// Reverse DNS lookup
async fn reverse_dns(ip: &str) -> Option<String> {
    let output = if cfg!(target_os = "windows") {
        std::process::Command::new("nslookup").arg(ip).output().ok()?
    } else {
        std::process::Command::new("nslookup").arg(ip).output().ok()?
    };
    let s = String::from_utf8_lossy(&output.stdout).to_string();
    for line in s.lines() {
        let l = line.trim().to_lowercase();
        if l.starts_with("name:") || l.contains("name =") || l.contains("имя =") {
            let parts: Vec<&str> = line.split(|c| c==':' || c=='=').collect();
            if parts.len() >= 2 { return Some(parts[1].trim().trim_end_matches('.').to_string()); }
        }
    }
    None
}

// NetBIOS name (Windows-only, best effort)
async fn netbios_name(ip: &str) -> Option<String> {
    if !cfg!(target_os = "windows") { return None; }
    let output = std::process::Command::new("nbtstat").arg("-A").arg(ip).output().ok()?;
    let s = String::from_utf8_lossy(&output.stdout).to_string();
    for line in s.lines() {
        let l = line.trim();
        if l.contains("<00>") && l.to_lowercase().contains("unique") {
            let name = l.split_whitespace().next().unwrap_or("").trim().to_string();
            if !name.is_empty() { return Some(name); }
        }
    }
    None
}

fn merge_devices(existing: &mut Vec<NetworkDevice>, new_devices: Vec<NetworkDevice>) {
    for new_device in new_devices {
        if let Some(existing_device) = existing.iter_mut().find(|d| d.ip == new_device.ip || d.mac == new_device.mac) {
            // Update existing device
            if existing_device.hostname.is_empty() && !new_device.hostname.is_empty() {
                existing_device.hostname = new_device.hostname;
            }
            if existing_device.vendor == "Unknown" && new_device.vendor != "Unknown" {
                existing_device.vendor = new_device.vendor;
            }
            if existing_device.device_type == "Unknown" && new_device.device_type != "Unknown" {
                existing_device.device_type = new_device.device_type;
            }
            existing_device.last_seen = new_device.last_seen;
        } else {
            existing.push(new_device);
        }
    }
}

async fn get_cached_devices() -> Result<Vec<NetworkDevice>, StatusCode> {
    // In a real implementation, this would read from a database or cache
    // For now, just return a fresh scan
    scan_network_devices().await
}

#[derive(Serialize, Deserialize, Clone)]
pub struct NetworkDevice {
    pub ip: String,
    pub mac: String,
    pub hostname: String,
    pub vendor: String,
    pub device_type: String,
    pub first_seen: u64,
    pub last_seen: u64,
    pub status: String, // online, offline, unknown
    pub tags: Vec<String>, // trusted, blocked, investigate, etc.
    pub notes: String,
    #[serde(default)]
    pub os: String,
}