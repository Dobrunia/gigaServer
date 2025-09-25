// Модуль для всех заданий
#[path = "routes/week2.rs"]
pub mod week2;
#[path = "routes/week3.rs"]
pub mod week3;
#[path = "routes/dashboard.rs"]
pub mod dashboard;

use axum::{Router, routing::get_service};
use tower_http::services::ServeFile;

// Функция для подключения всех роутов заданий
pub fn create_task_routes() -> Router {
    // Здесь будут добавляться новые модули заданий
    Router::new()
        .merge(dashboard::create_routes())
        .merge(week2::create_routes())
        .merge(week3::create_routes())
        .route_service("/dashboard", get_service(ServeFile::new("public/dashboard.html")))
}
