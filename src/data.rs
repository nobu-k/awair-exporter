use serde::Deserialize;

#[derive(Deserialize, Debug)]
pub struct Data {
    pub score: i32,
    pub dew_point: f64,
    pub temp: f64,
    pub humid: f64,
    pub abs_humid: f64,
    pub co2: f64,

    pub co2_est: f64,
    pub co2_est_baseline: f64,

    /// Total Volatile Organic Compounds (ppm)
    pub voc: f64,

    pub voc_baseline: f64,
    pub voc_h2_raw: f64,
    pub voc_ethanol_raw: f64,

    pub pm25: f64,

    pub pm10_est: f64,
}

// TODO: add method to register prometheus metrics
