use anyhow::Context;
use clap::{AppSettings, Clap};

use std::net::ToSocketAddrs;
use tracing::info;
use warp::Filter;

mod config;
use config::Config;

mod log_level;
use log_level::LogLevel;

mod data;
mod endpoints;
mod metrics;

const VERSION: &'static str = "0.1.0";

#[derive(Clap)]
#[clap(version = VERSION)]
#[clap(setting = AppSettings::ColoredHelp)]
struct Opts {
    #[clap(short, long, default_value = "/etc/awair-exporter/config.yaml")]
    config: String,

    #[clap(short = 'L', long, default_value = "localhost:19101")]
    listen_on: String,

    #[clap(long, default_value = "info")]
    log_level: LogLevel,
}

#[tokio::main]
async fn main() -> anyhow::Result<()> {
    let opts = Opts::parse();

    let collector = tracing_subscriber::fmt()
        .json()
        .with_timer(tracing_subscriber::fmt::time::ChronoUtc::rfc3339())
        .with_max_level(opts.log_level.level())
        .finish();

    tracing::subscriber::set_global_default(collector)
        .with_context(|| "failed to set up the logger")?;

    let config = load_config(&opts.config)?;
    let ctx = endpoints::metrics::MetricsContext::new(config)?;

    let addr = opts
        .listen_on
        .to_socket_addrs()
        .with_context(|| "parsing --listen-on failed")?
        .next()
        .with_context(|| "no address information provided with --listen-on")?;

    let metrics = warp::path!("metrics").and_then(move || endpoints::metrics::metrics(ctx.clone()));
    let routes = warp::get().and(metrics).with(warp::log::custom(|i| {
        // TODO: due to the limitation of warp, request durations cannot be
        // measured by warp.
        info!(method = %i.method(), path = i.path(), status = i.status().as_u16(), "access");
    }));

    info!(%addr, "starting the server");
    warp::serve(routes).run(addr).await;
    Ok(())
}

fn load_config(path: &str) -> anyhow::Result<Config> {
    let f =
        std::fs::File::open(path).with_context(|| format!("failed to open the file: {}", path))?;
    let c = serde_yaml::from_reader(f)
        .with_context(|| format!("failed to read the config file {}", path))?;
    Ok(c)
}
