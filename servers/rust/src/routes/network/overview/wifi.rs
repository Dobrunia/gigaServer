use axum::{http::StatusCode, response::Json};
use serde_json::{json, Value};
use std::process::Command;

pub async fn get_wifi_status() -> Result<Json<Value>, StatusCode> {
    let status = get_real_wifi_status().await?;
    Ok(Json(status))
}

async fn get_real_wifi_status() -> Result<Value, StatusCode> {
    if cfg!(target_os = "windows") {
        return get_wifi_status_windows().await;
    }

    let interface_result = get_wifi_interface().await;
    if interface_result.is_err() {
        return Err(StatusCode::NOT_FOUND);
    }

    let interface = interface_result?;
    let ssid = get_ssid(&interface).await?;
    let bssid = get_bssid(&interface).await?;
    let channel = get_channel(&interface).await?;
    let signal_strength = get_signal_strength(&interface).await?;
    let gateway_ip = get_gateway_ip().await?;
    let frequency = get_frequency(&interface).await?;
    let security = get_security(&interface).await?;

    let wifi_status = json!({
        "ssid": ssid,
        "bssid": bssid,
        "channel": channel,
        "gateway_ip": gateway_ip,
        "signal_strength": signal_strength,
        "frequency": frequency,
        "security": security
    });

    Ok(wifi_status)
}

async fn get_wifi_interface() -> Result<String, StatusCode> {
    let output = Command::new("iwconfig")
        .output();

    match output {
        Ok(result) => {
            let output_str = String::from_utf8_lossy(&result.stdout);
            for line in output_str.lines() {
                if line.contains("IEEE 802.11") {
                    if let Some(interface) = line.split_whitespace().next() {
                        return Ok(interface.to_string());
                    }
                }
            }
        }
        Err(_) => {}
    }

    let common_interfaces = ["wlan0", "wlp3s0", "wlp2s0", "wlp1s0"];
    for interface in &common_interfaces {
        let output = Command::new("iwconfig")
            .arg(interface)
            .output();
        
        if let Ok(result) = output {
            if result.status.success() {
                return Ok(interface.to_string());
            }
        }
    }

    Err(StatusCode::NOT_FOUND)
}

async fn get_ssid(interface: &str) -> Result<String, StatusCode> {
    let output = Command::new("iwconfig")
        .arg(interface)
        .output();

    match output {
        Ok(result) => {
            let output_str = String::from_utf8_lossy(&result.stdout);
            for line in output_str.lines() {
                if line.contains("ESSID:") {
                    if let Some(ssid) = line.split("ESSID:").nth(1) {
                        let ssid = ssid.trim().trim_matches('"');
                        if !ssid.is_empty() && ssid != "off/any" {
                            return Ok(ssid.to_string());
                        }
                    }
                }
            }
        }
        Err(_) => {}
    }

    Ok("Not Connected".to_string())
}

async fn get_bssid(interface: &str) -> Result<String, StatusCode> {
    let output = Command::new("iwconfig")
        .arg(interface)
        .output();

    match output {
        Ok(result) => {
            let output_str = String::from_utf8_lossy(&result.stdout);
            for line in output_str.lines() {
                if line.contains("Access Point:") {
                    if let Some(bssid) = line.split("Access Point:").nth(1) {
                        let bssid = bssid.trim();
                        if !bssid.is_empty() && bssid != "Not-Associated" {
                            return Ok(bssid.to_string());
                        }
                    }
                }
            }
        }
        Err(_) => {}
    }

    Ok("Not Associated".to_string())
}

async fn get_channel(interface: &str) -> Result<i32, StatusCode> {
    let output = Command::new("iwlist")
        .arg(interface)
        .arg("channel")
        .output();

    match output {
        Ok(result) => {
            let output_str = String::from_utf8_lossy(&result.stdout);
            for line in output_str.lines() {
                if line.contains("Current Frequency:") {
                    if let Some(freq_part) = line.split("(").nth(1) {
                        if let Some(channel_part) = freq_part.split(")").next() {
                            if let Some(channel) = channel_part.split("Channel").nth(1) {
                                if let Ok(ch) = channel.trim().parse::<i32>() {
                                    return Ok(ch);
                                }
                            }
                        }
                    }
                }
            }
        }
        Err(_) => {}
    }

    Ok(0)
}

