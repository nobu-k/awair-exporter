use clap::{AppSettings, Clap};
use prometheus::{self, Encoder, TextEncoder};
use std::convert::Infallible;
use std::net::ToSocketAddrs;
use warp::{Filter, Reply};

const VERSION: &'static str = "0.1.0";

#[derive(Clap)]
#[clap(version = VERSION)]
#[clap(setting = AppSettings::ColoredHelp)]
struct Opts {
    #[clap(short = 'L', long, default_value = "localhost:19101")]
    listen_on: String,
}

#[tokio::main]
async fn main() {
    let opts = Opts::parse();
    let addr = match opts.listen_on.to_socket_addrs() {
        Ok(mut addr) => addr
            .next()
            .expect("no address information provided with --listen-on"),
        Err(err) => {
            panic!("parsing socket failed: {}", err);
        }
    };

    let metrics = warp::path!("metrics").and_then(metrics);
    let routes = warp::get().and(metrics);

    warp::serve(routes).run(addr).await;
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
