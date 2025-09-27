use axum::{
    extract::{Query, WebSocketUpgrade},
    response::{Json, Response},
    routing::get,
    Router,
};
use axum::extract::ws::{WebSocket, Message};
use serde::{Deserialize, Serialize};
use std::sync::Arc;
use tokio::sync::{broadcast, Mutex};
use std::collections::HashMap;
use pnet::datalink;
use pcap::Capture;

#[derive(Debug, Serialize, Deserialize)]
pub struct Device {
    pub ip: String,
    pub mac: String,
    pub vendor: String,
    pub hostname: String,
    pub device_type: String,
}

#[derive(Debug, Serialize, Deserialize)]
pub struct Packet {
    pub time: String,
    pub source: String,
    pub destination: String,
    pub protocol: String,
    pub size: u32,
    pub info: String,
}

#[derive(Debug, Serialize, Deserialize)]
pub struct PacketQuery {
    pub ip: String,
}

// Global state for WebSocket connections  
use once_cell::sync::Lazy;
static WS_CONNECTIONS: Lazy<Arc<Mutex<HashMap<String, broadcast::Sender<String>>>>> = 
    Lazy::new(|| Arc::new(Mutex::new(HashMap::new())));

pub fn network_routes() -> Router {
    Router::new()
        .route("/start", get(start_collection))
        .route("/stop", get(stop_collection))
        .route("/packets", get(get_packets))
        .route("/ws", get(websocket_handler))
}

async fn start_collection() -> Json<Vec<Device>> {
    // Create WebSocket connection for this session
    let (tx, _rx) = broadcast::channel(100);
    let session_id = format!("session_{}", std::time::SystemTime::now().duration_since(std::time::UNIX_EPOCH).unwrap().as_secs());
    
    {
        let mut connections = WS_CONNECTIONS.lock().await;
        connections.insert(session_id.clone(), tx.clone());
    }
    
    // Start device collection
    let devices = collect_devices().await;
    
    // Send devices via WebSocket
    let _ = tx.send(serde_json::to_string(&devices).unwrap_or_default());
    
    Json(devices)
}

async fn stop_collection() -> &'static str {
    // Close all WebSocket connections
    {
        let mut connections = WS_CONNECTIONS.lock().await;
        connections.clear();
    }
    "Collection stopped"
}

async fn get_packets(Query(params): Query<PacketQuery>) -> Json<Vec<Packet>> {
    let packets = collect_packets(&params.ip).await;
    Json(packets)
}

async fn websocket_handler(ws: WebSocketUpgrade) -> Response {
    ws.on_upgrade(handle_socket)
}

async fn handle_socket(mut socket: WebSocket) {
    let mut rx = {
        let connections = WS_CONNECTIONS.lock().await;
        if let Some((_, tx)) = connections.iter().next() {
            tx.subscribe()
        } else {
            return;
        }
    };

    loop {
        tokio::select! {
            msg = socket.recv() => {
                if msg.is_none() || msg.unwrap().is_err() {
                    break;
                }
            }
            broadcast_msg = rx.recv() => {
                if let Ok(msg) = broadcast_msg {
                    if socket.send(Message::Text(msg)).await.is_err() {
                        break;
                    }
                }
            }
        }
    }
}

async fn collect_devices() -> Vec<Device> {
    let interfaces = datalink::interfaces();
    interfaces.into_iter().filter_map(|interface| match interface.is_up() {
        true => {
            let ip = interface.ips.first()
                .map(|ip| ip.ip().to_string())
                .unwrap_or_else(|| "Unknown".to_string());
            let mac = interface.mac
                .map(|mac| mac.to_string())
                .unwrap_or_else(|| "Unknown".to_string());
            
            Some(Device {
                ip,
                mac,
                vendor: "Unknown".to_string(),
                hostname: interface.name.clone(),
                device_type: "Network Interface".to_string(),
            })
        },
        false => None,
    }).collect()
}

async fn collect_packets(ip: &str) -> Vec<Packet> {
    let devices = datalink::interfaces();
    
    for device in &devices {
        if device.ips.iter().any(|addr| addr.is_ipv4() && addr.ip().to_string() == *ip) {
            if let Ok(cap) = Capture::from_device(device.name.as_str()) {
                if let Ok(cap) = cap.open() {
                    if let Ok(mut cap) = cap.setnonblock() {
                        let mut packets: Vec<Packet> = vec![];
                        for _ in 0..10 { // Limit to 10 packets for demo
                            match cap.next_packet() {
                                Ok(packet) => {
                                    packets.push(process_packet(&packet.data));
                                },
                                Err(_) => break,
                            }
                        }
                        
                        return packets;
                    }
                }
            }
        }
    }
    
    vec![] // Return an empty vector if no packets found or an error occurs
}

fn process_packet(data: &[u8]) -> Packet {
    use std::time::{SystemTime, UNIX_EPOCH};
    
    // Basic packet parsing - in real implementation you'd parse headers properly
    let time = SystemTime::now()
        .duration_since(UNIX_EPOCH)
        .unwrap()
        .as_secs()
        .to_string();
    
    // Extract basic info from packet data
    let source = if data.len() >= 26 {
        format!("{}.{}.{}.{}", data[26], data[27], data[28], data[29])
    } else {
        "Unknown".to_string()
    };
    
    let destination = if data.len() >= 30 {
        format!("{}.{}.{}.{}", data[30], data[31], data[32], data[33])
    } else {
        "Unknown".to_string()
    };
    
    let protocol = if data.len() >= 23 {
        match data[23] {
            1 => "ICMP",
            6 => "TCP",
            17 => "UDP",
            _ => "Other",
        }.to_string()
    } else {
        "Unknown".to_string()
    };
    
    Packet {
        time,
        source,
        destination,
        protocol,
        size: data.len() as u32,
        info: format!("Packet data length: {} bytes", data.len()),
    }
}
