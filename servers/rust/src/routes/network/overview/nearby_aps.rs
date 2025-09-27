use axum::{http::StatusCode, response::Json};
use serde_json::{json, Value};
use serde::{Serialize, Deserialize};
use std::process::Command;

pub async fn get_nearby_aps() -> Result<Json<Value>, StatusCode> {
    let data = get_real_nearby_aps().await?;
    Ok(Json(data))
}

async fn get_real_nearby_aps() -> Result<Value, StatusCode> {
    let aps = scan_nearby_aps().await?;
    let nearby_aps = json!({ "nearby_aps": aps });
    Ok(nearby_aps)
}

async fn scan_nearby_aps() -> Result<Vec<AccessPoint>, StatusCode> {
    if cfg!(target_os = "windows") {
        return scan_nearby_aps_windows().await;
    }

    let mut aps = Vec::new();
    if let Ok(scan_result) = scan_with_iwlist().await { aps.extend(scan_result); }
    if aps.is_empty() { if let Ok(scan_result) = scan_with_nmcli().await { aps.extend(scan_result); } }
    if aps.is_empty() { if let Ok(scan_result) = scan_with_iw().await { aps.extend(scan_result); } }
    
    Ok(aps)
}

async fn scan_with_iwlist() -> Result<Vec<AccessPoint>, StatusCode> {
    let output = Command::new("iwlist").arg("scan").output();
    match output {
        Ok(result) => {
            let output_str = String::from_utf8_lossy(&result.stdout);
            let mut aps = Vec::new();
            let mut current_ap = AccessPoint::default();
            for line in output_str.lines() {
                let line = line.trim();
                if line.starts_with("Cell") {
                    if !current_ap.ssid.is_empty() { aps.push(current_ap.clone()); }
                    current_ap = AccessPoint::default();
                } else if line.contains("ESSID:") {
                    if let Some(ssid) = line.split("ESSID:").nth(1) {
                        let ssid = ssid.trim().trim_matches('"');
                        if !ssid.is_empty() { current_ap.ssid = ssid.to_string(); }
                    }
                } else if line.contains("Address:") {
                    if let Some(bssid) = line.split("Address:").nth(1) { current_ap.bssid = bssid.trim().to_string(); }
                } else if line.contains("Signal level=") {
                    if let Some(level_part) = line.split("Signal level=").nth(1) {
                        if let Some(level) = level_part.split_whitespace().next() {
                            if let Ok(rssi) = level.parse::<i32>() { current_ap.rssi = rssi; }
                        }
                    }
                } else if line.contains("Channel:") {
                    if let Some(channel_part) = line.split("Channel:").nth(1) {
                        if let Ok(channel) = channel_part.trim().parse::<i32>() { current_ap.channel = channel; }
                    }
                } else if line.contains("Encryption key:") {
                    current_ap.security = if line.contains("off") { "Open".to_string() } else { "Secured".to_string() };
                } else if line.contains("Frequency:") {
                    if let Some(freq_part) = line.split("Frequency:").nth(1) {
                        if let Some(freq) = freq_part.split(' ').next() {
                            if let Ok(frequency) = freq.parse::<f32>() { current_ap.frequency = frequency as i32; }
                        }
                    }
                }
            }
            if !current_ap.ssid.is_empty() { aps.push(current_ap); }
            Ok(aps)
        }
        Err(_) => Err(StatusCode::INTERNAL_SERVER_ERROR)
    }
}

async fn scan_with_nmcli() -> Result<Vec<AccessPoint>, StatusCode> {
    let output = Command::new("nmcli")
        .arg("-t").arg("-f").arg("SSID,BSSID,SIGNAL,CHAN,SECURITY")
        .arg("dev").arg("wifi").arg("list")
        .output();
    match output {
        Ok(result) => {
            let output_str = String::from_utf8_lossy(&result.stdout);
            let mut aps = Vec::new();
            for line in output_str.lines() {
                let parts: Vec<&str> = line.split(':').collect();
                if parts.len() >= 5 {
                    let mut ap = AccessPoint::default();
                    ap.ssid = parts[0].to_string();
                    ap.bssid = parts[1].to_string();
                    if let Ok(signal) = parts[2].parse::<i32>() { ap.rssi = signal; }
                    if let Ok(channel) = parts[3].parse::<i32>() { ap.channel = channel; }
                    ap.security = parts[4].to_string();
                    if !ap.ssid.is_empty() { aps.push(ap); }
                }
            }
            Ok(aps)
        }
        Err(_) => Err(StatusCode::INTERNAL_SERVER_ERROR)
    }
}

