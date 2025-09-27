use axum::{http::StatusCode, response::Json, extract::Query};
use serde_json::{json, Value};
use serde::Deserialize;
use std::collections::HashMap;
use super::discovery::{NetworkDevice, discover_devices};
// (no extra imports)

pub async fn get_device_summary() -> Result<Json<Value>, StatusCode> {
    let devices_result = discover_devices().await?;
    let devices: Vec<NetworkDevice> = serde_json::from_value(devices_result.0["devices"].clone())
        .unwrap_or_default();
    
    let total = devices.len();
    let online = devices.iter().filter(|d| d.status == "online").count();
    let investigate = devices.iter().filter(|d| d.tags.contains(&"investigate".to_string())).count();
    
    // Group by device type
    let mut type_counts = HashMap::new();
    for device in &devices {
        *type_counts.entry(device.device_type.clone()).or_insert(0) += 1;
    }
    
    // Group by vendor
    let mut vendor_counts = HashMap::new();
    for device in &devices {
        *vendor_counts.entry(device.vendor.clone()).or_insert(0) += 1;
    }
    
    Ok(Json(json!({
        "summary": {
            "total_devices": total,
            "online_devices": online,
            "offline_devices": total - online,
            "investigate_devices": investigate
        },
        "by_type": type_counts,
        "by_vendor": vendor_counts,
        "recent_devices": devices.iter().take(5).collect::<Vec<_>>()
    })))
}

pub async fn get_topology() -> Result<Json<Value>, StatusCode> {
    // Always build topology from fresh discovery data
    let discover = discover_devices().await?;
    let mut devices: Vec<NetworkDevice> = serde_json::from_value(discover.0["devices"].clone()).unwrap_or_default();

    // Group by subnet /24
    let mut subnets: std::collections::BTreeMap<String, Vec<&NetworkDevice>> = std::collections::BTreeMap::new();
    for d in &devices {
        let parts: Vec<&str> = d.ip.split('.').collect();
        let key = if parts.len()==4 { format!("{}.{}.{}", parts[0],parts[1],parts[2]) } else { "other".to_string() };
        subnets.entry(key).or_default().push(d);
    }

    // AP/Router guess: devices typed Router or with gateway-looking IP (.1)
    let mut nodes = vec![];
    let mut links = vec![];
    let mut id = 0u32;

    let mut node_id: std::collections::HashMap<String,u32> = std::collections::HashMap::new();
    for (subnet, group) in subnets {
        // Create subnet node
        let subnet_node = json!({"id": id, "type": "subnet", "name": format!("{}.0/24", subnet)});
        node_id.insert(format!("subnet:{}", subnet), id); nodes.push(subnet_node); id+=1;

        // Router/AP candidate
        let mut router_idx: Option<u32> = None;
        for d in &group {
            let is_router = d.device_type.to_lowercase().contains("router") || d.ip.ends_with(".1");
            if is_router {
                let rid = id; node_id.insert(format!("dev:{}", d.ip), rid);
                nodes.push(json!({"id": rid, "type":"router", "name": if d.hostname.is_empty(){ d.ip.clone() } else { d.hostname.clone() }, "ip": d.ip, "vendor": d.vendor, "status": d.status})); id+=1; router_idx=Some(rid); break;
            }
        }
        // If no router detected, create virtual router node
        let r = router_idx.unwrap_or_else(|| { let rid=id; nodes.push(json!({"id": rid, "type":"router", "name": format!("{}.1", subnet)})); id+=1; rid });

        // Link subnet to router
        links.push(json!({"source": node_id[&format!("subnet:{}", subnet)], "target": r}));

        // Add clients
        for d in &group {
            let did = *node_id.entry(format!("dev:{}", d.ip)).or_insert_with(|| { let nid=id; nodes.push(json!({"id": nid, "type":"client", "name": if d.hostname.is_empty(){d.ip.clone()} else {d.hostname.clone()}, "ip": d.ip, "vendor": d.vendor, "status": d.status, "os": d.os })); id+=1; nid });
            links.push(json!({"source": r, "target": did}));
        }
    }

    Ok(Json(json!({"nodes": nodes, "links": links})))
}
pub async fn get_filtered_devices(Query(params): Query<DeviceFilter>) -> Result<Json<Value>, StatusCode> {
    let devices_result = discover_devices().await?;
    let mut devices: Vec<NetworkDevice> = serde_json::from_value(devices_result.0["devices"].clone())
        .unwrap_or_default();
    
    // Apply filters
    if let Some(device_type) = &params.device_type {
        devices.retain(|d| d.device_type.to_lowercase().contains(&device_type.to_lowercase()));
    }
    
    if let Some(vendor) = &params.vendor {
        devices.retain(|d| d.vendor.to_lowercase().contains(&vendor.to_lowercase()));
    }
    
    if let Some(status) = &params.status {
        devices.retain(|d| d.status == *status);
    }
    
    if let Some(tag) = &params.tag {
        devices.retain(|d| d.tags.contains(tag));
    }
    
    if let Some(search) = &params.search {
        let search_lower = search.to_lowercase();
        devices.retain(|d| {
            d.hostname.to_lowercase().contains(&search_lower) ||
            d.ip.contains(&search_lower) ||
            d.mac.to_lowercase().contains(&search_lower) ||
            d.vendor.to_lowercase().contains(&search_lower)
        });
    }
    
    // Sort by last seen (most recent first)
    devices.sort_by(|a, b| b.last_seen.cmp(&a.last_seen));
    
    // Pagination
    let page = params.page.unwrap_or(1);
    let per_page = params.per_page.unwrap_or(20).min(100); // Max 100 per page
    let start = ((page - 1) * per_page) as usize;
    let end = (start + per_page as usize).min(devices.len());
    
    let paginated_devices = if start < devices.len() {
        devices[start..end].to_vec()
    } else {
        vec![]
    };
    
    Ok(Json(json!({
        "devices": paginated_devices,
        "pagination": {
            "page": page,
            "per_page": per_page,
            "total": devices.len(),
            "total_pages": (devices.len() as f64 / per_page as f64).ceil() as u32
        }
    })))
}

#[derive(Deserialize)]
pub struct DeviceFilter {
    pub device_type: Option<String>,
    pub vendor: Option<String>,
    pub status: Option<String>, // online, offline
    pub tag: Option<String>,    // trusted, blocked, investigate
    pub search: Option<String>,
    pub page: Option<u32>,
    pub per_page: Option<u32>,
}