use axum::{
    extract::ws::{WebSocketUpgrade, WebSocket, Message},
    extract::Query,
    response::IntoResponse,
};
use serde::Deserialize;
use serde_json::json;

#[cfg(feature = "packet-capture")]
use tokio::sync::mpsc;
#[cfg(feature = "packet-capture")]
use tracing::info;

#[cfg(feature = "packet-capture")]
use pnet::datalink::{self, Channel::Ethernet, Config};
#[cfg(feature = "packet-capture")]
use pnet::packet::{Packet, ethernet::EtherTypes, ipv4::Ipv4Packet, tcp::TcpPacket};

#[derive(Debug, Deserialize, Clone, Default)]
pub struct SniffParams {
    pub ip: Option<String>,
    pub iface: Option<String>,
}

pub async fn ws_sniff(ws: WebSocketUpgrade, Query(params): Query<SniffParams>) -> impl IntoResponse {
    ws.on_upgrade(move |socket| handle_socket(socket, params))
}

async fn handle_socket(socket: WebSocket, _params: SniffParams) {
    let mut socket = socket;
    
    #[cfg(not(feature = "packet-capture"))]
    {
        let error_msg = json!({
            "type": "error",
            "message": "Packet capture not available. Build with --features packet-capture and install Npcap/WinPcap on Windows.",
            "ts": now_ms()
        }).to_string();
        let _ = socket.send(Message::Text(error_msg)).await;
        return;
    }

    #[cfg(feature = "packet-capture")]
    {
        // Initialize tracing for debugging
        tracing_subscriber::fmt::init();

        // Select interface
        let iface = _params.iface.clone().unwrap_or_else(|| {
            #[cfg(unix)]
            { "wlan0".to_string() }
            #[cfg(windows)]
            { pnet::datalink::interfaces().into_iter().find(|i| i.is_up() && !i.is_loopback()).map(|i| i.name).unwrap_or_default() }
        });
        info!("Selected interface: {}", iface);

        let interfaces = datalink::interfaces();
        let interface = interfaces
            .into_iter()
            .find(|i| i.name == iface)
            .unwrap_or_else(|| {
                datalink::interfaces()
                    .into_iter()
                    .find(|i| i.is_up() && !i.is_loopback())
                    .expect("No suitable interface found")
            });

        // Attempt to set monitor mode (Unix only, Windows may require manual setup)
        #[cfg(unix)]
        {
            if let Err(e) = std::process::Command::new("iwconfig")
                .args(&[&iface, "mode", "monitor"])
                .status()
            {
                info!("Failed to set monitor mode: {}", e);
            } else {
                info!("Set {} to monitor mode", iface);
            }
        }
        #[cfg(windows)]
        {
            info!("Monitor mode not natively supported on Windows. Ensure Npcap is installed and adapter is in promiscuous mode.");
        }

        // Packet capture channel
        let mut config = Config::default();
        config.promiscuous = true;
        let (tx, mut rx) = mpsc::channel(100);
        tokio::spawn(async move {
            let (_tx, mut rx) = match datalink::channel(&interface, config) {
                Ok(Ethernet(tx, rx)) => (tx, rx),
                Ok(_) => {
                    info!("Unsupported channel type");
                    return;
                }
                Err(e) => {
                    info!("Failed to create channel: {}", e);
                    return;
                }
            };
            while let Ok(packet) = rx.next() {
                info!("Captured packet: {:?}", packet);
                if let Some(json) = parse_packet(packet, &_params) {
                    tx.send(json).await.unwrap();
                }
            }
        });

        // WebSocket handling
        tokio::select! {
            _ = socket.recv() => { info!("Client disconnected"); }
            msg = rx.recv() => {
                if let Some(json_str) = msg {
                    info!("Sending packet: {}", json_str);
                    socket.send(Message::Text(json_str)).await.unwrap();
                    // Placeholder for file logging (to be implemented later)
                    // std::fs::write("sniff.log", json_str).unwrap();
                }
            }
        }
    }
}

#[cfg(feature = "packet-capture")]
fn parse_packet(packet: &[u8], params: &SniffParams) -> Option<String> {
    use pnet::packet::ethernet::EthernetPacket;
    if let Some(eth) = EthernetPacket::new(packet) {
        match eth.get_ethertype() {
            EtherTypes::Ipv4 => {
                if let Some(ipv4) = Ipv4Packet::new(eth.payload()) {
                    let src = ipv4.get_source().to_string();
                    let dst = ipv4.get_destination().to_string();
                    if let Some(ref ipf) = _params.ip {
                        if src != *ipf && dst != *ipf {
                            return None;
                        }
                    }
                    if let Some(tcp) = TcpPacket::new(ipv4.payload()) {
                        let srcp = tcp.get_source();
                        let dstp = tcp.get_destination();
                        if let Some((m, p, h)) = parse_http_request(tcp.payload()) {
                            return Some(
                                json!({
                                    "type": "http",
                                    "method": m,
                                    "path": p,
                                    "host": h,
                                    "src": format!("{}.{}", src, srcp),
                                    "dst": format!("{}.{}", dst, dstp),
                                    "direction": dir(&_params.ip, &src),
                                    "ts": now_ms()
                                })
                                .to_string(),
                            );
                        }
                    }
                }
            }
            _ => {}
        }
    }
    None
}

#[cfg(feature = "packet-capture")]
fn parse_http_request(payload: &[u8]) -> Option<(String, String, String)> {
    if payload.is_empty() {
        return None;
    }
    let text = String::from_utf8_lossy(payload);
    let methods = ["GET ", "POST ", "PUT ", "DELETE ", "HEAD ", "OPTIONS ", "PATCH "];
    let pos = methods.iter().filter_map(|m| text.find(m)).min()?;
    let rest = &text[pos..];
    let line_end = rest.find('\n').unwrap_or(rest.len());
    let line = rest[..line_end].trim_end_matches(['\r']);
    let mut parts = line.split_whitespace();
    let method = parts.next()?.to_string();
    let path = parts.next().unwrap_or("/").to_string();
    let lower = rest.to_lowercase();
    if let Some(hpos) = lower.find("\nhost:") {
        let after = &rest[hpos + 1..];
        let end = after.find('\n').unwrap_or(after.len());
        let header = after[..end].trim();
        let host = header.splitn(2, ':').nth(1).unwrap_or("").trim().to_string();
        return Some((method, path, host));
    }
    Some((method, path, String::new()))
}

#[cfg(feature = "packet-capture")]
fn dir(sel: &Option<String>, src: &str) -> &'static str {
    match (sel, src) {
        (Some(s), src) if src.starts_with(s) => "out",
        (Some(_), _) => "in",
        _ => "unknown",
    }
}

fn now_ms() -> i64 {
    chrono::Utc::now().timestamp_millis()
}