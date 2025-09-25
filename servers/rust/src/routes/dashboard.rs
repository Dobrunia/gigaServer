use axum::{routing::{get, post}, Router, response::IntoResponse, Json, extract::State};
use serde_json::json;
use serde::{Deserialize, Serialize};
use std::sync::{Arc, Mutex};
use reqwest::Client;
use tracing::{info, warn, error, debug};

const GO_SERVER_BASE: &str = "http://127.0.0.1:3002/go";

#[derive(Clone)]
struct AppState { 
    http: Client,
    session_data: Arc<Mutex<SessionData>>
}

#[derive(Default, Serialize, Deserialize)]
struct SessionData {
    network_history: Vec<NetworkPoint>,
    cpu_history: Vec<f64>,
    gpu_history: Vec<f64>,
    current_host: String,
}

#[derive(Serialize, Deserialize)]
struct NetworkPoint {
    rx: f64,
    tx: f64,
    timestamp: u64,
}

pub fn create_routes() -> Router {
    let state = AppState { 
        http: Client::new(),
        session_data: Arc::new(Mutex::new(SessionData::default()))
    };
    info!("Initializing dashboard routes");
    Router::new()
        .route("/rust/ssh/connect", post(ssh_connect))
        .route("/rust/ssh/disconnect", post(ssh_disconnect))
        .route("/rust/ssh/execute", post(ssh_execute))
        .route("/rust/data/processes", get(get_processes))
        .route("/rust/data/ports", get(get_ports))
        .route("/rust/data/connections", get(get_connections))
        .route("/rust/data/client-ips", get(get_client_ips))
        .route("/rust/data/process-logs", get(get_process_logs))
        .route("/rust/data/resources", get(get_resources))
        .route("/rust/data/network", get(get_network))
        .route("/rust/session/save", post(save_session))
        .route("/rust/session/restore", get(restore_session))
        .route("/rust/ssh/status", get(get_ssh_status))
        .with_state(Arc::new(state))
}

#[derive(Deserialize)]
struct SSHConnectReq { host: String, user: String, port: Option<u16>, password: Option<String> }

#[derive(Deserialize)]
struct SSHExecuteReq { command: String }

async fn ssh_connect(State(state): State<Arc<AppState>>, Json(body): Json<SSHConnectReq>) -> impl IntoResponse {
    info!("ssh_connect: host={} user={} port={}", body.host, body.user, body.port.unwrap_or(22));
    let go_url = format!("{}/ssh/connect", GO_SERVER_BASE);
    let resp = state.http.post(&go_url).json(&json!({
        "host": body.host,
        "user": body.user,
        "port": body.port.unwrap_or(22),
        "password": body.password
    })).send().await;
    match resp {
        Ok(r) => {
            let status = r.status();
            let text = r.text().await.unwrap_or_else(|_| "".into());
            info!("ssh_connect result: status={} bytes={}", status.as_u16(), text.len());
            (status, text)
        }
        Err(e) => {
            error!("ssh_connect error: {}", e);
            (axum::http::StatusCode::BAD_GATEWAY, format!("connection error: {}", e))
        }
    }
}

async fn ssh_disconnect(State(state): State<Arc<AppState>>) -> impl IntoResponse {
    info!("ssh_disconnect");
    let go_url = format!("{}/ssh/disconnect", GO_SERVER_BASE);
    let resp = state.http.post(&go_url).send().await;
    match resp {
        Ok(r) => {
            let status = r.status();
            let text = r.text().await.unwrap_or_else(|_| "".into());
            info!("ssh_disconnect result: status={} bytes={}", status.as_u16(), text.len());
            (status, text)
        }
        Err(e) => {
            error!("ssh_disconnect error: {}", e);
            (axum::http::StatusCode::BAD_GATEWAY, format!("connection error: {}", e))
        }
    }
}

async fn ssh_execute(State(state): State<Arc<AppState>>, Json(body): Json<SSHExecuteReq>) -> impl IntoResponse {
    let preview = body.command.chars().take(60).collect::<String>();
    debug!("ssh_execute: cmd_preview=\"{}\"", preview);
    let go_url = format!("{}/ssh/execute", GO_SERVER_BASE);
    let resp = state.http.post(&go_url).json(&json!({
        "command": body.command
    })).send().await;
    match resp {
        Ok(r) => {
            let status = r.status();
            let text = r.text().await.unwrap_or_else(|_| "".into());
            info!("ssh_execute result: status={} bytes={}", status.as_u16(), text.len());
            (status, text)
        }
        Err(e) => {
            error!("ssh_execute error: {}", e);
            (axum::http::StatusCode::BAD_GATEWAY, format!("connection error: {}", e))
        }
    }
}

async fn get_connections(State(state): State<Arc<AppState>>) -> impl IntoResponse {
    debug!("get_connections");
    let go_url = format!("{}/data/connections", GO_SERVER_BASE);
    let resp = state.http.get(&go_url).send().await;
    match resp { 
        Ok(r) => { 
            let s=r.status(); 
            let t=r.text().await.unwrap_or_default(); 
            info!("get_connections: status={} bytes={}", s.as_u16(), t.len());
            (s,t) 
        }, 
        Err(e)=> {
            error!("get_connections error: {}", e);
            (axum::http::StatusCode::BAD_GATEWAY, format!("connection error: {}", e)) 
        }
    }
}