async fn get_signal_strength(interface: &str) -> Result<i32, StatusCode> {
    let output = Command::new("iwconfig")
        .arg(interface)
        .output();

    match output {
        Ok(result) => {
            let output_str = String::from_utf8_lossy(&result.stdout);
            for line in output_str.lines() {
                if line.contains("Signal level=") {
                    if let Some(level_part) = line.split("Signal level=").nth(1) {
                        if let Some(level) = level_part.split_whitespace().next() {
                            if let Ok(rssi) = level.parse::<i32>() {
                                return Ok(rssi);
                            }
                        }
                    }
                }
            }
        }
        Err(_) => {}
    }

    Ok(-100)
}

async fn get_gateway_ip() -> Result<String, StatusCode> {
    let output = Command::new("ip")
        .arg("route")
        .arg("show")
        .arg("default")
        .output();

    match output {
        Ok(result) => {
            let output_str = String::from_utf8_lossy(&result.stdout);
            for line in output_str.lines() {
                if line.contains("default via") {
                    if let Some(gateway) = line.split_whitespace().nth(2) {
                        return Ok(gateway.to_string());
                    }
                }
            }
        }
        Err(_) => {}
    }

    let output = Command::new("route")
        .arg("-n")
        .output();

    match output {
        Ok(result) => {
            let output_str = String::from_utf8_lossy(&result.stdout);
            for line in output_str.lines() {
                if line.starts_with("0.0.0.0") {
                    if let Some(gateway) = line.split_whitespace().nth(1) {
                        return Ok(gateway.to_string());
                    }
                }
            }
        }
        Err(_) => {}
    }

    Ok("Unknown".to_string())
}

async fn get_frequency(interface: &str) -> Result<i32, StatusCode> {
    let output = Command::new("iwlist")
        .arg(interface)
        .arg("freq")
        .output();

    match output {
        Ok(result) => {
            let output_str = String::from_utf8_lossy(&result.stdout);
            for line in output_str.lines() {
                if line.contains("Current Frequency:") {
                    if let Some(freq_part) = line.split(":").nth(1) {
                        if let Some(freq) = freq_part.split(" ").next() {
                            if let Ok(frequency) = freq.parse::<f32>() {
                                return Ok(frequency as i32);
                            }
                        }
                    }
                }
            }
        }
        Err(_) => {}
    }

    Ok(0)
}

async fn get_security(interface: &str) -> Result<String, StatusCode> {
    let output = Command::new("iwconfig")
        .arg(interface)
        .output();

    match output {
        Ok(result) => {
            let output_str = String::from_utf8_lossy(&result.stdout);
            for line in output_str.lines() {
                if line.contains("Encryption key:") {
                    if line.contains("off") {
                        return Ok("Open".to_string());
                    } else {
                        return Ok("Secured".to_string());
                    }
                }
            }
        }
        Err(_) => {}
    }

    Ok("Unknown".to_string())
}

