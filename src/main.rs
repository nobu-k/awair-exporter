use prometheus::{self, Encoder, TextEncoder};
use std::convert::Infallible;
use warp::{Filter, Reply};

#[tokio::main]
async fn main() {
    let metrics = warp::path!("metrics").and_then(metrics);
    let routes = warp::get().and(metrics);

    warp::serve(routes).run(([127, 0, 0, 1], 3030)).await;
}

async fn metrics() -> Result<impl Reply, Infallible> {
    let mut buffer = Vec::new();
    let encoder = TextEncoder::new();
    let metric_families = prometheus::gather();
    if encoder.encode(&metric_families, &mut buffer).is_err() {
        return Ok(warp::http::Response::builder()
            .status(warp::http::StatusCode::INTERNAL_SERVER_ERROR)
            .body("Something went wrong".to_owned()));
    }

    Ok(warp::http::Response::builder()
        .header("Content-Type", "text/plain; version=0.0.4")
        .body(String::from_utf8(buffer).unwrap()))
}
