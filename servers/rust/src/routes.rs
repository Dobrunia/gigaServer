// Модуль для всех заданий
#[path = "routes/week2.rs"]
pub mod week2;
#[path = "routes/week3.rs"]
pub mod week3;
#[path = "routes/dashboard.rs"]
pub mod dashboard;
#[path = "routes/navigation.rs"]
pub mod navigation;
#[path = "routes/ajax.rs"]
pub mod ajax;
#[path = "routes/snippets.rs"]
pub mod snippets;
#[path = "routes/network/network.rs"]
pub mod network;

use axum::{Router, routing::get_service};
use tower_http::services::ServeFile;

// Функция для подключения всех роутов заданий
pub fn create_task_routes() -> Router {
    // Здесь будут добавляться новые модули заданий
    Router::new()
        .merge(dashboard::create_routes())
        .merge(navigation::create_routes())
        .merge(ajax::create_routes())
        .merge(snippets::create_routes())
        .merge(network::create_routes())
        .merge(week2::create_routes())
        .merge(week3::create_routes())
        .route_service("/dashboard", get_service(ServeFile::new("public/dashboard.html")))
        .route_service("/navigation", get_service(ServeFile::new("public/navigation.html")))
        .route_service("/ajax", get_service(ServeFile::new("public/ajax.html")))
        .route_service("/snippets", get_service(ServeFile::new("public/snippets.html")))
        .route_service("/snippets.json", get_service(ServeFile::new("public/snippets.json")))
        .route_service("/network", get_service(ServeFile::new("public/network.html")))
}
