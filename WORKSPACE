workspace(name = "awair-exporter")

load("@bazel_tools//tools/build_defs/repo:http.bzl", "http_archive")

# Rust
http_archive(
    name = "rules_rust",
    sha256 = "224ebaf1156b6f2d3680e5b8c25191e71483214957dfecd25d0f29b2f283283b",
    strip_prefix = "rules_rust-a814d859845c420fd105c629134c4a4cb47ba3f8",
    urls = [
        # `main` branch as of 2021-06-15
        "https://github.com/bazelbuild/rules_rust/archive/a814d859845c420fd105c629134c4a4cb47ba3f8.tar.gz",
    ],
)

load("@rules_rust//rust:repositories.bzl", "rust_repositories")

rust_repositories(
    edition = "2018",
    version = "1.54.0",
)

# cargo raze
load("//cargo:crates.bzl", "raze_fetch_remote_crates")

raze_fetch_remote_crates()

# Docker
http_archive(
    name = "io_bazel_rules_docker",
    sha256 = "5d31ad261b9582515ff52126bf53b954526547a3e26f6c25a9d64c48a31e45ac",
    strip_prefix = "rules_docker-0.18.0",
    urls = ["https://github.com/bazelbuild/rules_docker/releases/download/v0.18.0/rules_docker-v0.18.0.tar.gz"],
)

load(
    "@io_bazel_rules_docker//repositories:repositories.bzl",
    container_repositories = "repositories",
)

container_repositories()

load("@io_bazel_rules_docker//repositories:deps.bzl", container_deps = "deps")

container_deps()

load(
    "@io_bazel_rules_docker//container:container.bzl",
    "container_pull",
)

# TODO: switch this to distroless once cc-debian11 is out. Currently, Debian 10
# is not usable because the glibc version in it is not compatbile with my local
# one.
container_pull(
    name = "rust_base_image",
    digest = "sha256:c6e865b5373b09942bc49e4b02a7b361fcfa405479ece627f5d4306554120673",  # 11
    registry = "index.docker.io",
    repository = "debian",
)