async fn scan_with_iw() -> Result<Vec<AccessPoint>, StatusCode> {
    let interface = get_wifi_interface().await?;
    let output = Command::new("iw").arg("dev").arg(&interface).arg("scan").output();
    match output {
        Ok(result) => {
            let output_str = String::from_utf8_lossy(&result.stdout);
            let mut aps = Vec::new();
            let mut current_ap = AccessPoint::default();
            for line in output_str.lines() {
                let line = line.trim();
                if line.starts_with("BSS") {
                    if !current_ap.ssid.is_empty() { aps.push(current_ap.clone()); }
                    current_ap = AccessPoint::default();
                    if let Some(bssid) = line.split_whitespace().nth(1) { current_ap.bssid = bssid.to_string(); }
                } else if line.contains("signal:") {
                    if let Some(signal_part) = line.split("signal:").nth(1) {
                        if let Some(signal) = signal_part.split_whitespace().next() {
                            if let Ok(rssi) = signal.parse::<i32>() { current_ap.rssi = rssi; }
                        }
                    }
                } else if line.contains("SSID:") {
                    if let Some(ssid_part) = line.split("SSID:").nth(1) { current_ap.ssid = ssid_part.trim().to_string(); }
                } else if line.contains("DS Parameter set: channel") {
                    if let Some(channel_part) = line.split("channel").nth(1) {
                        if let Ok(channel) = channel_part.trim().parse::<i32>() { current_ap.channel = channel; }
                    }
                }
            }
            if !current_ap.ssid.is_empty() { aps.push(current_ap); }
            Ok(aps)
        }
        Err(_) => Err(StatusCode::INTERNAL_SERVER_ERROR)
    }
}

async fn get_wifi_interface() -> Result<String, StatusCode> {
    if cfg!(target_os = "windows") {
        return get_wifi_interface_windows();
    }
    let output = Command::new("iwconfig").output();
    if let Ok(result) = output {
        let output_str = String::from_utf8_lossy(&result.stdout);
        for line in output_str.lines() {
            if line.contains("IEEE 802.11") {
                if let Some(interface) = line.split_whitespace().next() { return Ok(interface.to_string()); }
            }
        }
    }
    let common_interfaces = ["wlan0", "wlp3s0", "wlp2s0", "wlp1s0"];
    for interface in &common_interfaces {
        let output = Command::new("iwconfig").arg(interface).output();
        if let Ok(result) = output { if result.status.success() { return Ok(interface.to_string()); } }
    }
    Err(StatusCode::NOT_FOUND)
}

// Windows fallbacks for interface and scans
fn get_wifi_interface_windows() -> Result<String, StatusCode> {
    let output = Command::new("netsh").arg("wlan").arg("show").arg("interfaces").output();
    if let Ok(result) = output {
        let stdout = String::from_utf8_lossy(&result.stdout);
        for raw_line in stdout.lines() {
            let line = raw_line.trim();
            if line.to_lowercase().starts_with("name") || line.to_lowercase().starts_with("имя") {
                if let Some(v) = line.split(':').nth(1) {
                    let name = v.trim();
                    if !name.is_empty() { return Ok(name.to_string()); }
                }
            }
        }
    }
    Err(StatusCode::NOT_FOUND)
}

#[derive(Default, Clone, Serialize, Deserialize)]
struct AccessPoint { ssid: String, bssid: String, rssi: i32, channel: i32, security: String, frequency: i32 }

