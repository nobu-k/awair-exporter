use prometheus::{self, Encoder, TextEncoder};
use warp::Filter;

#[tokio::main]
async fn main() {
    let metrics = warp::path!("metrics").map(metrics);
    let routes = warp::get().and(metrics);

    warp::serve(routes).run(([127, 0, 0, 1], 3030)).await;
}

fn metrics() -> String {
    let mut buffer = Vec::new();
    let encoder = TextEncoder::new();
    let metric_families = prometheus::gather();
    encoder.encode(&metric_families, &mut buffer).unwrap(); // TODO: error handling

    String::from_utf8(buffer).unwrap()
}
