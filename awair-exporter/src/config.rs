use serde::Deserialize;

#[derive(Deserialize, Debug)]
pub struct Config {
    pub endpoints: Vec<Endpoint>,
}

#[derive(Deserialize, Debug)]
pub struct Endpoint {
    pub name: String,
    pub url: String,
}

// TODO: better error reporting
