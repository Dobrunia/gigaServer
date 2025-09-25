use axum::{Router, routing::post, extract::State, Json, response::IntoResponse};
use serde::{Deserialize, Serialize};
use serde_json::json;
use std::sync::Arc;
use std::time::Instant;
use reqwest::{Client, Method};
use tracing::{info, debug, error};

#[derive(Clone)]
struct AjaxState { http: Client }

#[derive(Deserialize)]
struct ProxyReq {
    method: String,
    url: String,
    headers: Option<serde_json::Value>,
    body: Option<serde_json::Value>,
}

#[derive(Serialize)]
struct ProxyResp {
    status: u16,
    headers: serde_json::Value,
    body_text: String,
}

pub fn create_routes() -> Router {
    Router::new()
        .route("/rust/ajax/proxy", post(proxy))
        .with_state(Arc::new(AjaxState { http: Client::new() }))
}

async fn proxy(State(state): State<Arc<AjaxState>>, Json(req): Json<ProxyReq>) -> impl IntoResponse {
    // Basic validation
    if req.url.is_empty() { return Json(json!({"error":"url required"})); }

    let started = Instant::now();
    let hdrs_count = req.headers.as_ref().and_then(|v| v.as_object()).map(|o| o.len()).unwrap_or(0);
    let body_bytes = req.body.as_ref().map(|b| b.to_string().len()).unwrap_or(0);
    info!("ajax_proxy request: method={} url={} headers={} body_bytes={}", req.method, req.url, hdrs_count, body_bytes);

    let method = req.method.parse::<Method>().unwrap_or(Method::GET);
    let mut builder = state.http.request(method, &req.url);

    if let Some(hs) = req.headers.as_ref().and_then(|v| v.as_object()) {
        for (k, v) in hs.iter() {
            if let Some(s) = v.as_str() { builder = builder.header(k, s); }
        }
    }

    if let Some(body) = req.body {
        // Pass through JSON bodies as text to avoid content-type surprises
        builder = builder.body(body.to_string());
    }

    let res = match builder.send().await {
        Ok(r) => r,
        Err(e) => {
            error!("ajax_proxy error sending request: {}", e);
            return Json(json!({"error": format!("request error: {}", e)}));
        },
    };

    let status = res.status().as_u16();
    let mut headers_obj = serde_json::Map::new();
    for (k, v) in res.headers().iter() {
        headers_obj.insert(k.to_string(), json!(v.to_str().unwrap_or("")));
    }
    let body_text = res.text().await.unwrap_or_default();
    let elapsed_ms = started.elapsed().as_millis();
    debug!("ajax_proxy response: status={} bytes={} headers={} in {}ms", status, body_text.len(), headers_obj.len(), elapsed_ms);

    Json(json!({
        "status": status,
        "headers": serde_json::Value::Object(headers_obj),
        "body_text": body_text
    }))
}


