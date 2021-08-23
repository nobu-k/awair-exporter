use futures::{stream, StreamExt};
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
    client: reqwest::Client,
}

impl MetricsContext {
    pub fn new(config: Config) -> anyhow::Result<std::sync::Arc<MetricsContext>> {
        Ok(std::sync::Arc::new(MetricsContext {
            config,
            registry: Registry::new(prometheus::Opts::new("", ""))?,
            client: reqwest::Client::new(),
        }))
    }
}

#[instrument(skip(ctx))]
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

    let ctx = ctx.as_ref();
    stream::iter(ctx.config.endpoints.clone())
        .map(|endpoint| async move {
            match ctx.client.get(&endpoint.url).send().await {
                Ok(res) => match res.json::<Data>().await {
                    Ok(data) => Ok((endpoint.name, data)),
                    Err(error) => {
                        error!(%error, url = %&endpoint.url, "failed to unmarshal raw data JSON");
                        ctx.registry.failed(&endpoint.name);
                        Err(error)
                    }
                },
                Err(error) => {
                    error!(%error, url = %&endpoint.url, "failed to get raw data");
                    ctx.registry.failed(&endpoint.name);
                    Err(error)
                }
            }
        })
        .buffer_unordered(4) // TODO: customizable
        .for_each(|b| async {
            match b {
                Ok((name, body)) => ctx.registry.scrape(&name, &body),
                _ => {}
            }
        })
        .await;

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
