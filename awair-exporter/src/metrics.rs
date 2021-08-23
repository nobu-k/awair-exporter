use crate::data::Data;
use prometheus::{core::Collector, proto::MetricFamily, CounterVec, GaugeVec, Opts};

#[derive(Debug)]
pub struct Registry {
    r: prometheus::Registry,
    m: Metrics,
}

impl Registry {
    pub fn new(opts: Opts) -> anyhow::Result<Self> {
        let r = prometheus::Registry::new();
        let m = Metrics::new(&r, opts)?;
        Ok(Self { r, m })
    }

    pub fn scrape(&self, instance: &str, data: &Data) {
        self.m.scrape(instance, data);
    }

    pub fn failed(&self, instance: &str) {
        self.m.failed(instance);
    }

    pub fn gather(&self) -> Vec<MetricFamily> {
        self.r.gather()
    }
}

#[derive(Debug)]
struct Metrics {
    score: GaugeVec,
    dew_point: GaugeVec,
    temp: GaugeVec,
    humid: GaugeVec,
    abs_humid: GaugeVec,
    co2: GaugeVec,
    co2_est: GaugeVec,
    co2_est_baseline: GaugeVec,
    voc: GaugeVec,
    voc_baseline: GaugeVec,
    voc_h2_raw: GaugeVec,
    voc_ethanol_raw: GaugeVec,
    pm25: GaugeVec,
    pm10_est: GaugeVec,
    scraped: CounterVec,
    failed: CounterVec,
}

impl Metrics {
    fn new(r: &prometheus::Registry, opts: Opts) -> anyhow::Result<Self> {
        Ok(Self {
            score: gauge(r, &opts, "awair_score", "Awair Score (0-100)")?,
            dew_point: gauge(r, &opts, "awair_dew_point_celsius", "The temperature at which water will condense and form into dew")?,
            temp: gauge(r, &opts, "awair_temperature_celcius", "Dry bulb temperature")?,
            humid: gauge(r, &opts, "awair_humidity_ratio", "Relative Humidity")?,
            abs_humid: gauge(r, &opts, "awair_absolute_humidity", "Absolute humidity g/m^3")?,
            co2: gauge(r, &opts, "awair_co2_ppm", "Carbon Dioxide ppm")?,
            co2_est: gauge(r, &opts, "awair_co2_est", "Estimated Carbon Dioxide (ppm - calculated by the TVOC sensor)")?,
            co2_est_baseline: gauge(r, &opts, "awair_co2_est_baseline", "A unitless value that represents the baseline from which the TVOC sensor partially derives its estimated (e)CO2output.")?,
            voc: gauge(r, &opts, "awair_voc_ppb", "Total Volatile Organic Compounds")?,
            voc_baseline: gauge(r, &opts, "awair_voc_baseline", "A unitless value that represents the baseline from which the TVOC sensor partially derives its TVOC output")?,
            voc_h2_raw: gauge(r, &opts, "awair_voc_h2_raw", "A unitless value that represents the Hydrogen gas signal from which the TVOC sensor partially derives its TVOC output")?,
            voc_ethanol_raw: gauge(r, &opts, "awair_voc_ethanol_raw", "A unitless value that represents the Ethanol gas signal from which the TVOC sensor partially derives its TVOC output")?,
            pm25: gauge(r, &opts, "awair_pm25", "Particulate matter less than 2.5 microns in diameter (µg/m^3)")?,
            pm10_est: gauge(r, &opts, "awair_pm25_est", "Estimated particulate matter less than 10 microns in diameter (µg/m^3 - calculated by the PM2.5 sensor)")?,
            scraped: counter(r, &opts, "awair_scraped_total", "The number of times the Awair has been scraped so far")?,
            failed: counter(r, &opts, "awair_scrape_failed_total", "The number of times requests to Awair failed so far")?,
        })
    }

    fn scrape(&self, instance: &str, data: &Data) {
        let labels = [instance];
        self.score.with_label_values(&labels).set(data.score as f64);
        self.dew_point
            .with_label_values(&labels)
            .set(data.dew_point);
        self.temp.with_label_values(&labels).set(data.temp);
        self.humid.with_label_values(&labels).set(data.humid);
        self.abs_humid
            .with_label_values(&labels)
            .set(data.abs_humid);
        self.co2.with_label_values(&labels).set(data.co2);
        self.co2_est.with_label_values(&labels).set(data.co2_est);
        self.co2_est_baseline
            .with_label_values(&labels)
            .set(data.co2_est_baseline);
        self.voc.with_label_values(&labels).set(data.voc);
        self.voc_baseline
            .with_label_values(&labels)
            .set(data.voc_baseline);
        self.voc_h2_raw
            .with_label_values(&labels)
            .set(data.voc_h2_raw);
        self.voc_ethanol_raw
            .with_label_values(&labels)
            .set(data.voc_ethanol_raw);
        self.pm25.with_label_values(&labels).set(data.pm25);
        self.pm10_est.with_label_values(&labels).set(data.pm10_est);
        self.scraped.with_label_values(&labels).inc();
    }

    fn failed(&self, instance: &str) {
        self.failed.with_label_values(&[instance]).inc();
    }
}

fn gauge(
    r: &prometheus::Registry,
    opts: &Opts,
    name: &str,
    help: &str,
) -> anyhow::Result<GaugeVec> {
    metric(&GaugeVec::new, r, opts, name, help)
}

fn counter(
    r: &prometheus::Registry,
    opts: &Opts,
    name: &str,
    help: &str,
) -> anyhow::Result<CounterVec> {
    metric(&CounterVec::new, r, opts, name, help)
}

static VARIABLE_LABELS: [&'static str; 1] = ["instance"];

fn metric<T: 'static + Clone + Collector>(
    new: &dyn Fn(Opts, &[&str]) -> prometheus::Result<T>,
    r: &prometheus::Registry,
    opts: &Opts,
    name: &str,
    help: &str,
) -> anyhow::Result<T> {
    let mut opts = opts.clone();
    opts.name = name.to_owned();
    opts.help = help.to_owned();

    let m = new(opts, &VARIABLE_LABELS)?;
    r.register(Box::new(m.clone()))?;
    Ok(m)
}
