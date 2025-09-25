use axum::{Router, routing::get, response::IntoResponse, Json};
use serde_json::json;

pub fn create_routes() -> Router {
    Router::new()
        .route("/rust/navigation/routes", get(list_routes))
}

async fn list_routes() -> impl IntoResponse {
    // Пока только дашборд
    Json(json!({
        "routes": [
            { "name": "Dashboard", "path": "/dashboard", "desc": "Server monitoring dashboard" },
            { "name": "Ajax Mini", "path": "/ajax", "desc": "Minimal Postman-like client" }
        ]
    }))
}
