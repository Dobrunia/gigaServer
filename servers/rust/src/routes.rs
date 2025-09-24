// Модуль для всех заданий
#[path = "routes/week2.rs"]
pub mod week2;

use axum::Router;

// Функция для подключения всех роутов заданий
pub fn create_task_routes() -> Router {
    // Здесь будут добавляться новые модули заданий
    Router::new()
        .merge(week2::create_routes())
        // .merge(week3::create_routes())
        // .merge(week4::create_routes())
}
