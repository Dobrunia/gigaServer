use axum::{
    http::{HeaderMap, StatusCode},
    response::{Response, IntoResponse, Redirect},
    routing::get,
    Router,
};
use tracing::info;

// Создаем роуты для week2 заданий
pub fn create_routes() -> Router {
    Router::new()
        // редиректы с путей без слэша
        .route("/login", get(login_redirect))
        .route("/sample", get(sample_redirect))
        // целевые пути со слэшем
        .route("/login/", get(login_handler))
        .route("/sample/", get(sample_handler))
}

// Функция для создания ответа с нужными заголовками
pub fn create_text_response(content: &str) -> Response {
    info!("Sending response: {}", content);
    
    let mut headers = HeaderMap::new();
    headers.insert("content-type", "text/plain; charset=UTF-8".parse().unwrap());
    headers.insert("access-control-allow-origin", "*".parse().unwrap());
    
    (StatusCode::OK, headers, content.to_string()).into_response()
}

// Редиректы на пути со слэшем
async fn login_redirect() -> Redirect { Redirect::permanent("/login/") }
async fn sample_redirect() -> Redirect { Redirect::permanent("/sample/") }

// Хэндлеры для заданий week2
async fn login_handler() -> Response {
    info!("Login handler called");
    create_text_response("dbe14467-cf9f-4f6d-844e-35d284ae4d2d")
}

async fn sample_handler() -> Response {
    info!("Sample handler called");
    let code = "function task(x){ return x * (this ** 2); }";
    create_text_response(code)
}
