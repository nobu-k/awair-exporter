use warp::Filter;

#[tokio::main]
async fn main() {
    let metrics = warp::path!("metrics").map(metrics);
    let routes = warp::get().and(metrics);

    warp::serve(routes).run(([127, 0, 0, 1], 3030)).await;
}

fn metrics() -> String {
    "test".to_owned()
}
