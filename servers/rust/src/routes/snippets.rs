use axum::{Router, routing::{get, post}, Json};
use serde::{Deserialize, Serialize};
use serde_json::json;
use std::{fs, path::Path, io};

const SNIPPETS_PATH: &str = "public/snippets.json";

#[derive(Serialize, Deserialize, Clone)]
struct Snippet {
    id: i64,
    name: String,
    language: String,
    code: String,
}

#[derive(Serialize, Deserialize)]
struct SnippetPayload {
    id: Option<i64>,
    name: String,
    language: String,
    code: String,
}

pub fn create_routes() -> Router {
    Router::new()
        .route("/rust/snippets/list", get(list))
        .route("/rust/snippets/save", post(save))
        .route("/rust/snippets/delete", post(delete_snippet))
}

fn read_snippets() -> io::Result<Vec<Snippet>> {
    if !Path::new(SNIPPETS_PATH).exists() {
        return Ok(vec![]);
    }
    let data = fs::read_to_string(SNIPPETS_PATH)?;
    let parsed: Vec<Snippet> = serde_json::from_str(&data).unwrap_or_default();
    Ok(parsed)
}

fn write_snippets(all: &[Snippet]) -> io::Result<()> {
    let text = serde_json::to_string_pretty(all).unwrap_or("[]".into());
    fs::write(SNIPPETS_PATH, text)
}

async fn list() -> Json<serde_json::Value> {
    match read_snippets() {
        Ok(v) => Json(json!({"snippets": v})),
        Err(e) => Json(json!({"snippets": [], "error": e.to_string()})),
    }
}

async fn save(Json(payload): Json<SnippetPayload>) -> Json<serde_json::Value> {
    let mut all = read_snippets().unwrap_or_default();
    let id = payload.id.unwrap_or_else(|| chrono::Utc::now().timestamp_millis());

    if let Some(existing) = all.iter_mut().find(|s| s.id == id) {
        existing.name = payload.name;
        existing.language = payload.language;
        existing.code = payload.code;
    } else {
        all.insert(0, Snippet { id, name: payload.name, language: payload.language, code: payload.code });
    }

    if let Err(e) = write_snippets(&all) {
        return Json(json!({"ok": false, "error": e.to_string()}));
    }
    Json(json!({"ok": true, "id": id}))
}

#[derive(Deserialize)]
struct DeletePayload { id: i64 }

async fn delete_snippet(Json(payload): Json<DeletePayload>) -> Json<serde_json::Value> {
    let mut all = read_snippets().unwrap_or_default();
    let before = all.len();
    all.retain(|s| s.id != payload.id);
    if all.len() == before {
        return Json(json!({"ok": false, "error": "not found"}));
    }
    if let Err(e) = write_snippets(&all) {
        return Json(json!({"ok": false, "error": e.to_string()}));
    }
    Json(json!({"ok": true}))
}