// ---------------- Windows fallbacks ----------------
async fn get_wifi_status_windows() -> Result<Value, StatusCode> {
    // Use `netsh wlan show interfaces` which is available on Windows
    let output = Command::new("netsh")
        .arg("wlan")
        .arg("show")
        .arg("interfaces")
        .output();

    match output {
        Ok(result) => {
            let mut ssid = String::new();
            let mut bssid = String::new();
            let mut channel: i32 = 0;
            let mut signal_percent: i32 = -1;
            let mut auth = String::new();

            let stdout = String::from_utf8_lossy(&result.stdout);
            for raw_line in stdout.lines() {
                let line = raw_line.trim();
                let line_lower = line.to_lowercase();
                
                // More flexible parsing for different locales
                if (line_lower.contains("ssid") && !line_lower.contains("bssid")) && ssid.is_empty() {
                    if let Some(colon_pos) = line.find(':') {
                        ssid = line[colon_pos + 1..].trim().to_string();
                    }
                } else if line_lower.contains("bssid") && bssid.is_empty() {
                    if let Some(colon_pos) = line.find(':') {
                        bssid = line[colon_pos + 1..].trim().to_string();
                    }
                } else if (line_lower.contains("channel") || line_lower.contains("канал")) && channel == 0 {
                    if let Some(colon_pos) = line.find(':') {
                        let channel_str = line[colon_pos + 1..].trim();
                        if let Ok(ch) = channel_str.parse::<i32>() { 
                            channel = ch; 
                        }
                    }
                } else if (line_lower.contains("signal") || line_lower.contains("сигнал")) && signal_percent < 0 {
                    if let Some(colon_pos) = line.find(':') {
                        let signal_str = line[colon_pos + 1..].trim().trim_end_matches('%');
                        if let Ok(p) = signal_str.parse::<i32>() { 
                            signal_percent = p; 
                        }
                    }
                } else if (line_lower.contains("authentication") || line_lower.contains("аутентифик") || line_lower.contains("auth")) && auth.is_empty() {
                    if let Some(colon_pos) = line.find(':') {
                        auth = line[colon_pos + 1..].trim().to_string();
                    }
                }
            }

            // If we couldn't get data from interfaces, try show profile
            if ssid.is_empty() {
                if let Ok(profile_result) = Command::new("netsh")
                    .arg("wlan")
                    .arg("show")
                    .arg("profile")
                    .output() 
                {
                    let profile_stdout = String::from_utf8_lossy(&profile_result.stdout);
                    // Get first profile name as current SSID
                    for line in profile_stdout.lines() {
                        if line.trim().contains("All User Profile") || line.trim().contains("Профиль всех пользователей") {
                            if let Some(colon_pos) = line.find(':') {
                                ssid = line[colon_pos + 1..].trim().to_string();
                                break;
                            }
                        }
                    }
                }
            }

            // Derive values
            let frequency = channel_to_frequency(channel);
            let rssi_dbm = if signal_percent >= 0 { (signal_percent / 2) - 100 } else { -100 };
            let gateway_ip = get_gateway_ip_windows().unwrap_or_else(|_| "Unknown".to_string());

            let wifi_status = json!({
                "ssid": if ssid.is_empty() { "Not Connected".to_string() } else { ssid },
                "bssid": if bssid.is_empty() { "Not Available".to_string() } else { bssid },
                "channel": if channel == 0 { 1 } else { channel },
                "gateway_ip": gateway_ip,
                "signal_strength": rssi_dbm,
                "frequency": if frequency == 0 { 2412 } else { frequency },
                "security": if auth.is_empty() { "Unknown".to_string() } else { auth }
            });
            Ok(wifi_status)
        }
        Err(_) => Err(StatusCode::INTERNAL_SERVER_ERROR)
    }
}

fn channel_to_frequency(channel: i32) -> i32 {
    if channel >= 1 && channel <= 13 { return 2407 + channel * 5; }
    if channel == 14 { return 2484; }
    if channel >= 32 && channel <= 196 { return 5000 + channel * 5; }
    0
}

fn get_gateway_ip_windows() -> Result<String, StatusCode> {
    // Use `ipconfig` and try to find "Default Gateway"
    let output = Command::new("ipconfig").output();
    if let Ok(result) = output {
        let stdout = String::from_utf8_lossy(&result.stdout);
        for raw_line in stdout.lines() {
            let line = raw_line.trim();
            let ll = line.to_lowercase();
            if ll.contains("default gateway") || ll.contains("основной шлюз") {
                if let Some(v) = line.split(':').nth(1) {
                    let gw = v.trim();
                    if !gw.is_empty() { return Ok(gw.to_string()); }
                }
            }
        }
    }
    Err(StatusCode::NOT_FOUND)
}