async fn get_client_ips(State(state): State<Arc<AppState>>) -> impl IntoResponse {
    debug!("get_client_ips");
    let go_url = format!("{}/data/client-ips", GO_SERVER_BASE);
    let resp = state.http.get(&go_url).send().await;
    match resp { 
        Ok(r) => { let s=r.status(); let t=r.text().await.unwrap_or_default(); info!("get_client_ips: status={} bytes={}", s.as_u16(), t.len()); (s,t) }, 
        Err(e)=> { error!("get_client_ips error: {}", e); (axum::http::StatusCode::BAD_GATEWAY, format!("connection error: {}", e)) } }
}

async fn get_process_logs(State(state): State<Arc<AppState>>) -> impl IntoResponse {
    debug!("get_process_logs");
    let go_url = format!("{}/data/process-logs", GO_SERVER_BASE);
    let resp = state.http.get(&go_url).send().await;
    match resp { 
        Ok(r) => { let s=r.status(); let t=r.text().await.unwrap_or_default(); info!("get_process_logs: status={} bytes={}", s.as_u16(), t.len()); (s,t) }, 
        Err(e)=> { error!("get_process_logs error: {}", e); (axum::http::StatusCode::BAD_GATEWAY, format!("connection error: {}", e)) } }
}

async fn get_resources(State(state): State<Arc<AppState>>) -> impl IntoResponse {
    debug!("get_resources");
    let go_url = format!("{}/data/resources", GO_SERVER_BASE);
    let resp = state.http.get(&go_url).send().await;
    match resp { 
        Ok(r) => { let s=r.status(); let t=r.text().await.unwrap_or_default(); info!("get_resources: status={} bytes={}", s.as_u16(), t.len()); (s,t) }, 
        Err(e)=> { error!("get_resources error: {}", e); (axum::http::StatusCode::BAD_GATEWAY, format!("connection error: {}", e)) } }
}

async fn get_network(State(state): State<Arc<AppState>>) -> impl IntoResponse {
    debug!("get_network");
    let go_url = format!("{}/data/network", GO_SERVER_BASE);
    let resp = state.http.get(&go_url).send().await;
    match resp { 
        Ok(r) => { let s=r.status(); let t=r.text().await.unwrap_or_default(); info!("get_network: status={} bytes={}", s.as_u16(), t.len()); (s,t) }, 
        Err(e)=> { error!("get_network error: {}", e); (axum::http::StatusCode::BAD_GATEWAY, format!("connection error: {}", e)) } }
}

async fn get_processes(State(state): State<Arc<AppState>>) -> impl IntoResponse {
    debug!("get_processes");
    let go_url = format!("{}/data/processes", GO_SERVER_BASE);
    let resp = state.http.get(&go_url).send().await;
    match resp { 
        Ok(r) => { let s=r.status(); let t=r.text().await.unwrap_or_default(); info!("get_processes: status={} bytes={}", s.as_u16(), t.len()); (s,t) }, 
        Err(e)=> { error!("get_processes error: {}", e); (axum::http::StatusCode::BAD_GATEWAY, format!("connection error: {}", e)) } }
}

async fn get_ports(State(state): State<Arc<AppState>>) -> impl IntoResponse {
    debug!("get_ports");
    let go_url = format!("{}/data/ports", GO_SERVER_BASE);
    let resp = state.http.get(&go_url).send().await;
    match resp { 
        Ok(r) => { let s=r.status(); let t=r.text().await.unwrap_or_default(); info!("get_ports: status={} bytes={}", s.as_u16(), t.len()); (s,t) }, 
        Err(e)=> { error!("get_ports error: {}", e); (axum::http::StatusCode::BAD_GATEWAY, format!("connection error: {}", e)) } }
}

async fn save_session(State(state): State<Arc<AppState>>, Json(body): Json<SessionData>) -> impl IntoResponse {
    info!(
        "save_session: net={} cpu={} gpu={} host=\"{}\"",
        body.network_history.len(),
        body.cpu_history.len(),
        body.gpu_history.len(),
        body.current_host
    );
    match state.session_data.lock() {
        Ok(mut data) => {
            *data = body;
            Json(json!({"success": true}))
        }
        Err(_) => Json(json!({"success": false, "error": "Failed to lock session data"}))
    }
}

async fn restore_session(State(state): State<Arc<AppState>>) -> impl IntoResponse {
    debug!("restore_session");
    match state.session_data.lock() {
        Ok(data) => { 
            info!(
                "restore_session: net={} cpu={} gpu={} host=\"{}\"",
                data.network_history.len(),
                data.cpu_history.len(),
                data.gpu_history.len(),
                data.current_host
            );
            Json(json!({
            "success": true,
            "data": {
                "networkHistory": data.network_history,
                "cpuHistory": data.cpu_history,
                "gpuHistory": data.gpu_history,
                "currentHost": data.current_host
            }
        }))
        },
        Err(_) => { error!("restore_session lock error"); Json(json!({"success": false, "error": "Failed to lock session data"})) }
    }
}

async fn get_ssh_status(State(state): State<Arc<AppState>>) -> impl IntoResponse {
    debug!("get_ssh_status");
    let go_url = format!("{}/ssh/status", GO_SERVER_BASE);
    let resp = state.http.get(&go_url).send().await;
    match resp { 
        Ok(r) => { let s=r.status(); let t=r.text().await.unwrap_or_default(); info!("get_ssh_status: status={} bytes={}", s.as_u16(), t.len()); (s,t) }, 
        Err(e)=> { error!("get_ssh_status error: {}", e); (axum::http::StatusCode::BAD_GATEWAY, format!("connection error: {}", e)) } }
}

