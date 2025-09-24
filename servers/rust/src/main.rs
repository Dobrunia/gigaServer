use axum::{response::Html, Router};
use std::net::SocketAddr;
use tower::ServiceBuilder;
use tower_http::trace::TraceLayer;
use tracing::{info, Level};

mod routes;

async fn handler() -> Html<&'static str> {
    info!("Default handler called - returning Dobrunia's Rust server");
    Html("Dobrunia's Rust server")
}

#[tokio::main]
async fn main() {
    // Инициализация логирования
    tracing_subscriber::fmt()
        .with_max_level(Level::INFO)
        .init();

    let app = Router::new()
        .merge(routes::create_task_routes())  // Подключаем роуты заданий
        .fallback(handler)
        .layer(
            ServiceBuilder::new()
                .layer(TraceLayer::new_for_http())
        );

    let addr = SocketAddr::from(([127, 0, 0, 1], 3001));
    info!("🚀 Starting Dobrunia's Rust server on http://{}", addr);

    let listener = tokio::net::TcpListener::bind(addr).await.unwrap();
    info!("✅ Server successfully started and listening...");
    
    axum::serve(listener, app).await.unwrap();
}
