use axum::{http::StatusCode, response::Json};
use serde::{Deserialize, Serialize};
use serde_json::{json, Value};
use std::process::{Child, Command, Stdio};
use std::sync::{Arc, Mutex};
use once_cell::sync::Lazy;
use chrono::{DateTime, Utc};

#[derive(Clone, Serialize)]
struct CaptureStatus {
    consent: bool,
    running: bool,
    started_at: Option<i64>,
    last_file: Option<String>,
    privacy_mask: bool,
    audit: Vec<String>,
}

struct CaptureState {
    consent: bool,
    running: bool,
    child: Option<Child>,
    started_at: Option<DateTime<Utc>>,
    last_file: Option<String>,
    privacy_mask: bool,
    audit: Vec<String>,
}

static STATE: Lazy<Arc<Mutex<CaptureState>>> = Lazy::new(|| {
    Arc::new(Mutex::new(CaptureState {
        consent: true,
        running: false,
        child: None,
        started_at: None,
        last_file: None,
        privacy_mask: true,
        audit: vec![format!("{} consent preset to true", Utc::now())],
    }))
});

#[derive(Deserialize)]
pub struct ConsentReq { pub accept: bool, pub user: Option<String> }

pub async fn set_consent(Json(payload): Json<ConsentReq>) -> Result<Json<Value>, StatusCode> {
    let mut st = STATE.lock().unwrap();
    st.consent = payload.accept;
    st.audit.push(format!("{} consent set to {}", Utc::now(), payload.accept));
    Ok(Json(json!({"ok": true, "consent": st.consent})))
}

#[derive(Deserialize)]
pub struct StartReq {
    pub privacy_mask: Option<bool>,
    pub iface: Option<String>,
    pub bpf: Option<String>,
    pub ring_mb: Option<u32>,
    pub targets: Option<Vec<String>>, // list of device IPv4/IPv6 addresses to sniff
}

pub async fn start_capture(Json(payload): Json<StartReq>) -> Result<Json<Value>, StatusCode> {
    let mut st = STATE.lock().unwrap();
    if !st.consent { return Err(StatusCode::FORBIDDEN); }
    if st.running { return Ok(Json(json!({"ok": true, "running": true}))); }

    st.privacy_mask = payload.privacy_mask.unwrap_or(true);

    #[cfg(target_os = "windows")]
    let child = {
        // Use pktmon ETW capture (Windows 10+). This writes PktMon.etl in the working dir.
        // Attempt to apply IPv4/IPv6 address filters for targets; ignore errors if unsupported.
        let _ = Command::new("pktmon").arg("stop").output();
        let _ = Command::new("pktmon").arg("unload").output();
        if let Some(tgts) = payload.targets.as_ref() {
            for ip in tgts.iter().filter(|s| !s.trim().is_empty()) {
                // Best-effort: try IPv4 then IPv6 syntax; failures are ignored
                let _ = Command::new("pktmon").args(["filter","add","-t","ipv4","-a", ip]).output();
                let _ = Command::new("pktmon").args(["filter","add","-t","ipv6","-a", ip]).output();
            }
        }
        Command::new("pktmon").arg("start").arg("--etw").stdout(Stdio::null()).stderr(Stdio::null()).spawn()
    };

    #[cfg(not(target_os = "windows"))]
    let child = {
        // Try tcpdump with file output; build BPF from targets if not provided
        let iface = payload.iface.unwrap_or("any".to_string());
        let file = "capture.pcap";
        let _ = std::fs::remove_file(file);
        let user_bpf = payload.bpf.unwrap_or_default();
        let target_bpf = payload.targets.unwrap_or_default()
            .into_iter()
            .filter(|s| !s.trim().is_empty())
            .map(|ip| format!("host {}", ip))
            .collect::<Vec<_>>()
            .join(" or ");
        let combined_bpf = if !user_bpf.is_empty() && !target_bpf.is_empty() {
            format!("({}) and ({})", user_bpf, target_bpf)
        } else if !user_bpf.is_empty() {
            user_bpf
        } else {
            target_bpf
        };
        let cmd = if combined_bpf.trim().is_empty() {
            format!("tcpdump -i {} -w {}", iface, file)
        } else {
            format!("tcpdump -i {} -w {} \"{}\"", iface, file, combined_bpf)
        };
        Command::new("sh").arg("-c")
            .arg(cmd)
            .stdout(Stdio::null()).stderr(Stdio::null()).spawn()
    };

    match child {
        Ok(ch) => {
            st.running = true;
            st.child = Some(ch);
            st.started_at = Some(Utc::now());
            st.audit.push(format!("{} capture started", Utc::now()));
            Ok(Json(json!({"ok": true, "running": true})))
        }
        Err(_) => Err(StatusCode::INTERNAL_SERVER_ERROR)
    }
}

pub async fn stop_capture() -> Result<Json<Value>, StatusCode> {
    let mut st = STATE.lock().unwrap();
    if !st.running { return Ok(Json(json!({"ok": true, "running": false}))); }

    #[cfg(target_os = "windows")]
    {
        let _ = Command::new("pktmon").arg("stop").output();
        // Convert to pcapng
        let _ = Command::new("pktmon").arg("format").arg("PktMon.etl").arg("-o").arg("capture.pcapng").arg("-p").output();
        st.last_file = Some("capture.pcapng".to_string());
    }
    #[cfg(not(target_os = "windows"))]
    {
        if let Some(mut ch) = st.child.take() { let _ = ch.kill(); let _ = ch.wait(); }
        st.last_file = Some("capture.pcap".to_string());
    }

    st.running = false;
    st.audit.push(format!("{} capture stopped", Utc::now()));
    Ok(Json(json!({"ok": true, "running": false, "file": st.last_file})))
}

pub async fn get_status() -> Result<Json<Value>, StatusCode> {
    let st = STATE.lock().unwrap();
    let status = CaptureStatus {
        consent: st.consent,
        running: st.running,
        started_at: st.started_at.map(|t| t.timestamp()),
        last_file: st.last_file.clone(),
        privacy_mask: st.privacy_mask,
        audit: st.audit.clone(),
    };
    Ok(Json(serde_json::to_value(status).unwrap()))
}


