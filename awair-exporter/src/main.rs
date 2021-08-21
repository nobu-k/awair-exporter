use anyhow::Context;
use clap::{AppSettings, Clap};
use prometheus::{self, Encoder, TextEncoder};
use std::convert::Infallible;
use std::net::ToSocketAddrs;
use tracing::{error, info, instrument};
use warp::{Filter, Reply};

mod config;
use config::Config;

mod data;
use data::Data;

mod metrics;
use metrics::Registry;

const VERSION: &'static str = "0.1.0";

#[derive(Clap)]
#[clap(version = VERSION)]
#[clap(setting = AppSettings::ColoredHelp)]
struct Opts {
    #[clap(short, long, default_value = "/etc/awair-exporter/config.yaml")]
    config: String,

    #[clap(short = 'L', long, default_value = "localhost:19101")]
    listen_on: String,
}

#[derive(Debug)]
struct MetricsContext {
    config: Config,
    registry: Registry,
}

#[tokio::main]
async fn main() -> anyhow::Result<()> {
    let collector = tracing_subscriber::fmt()
        .json()
        .with_timer(tracing_subscriber::fmt::time::ChronoUtc::rfc3339())
        .finish();

    tracing::subscriber::set_global_default(collector)
        .with_context(|| "failed to set up the logger")?;

    let opts = Opts::parse();
    let config = load_config(&opts.config)?;
    let ctx = std::sync::Arc::new(MetricsContext {
        config,
        registry: Registry::new(prometheus::Opts::new("", ""))?,
    });

    let addr = opts
        .listen_on
        .to_socket_addrs()
        .with_context(|| "parsing --listen-on failed")?
        .next()
        .with_context(|| "no address information provided with --listen-on")?;

    let metrics = warp::path!("metrics").and_then(move || metrics(ctx.clone()));
    let routes = warp::get().and(metrics).with(warp::log::custom(|i| {
        // TODO: due to the limitation of warp, request durations cannot be
        // measured by warp.
        info!(method = %i.method(), path = i.path(), status = i.status().as_u16(), "access");
    }));

    info!(%addr, "starting the server");
    warp::serve(routes).run(addr).await;
    Ok(())
}

#[instrument]
async fn metrics(ctx: std::sync::Arc<MetricsContext>) -> Result<impl Reply, Infallible> {
    let mut buffer = Vec::new();
    let encoder = TextEncoder::new();
    let metric_families = prometheus::gather();
    if let Err(error) = encoder.encode(&metric_families, &mut buffer) {
        error!(%error, "failed to encode metrics");
        return Ok(warp::http::Response::builder()
            .status(warp::http::StatusCode::INTERNAL_SERVER_ERROR)
            .body("Something went wrong".to_owned()));
    }

    // TODO: concurrent request
    let ctx = ctx.as_ref();
    for endpoint in &ctx.config.endpoints {
        match reqwest::get(&endpoint.url).await {
            Ok(res) => {
                let body: Data = res.json().await.unwrap(); // TODO: error handling
                ctx.registry.scrape(&endpoint.name, &body);
            }
            Err(error) => {
                error!(%error, url = %&endpoint.url, "failed to get raw data");
            }
        }
    }
    if let Err(error) = encoder.encode(&ctx.registry.gather(), &mut buffer) {
        error!(%error, "failed to encode awair metrics");
        return Ok(warp::http::Response::builder()
            .status(warp::http::StatusCode::INTERNAL_SERVER_ERROR)
            .body("Something went wrong".to_owned()));
    }

    Ok(warp::http::Response::builder()
        .header("Content-Type", "text/plain; version=0.0.4")
        .body(String::from_utf8(buffer).unwrap()))
}

fn load_config(path: &str) -> anyhow::Result<Config> {
    let f =
        std::fs::File::open(path).with_context(|| format!("failed to open the file: {}", path))?;
    let c = serde_yaml::from_reader(f)
        .with_context(|| format!("failed to read the config file {}", path))?;
    Ok(c)
}
