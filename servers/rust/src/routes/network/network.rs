use axum::{
    http::StatusCode,
    response::Json,
    routing::get,
    Router,
};
use serde_json::{json, Value};

pub mod overview;
pub mod devices;

pub fn create_routes() -> Router {
    Router::new()
        .route("/network/overview", get(get_network_overview))
        .route("/network/wifi-status", get(overview::wifi::get_wifi_status))
        .route("/network/throughput", get(overview::throughput::get_throughput))
        .route("/network/nearby-aps", get(overview::nearby_aps::get_nearby_aps))
        .route("/network/devices/discover", get(devices::discovery::discover_devices))
        .route("/network/devices/inventory", get(devices::discovery::get_device_inventory))
        .route("/network/devices/summary", get(devices::inventory::get_device_summary))
        .route("/network/devices/filtered", get(devices::inventory::get_filtered_devices))
        .route("/network/map", get(devices::inventory::get_topology))
}

async fn get_network_overview() -> Result<Json<Value>, StatusCode> {
    // Get data from other modules; on error, return empty/null values
    let wifi_status = overview::wifi::get_wifi_status().await.unwrap_or_else(|_| {
        Json(json!({}))
    });    
    
    let throughput_data = overview::throughput::get_throughput().await.unwrap_or_else(|_| {
        Json(json!({
            "current_download": 0.0,
            "current_upload": 0.0,
            "avg_rtt": 0.0,
            "packet_loss": 0.0
        }))
    });
    
    let nearby_aps_data = overview::nearby_aps::get_nearby_aps().await.unwrap_or_else(|_| {
        Json(json!({ "nearby_aps": [] }))
    });
    
    let overview = json!({
        "wifi_status": wifi_status.0,
        "clients": {
            "throughput": {
                "download": throughput_data.0.get("current_download").cloned().unwrap_or(json!(0.0)),
                "upload": throughput_data.0.get("current_upload").cloned().unwrap_or(json!(0.0))
            },
            "avg_rtt": throughput_data.0.get("avg_rtt").cloned().unwrap_or(json!(0.0)),
            "packet_loss": throughput_data.0.get("packet_loss").cloned().unwrap_or(json!(0.0))
        },
        "nearby_aps": nearby_aps_data.0["nearby_aps"]
    });

    Ok(Json(overview))
}

