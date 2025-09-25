use axum::{routing::{get, post}, Router, response::IntoResponse, Json, extract::State};
use serde_json::json;
use serde::{Deserialize, Serialize};
use std::sync::{Arc, Mutex};
use reqwest::Client;

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
            (status, text)
        }
        Err(e) => {
            (axum::http::StatusCode::BAD_GATEWAY, format!("connection error: {}", e))
        }
    }
}

async fn ssh_disconnect(State(state): State<Arc<AppState>>) -> impl IntoResponse {
    let go_url = format!("{}/ssh/disconnect", GO_SERVER_BASE);
    let resp = state.http.post(&go_url).send().await;
    match resp {
        Ok(r) => {
            let status = r.status();
            let text = r.text().await.unwrap_or_else(|_| "".into());
            (status, text)
        }
        Err(e) => (axum::http::StatusCode::BAD_GATEWAY, format!("connection error: {}", e))
    }
}

async fn ssh_execute(State(state): State<Arc<AppState>>, Json(body): Json<SSHExecuteReq>) -> impl IntoResponse {
    let go_url = format!("{}/ssh/execute", GO_SERVER_BASE);
    let resp = state.http.post(&go_url).json(&json!({
        "command": body.command
    })).send().await;
    match resp {
        Ok(r) => {
            let status = r.status();
            let text = r.text().await.unwrap_or_else(|_| "".into());
            (status, text)
        }
        Err(e) => (axum::http::StatusCode::BAD_GATEWAY, format!("connection error: {}", e))
    }
}

async fn get_connections(State(state): State<Arc<AppState>>) -> impl IntoResponse {
    let go_url = format!("{}/data/connections", GO_SERVER_BASE);
    let resp = state.http.get(&go_url).send().await;
    match resp { Ok(r) => { let s=r.status(); let t=r.text().await.unwrap_or_default(); (s,t) }, Err(e)=> (axum::http::StatusCode::BAD_GATEWAY, format!("connection error: {}", e)) }
}

async fn get_client_ips(State(state): State<Arc<AppState>>) -> impl IntoResponse {
    let go_url = format!("{}/data/client-ips", GO_SERVER_BASE);
    let resp = state.http.get(&go_url).send().await;
    match resp { Ok(r) => { let s=r.status(); let t=r.text().await.unwrap_or_default(); (s,t) }, Err(e)=> (axum::http::StatusCode::BAD_GATEWAY, format!("connection error: {}", e)) }
}

async fn get_process_logs(State(state): State<Arc<AppState>>) -> impl IntoResponse {
    let go_url = format!("{}/data/process-logs", GO_SERVER_BASE);
    let resp = state.http.get(&go_url).send().await;
    match resp { Ok(r) => { let s=r.status(); let t=r.text().await.unwrap_or_default(); (s,t) }, Err(e)=> (axum::http::StatusCode::BAD_GATEWAY, format!("connection error: {}", e)) }
}

async fn get_resources(State(state): State<Arc<AppState>>) -> impl IntoResponse {
    let go_url = format!("{}/data/resources", GO_SERVER_BASE);
    let resp = state.http.get(&go_url).send().await;
    match resp { Ok(r) => { let s=r.status(); let t=r.text().await.unwrap_or_default(); (s,t) }, Err(e)=> (axum::http::StatusCode::BAD_GATEWAY, format!("connection error: {}", e)) }
}

async fn get_network(State(state): State<Arc<AppState>>) -> impl IntoResponse {
    let go_url = format!("{}/data/network", GO_SERVER_BASE);
    let resp = state.http.get(&go_url).send().await;
    match resp { Ok(r) => { let s=r.status(); let t=r.text().await.unwrap_or_default(); (s,t) }, Err(e)=> (axum::http::StatusCode::BAD_GATEWAY, format!("connection error: {}", e)) }
}

async fn get_processes(State(state): State<Arc<AppState>>) -> impl IntoResponse {
    let go_url = format!("{}/data/processes", GO_SERVER_BASE);
    let resp = state.http.get(&go_url).send().await;
    match resp { Ok(r) => { let s=r.status(); let t=r.text().await.unwrap_or_default(); (s,t) }, Err(e)=> (axum::http::StatusCode::BAD_GATEWAY, format!("connection error: {}", e)) }
}

async fn get_ports(State(state): State<Arc<AppState>>) -> impl IntoResponse {
    let go_url = format!("{}/data/ports", GO_SERVER_BASE);
    let resp = state.http.get(&go_url).send().await;
    match resp { Ok(r) => { let s=r.status(); let t=r.text().await.unwrap_or_default(); (s,t) }, Err(e)=> (axum::http::StatusCode::BAD_GATEWAY, format!("connection error: {}", e)) }
}

async fn save_session(State(state): State<Arc<AppState>>, Json(body): Json<SessionData>) -> impl IntoResponse {
    match state.session_data.lock() {
        Ok(mut data) => {
            *data = body;
            Json(json!({"success": true}))
        }
        Err(_) => Json(json!({"success": false, "error": "Failed to lock session data"}))
    }
}

async fn restore_session(State(state): State<Arc<AppState>>) -> impl IntoResponse {
    match state.session_data.lock() {
        Ok(data) => Json(json!({
            "success": true,
            "data": {
                "networkHistory": data.network_history,
                "cpuHistory": data.cpu_history,
                "gpuHistory": data.gpu_history,
                "currentHost": data.current_host
            }
        })),
        Err(_) => Json(json!({"success": false, "error": "Failed to lock session data"}))
    }
}

async fn get_ssh_status(State(state): State<Arc<AppState>>) -> impl IntoResponse {
    let go_url = format!("{}/ssh/status", GO_SERVER_BASE);
    let resp = state.http.get(&go_url).send().await;
    match resp { Ok(r) => { let s=r.status(); let t=r.text().await.unwrap_or_default(); (s,t) }, Err(e)=> (axum::http::StatusCode::BAD_GATEWAY, format!("connection error: {}", e)) }
}

