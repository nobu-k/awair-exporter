use serde::Deserialize;

#[derive(Deserialize, Debug)]
pub struct Config {
    endpoints: Vec<Endpoint>,
}

#[derive(Deserialize, Debug)]
pub struct Endpoint {
    name: String,
    url: String,
}

// TODO: better error reporting
