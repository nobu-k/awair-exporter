#[derive(Debug, PartialEq, Eq)]
pub enum LogLevel {
    Trace,
    Debug,
    Info,
    Warn,
    Error,
}

impl LogLevel {
    pub fn level(&self) -> tracing::Level {
        use LogLevel::*;
        match self {
            Trace => tracing::Level::TRACE,
            Debug => tracing::Level::DEBUG,
            Info => tracing::Level::INFO,
            Warn => tracing::Level::WARN,
            Error => tracing::Level::ERROR,
        }
    }
}

impl std::str::FromStr for LogLevel {
    type Err = anyhow::Error;

    fn from_str(s: &str) -> Result<Self, Self::Err> {
        use LogLevel::*;
        match s {
            "trace" => Ok(Trace),
            "debug" => Ok(Debug),
            "info" => Ok(Info),
            "warn" => Ok(Warn),
            "error" => Ok(Error),
            _ => Err(anyhow::format_err!("unsupported log level: {}", s)),
        }
    }
}

#[cfg(test)]
mod tests {
    use std::str::FromStr;

    use super::*;

    #[test]
    fn trace() {
        let l = LogLevel::from_str("trace").unwrap();
        assert_eq!(l, LogLevel::Trace);
        assert_eq!(l.level(), tracing::Level::TRACE);
    }

    #[test]
    fn debug() {
        let l = LogLevel::from_str("debug").unwrap();
        assert_eq!(l, LogLevel::Debug);
        assert_eq!(l.level(), tracing::Level::DEBUG);
    }

    #[test]
    fn info() {
        let l = LogLevel::from_str("info").unwrap();
        assert_eq!(l, LogLevel::Info);
        assert_eq!(l.level(), tracing::Level::INFO);
    }

    #[test]
    fn warn() {
        let l = LogLevel::from_str("warn").unwrap();
        assert_eq!(l, LogLevel::Warn);
        assert_eq!(l.level(), tracing::Level::WARN);
    }

    #[test]
    fn error() {
        let l = LogLevel::from_str("error").unwrap();
        assert_eq!(l, LogLevel::Error);
        assert_eq!(l.level(), tracing::Level::ERROR)
    }

    #[test]
    fn undefined() {
        assert!(LogLevel::from_str("unknown").is_err());
    }
}
