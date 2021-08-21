use prometheus::{self, Encoder, TextEncoder};
use std::convert::Infallible;
use tracing::{error, instrument};
use warp::Reply;

use crate::config::Config;
use crate::data::Data;
use crate::metrics::Registry;

#[derive(Debug)]
pub struct MetricsContext {
    config: Config,
    registry: Registry,
}

impl MetricsContext {
    pub fn new(config: Config) -> anyhow::Result<std::sync::Arc<MetricsContext>> {
        Ok(std::sync::Arc::new(MetricsContext {
            config,
            registry: Registry::new(prometheus::Opts::new("", ""))?,
        }))
    }
}

#[instrument]
pub async fn metrics(ctx: std::sync::Arc<MetricsContext>) -> Result<impl Reply, Infallible> {
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
