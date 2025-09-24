use axum::{
    http::{HeaderMap, StatusCode},
    response::{Html, IntoResponse, Response, Redirect},
    routing::get,
    Router,
};
use tracing::info;

pub fn create_routes() -> Router {
    Router::new()
        // редиректы без слэша -> со слэшем
        .route("/promise", get(promise_redirect))
        .route("/fetch", get(fetch_redirect))
        // целевые пути
        .route("/promise/", get(promise_handler))
        .route("/fetch/", get(fetch_handler))
}

fn with_cors_headers(mut headers: HeaderMap) -> HeaderMap {
    headers.insert("access-control-allow-origin", "*".parse().unwrap());
    headers
}

fn text_response(body: &str) -> Response {
    let mut headers = HeaderMap::new();
    headers.insert("content-type", "text/plain; charset=UTF-8".parse().unwrap());
    let headers = with_cors_headers(headers);
    (StatusCode::OK, headers, body.to_string()).into_response()
}

fn html_response(body: &str) -> Response {
    let mut headers = HeaderMap::new();
    headers.insert("content-type", "text/html; charset=UTF-8".parse().unwrap());
    let headers = with_cors_headers(headers);
    (StatusCode::OK, headers, body.to_string()).into_response()
}

async fn promise_redirect() -> Redirect { Redirect::permanent("/promise/") }
async fn fetch_redirect() -> Redirect { Redirect::permanent("/fetch/") }

async fn promise_handler() -> Response {
    info!("/promise/ called");
    // точный JS: function task(x){ return new Promise((res, rej)=> x < 18 ? res('yes') : rej('no')); }
    let js = "function task(x){ return new Promise((res, rej)=> x < 18 ? res('yes') : rej('no')); }";
    text_response(js)
}

async fn fetch_handler() -> Response {
    info!("/fetch/ called");
    let html = r#"<!doctype html><html><head><meta charset='utf-8'><title>Week3 Fetch</title></head>
<body>
  <input id="inp" />
  <button id="bt">Go</button>
  <script>
    const inp = document.getElementById('inp');
    const bt = document.getElementById('bt');
    bt.addEventListener('click', async () => {
      try {
        const url = inp.value;
        const resp = await fetch(url);
        const text = await resp.text();
        inp.value = text;
      } catch(e) {
        inp.value = String(e);
      }
    });
  </script>
</body></html>"#;
    html_response(html)
}