// Windows implementation
async fn scan_nearby_aps_windows() -> Result<Vec<AccessPoint>, StatusCode> {
    // Use netsh wlan show networks mode=bssid for detailed scan
    let output = Command::new("netsh")
        .arg("wlan")
        .arg("show")
        .arg("networks")
        .arg("mode=bssid")
        .output();

    if let Ok(result) = output {
        let output_str = String::from_utf8_lossy(&result.stdout);
        let mut aps = Vec::new();
        let mut current_ap = AccessPoint::default();
        
        for line in output_str.lines() {
            let line = line.trim();
            let line_lower = line.to_lowercase();
            
            // Parse SSID
            if (line_lower.starts_with("ssid") || line_lower.contains("имя сети")) && line.contains(':') {
                if let Some(colon_pos) = line.find(':') {
                    let ssid = line[colon_pos + 1..].trim();
                    if !ssid.is_empty() {
                        // If we have a previous AP, save it
                        if !current_ap.ssid.is_empty() {
                            aps.push(current_ap.clone());
                        }
                        current_ap = AccessPoint::default();
                        current_ap.ssid = ssid.to_string();
                    }
                }
            }
            // Parse BSSID
            else if line_lower.contains("bssid") && line.contains(':') {
                // Find the MAC address pattern
                if let Some(mac_start) = line.find(|c: char| c.is_ascii_hexdigit()) {
                    let mac_part = &line[mac_start..];
                    if let Some(mac_end) = mac_part.find(' ') {
                        current_ap.bssid = mac_part[..mac_end].trim().to_string();
                    } else {
                        current_ap.bssid = mac_part.trim().to_string();
                    }
                }
            }
            // Parse Signal
            else if (line_lower.contains("signal") || line_lower.contains("сигнал")) && line.contains(':') {
                if let Some(colon_pos) = line.find(':') {
                    let signal_str = line[colon_pos + 1..].trim().trim_end_matches('%');
                    if let Ok(percent) = signal_str.parse::<i32>() {
                        current_ap.rssi = (percent / 2) - 100; // Convert % to approximate dBm
                    }
                }
            }
            // Parse Channel
            else if (line_lower.contains("channel") || line_lower.contains("канал")) && line.contains(':') {
                if let Some(colon_pos) = line.find(':') {
                    let channel_str = line[colon_pos + 1..].trim();
                    if let Ok(ch) = channel_str.parse::<i32>() {
                        current_ap.channel = ch;
                        current_ap.frequency = channel_to_frequency(ch);
                    }
                }
            }
            // Parse Authentication/Security
            else if (line_lower.contains("authentication") || line_lower.contains("аутентификация") || line_lower.contains("auth")) && line.contains(':') {
                if let Some(colon_pos) = line.find(':') {
                    current_ap.security = line[colon_pos + 1..].trim().to_string();
                }
            }
            // Parse Encryption
            else if (line_lower.contains("encryption") || line_lower.contains("шифрование")) && line.contains(':') && current_ap.security.is_empty() {
                if let Some(colon_pos) = line.find(':') {
                    current_ap.security = line[colon_pos + 1..].trim().to_string();
                }
            }
        }
        
        // Don't forget the last AP
        if !current_ap.ssid.is_empty() {
            if current_ap.security.is_empty() {
                current_ap.security = "Unknown".to_string();
            }
            aps.push(current_ap);
        }
        
        return Ok(aps);
    }
    
    // Fallback: try show profiles to get at least saved networks
    let output = Command::new("netsh")
        .arg("wlan")
        .arg("show")
        .arg("profiles")
        .output();
        
    if let Ok(result) = output {
        let output_str = String::from_utf8_lossy(&result.stdout);
        let mut aps = Vec::new();
        
        for line in output_str.lines() {
            let line_lower = line.to_lowercase();
            if (line_lower.contains("all user profile") || line_lower.contains("профиль всех пользователей")) && line.contains(':') {
                if let Some(colon_pos) = line.find(':') {
                    let ssid = line[colon_pos + 1..].trim();
                    if !ssid.is_empty() {
                        aps.push(AccessPoint {
                            ssid: ssid.to_string(),
                            bssid: "Unknown".to_string(),
                            rssi: -60, // Estimated
                            channel: 6, // Common channel
                            security: "WPA2".to_string(),
                            frequency: 2437,
                        });
                    }
                }
            }
        }
        
        if !aps.is_empty() {
            return Ok(aps);
        }
    }
    
    Ok(vec![])
}

fn channel_to_frequency(channel: i32) -> i32 {
    if channel >= 1 && channel <= 13 { return 2407 + channel * 5; }
    if channel == 14 { return 2484; }
    if channel >= 32 && channel <= 196 { return 5000 + channel * 5; }
    0
}


