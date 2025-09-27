use axum::{extract::ws::{Message, WebSocket, WebSocketUpgrade}, response::IntoResponse};
use futures_util::{SinkExt, StreamExt};
use serde_json::json;
use tokio::{time::{interval, Duration}};
use std::sync::Arc;
use tokio::sync::Mutex;
 

pub async fn ws_handler(ws: WebSocketUpgrade) -> impl IntoResponse {
    ws.on_upgrade(handle_socket)
}

async fn handle_socket(socket: WebSocket) {
    let (sender, mut receiver) = socket.split();
    let sender = Arc::new(Mutex::new(sender));
    let mut stream_task: Option<tokio::task::JoinHandle<()>> = None;
    while let Some(Ok(msg)) = receiver.next().await {
        match msg {
            Message::Text(text) => {
                let t = text.trim().to_lowercase();
                if t.contains("start") {
                    // start stream task if not running
                    if stream_task.is_none() {
                        let s = Arc::clone(&sender);
                        let task = tokio::spawn(async move {
                            let mut ticker = interval(Duration::from_secs(5));
                            loop {
                                ticker.tick().await;
                                if let Some(payload) = gather_devices_json().await {
                                    let mut sink = s.lock().await;
                                    let _ = sink.send(Message::Text(payload)).await;
                                }
                            }
                        });
                        stream_task = Some(task);
                        // push immediate snapshot
                        if let Some(payload) = gather_devices_json().await {
                            let mut sink = sender.lock().await;
                            let _ = sink.send(Message::Text(payload)).await;
                        }
                    }
                } else if t.contains("stop") {
                    if let Some(task) = stream_task.take() { task.abort(); }
                    let mut sink = sender.lock().await;
                    let _ = sink.send(Message::Text(json!({"type":"stopped"}).to_string())).await;
                }
            }
            Message::Close(_) => { if let Some(task) = stream_task.take() { task.abort(); } break; }
            _ => {}
        }
    }
}

async fn gather_devices_json() -> Option<String> {
    let inv = super::devices::discovery::get_device_inventory().await.ok()?;
    let devices = inv.0.get("devices")?.clone();
    Some(json!({"type":"devices","devices": devices}).to_string())
}


