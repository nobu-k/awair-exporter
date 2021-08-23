"""
@generated
cargo-raze generated Bazel file.

DO NOT EDIT! Replaced on runs of cargo-raze
"""

load("@bazel_tools//tools/build_defs/repo:git.bzl", "new_git_repository")  # buildifier: disable=load
load("@bazel_tools//tools/build_defs/repo:http.bzl", "http_archive")  # buildifier: disable=load
load("@bazel_tools//tools/build_defs/repo:utils.bzl", "maybe")  # buildifier: disable=load

# EXPERIMENTAL -- MAY CHANGE AT ANY TIME: A mapping of package names to a set of normal dependencies for the Rust targets of that package.
_DEPENDENCIES = {
    "awair-exporter": {
        "anyhow": "@raze__anyhow__1_0_43//:anyhow",
        "clap": "@raze__clap__3_0_0_beta_2//:clap",
        "futures": "@raze__futures__0_3_16//:futures",
        "prometheus": "@raze__prometheus__0_12_0//:prometheus",
        "reqwest": "@raze__reqwest__0_11_4//:reqwest",
        "serde": "@raze__serde__1_0_127//:serde",
        "serde_yaml": "@raze__serde_yaml__0_8_17//:serde_yaml",
        "tokio": "@raze__tokio__1_9_0//:tokio",
        "tracing": "@raze__tracing__0_1_26//:tracing",
        "tracing-subscriber": "@raze__tracing_subscriber__0_2_19//:tracing_subscriber",
        "warp": "@raze__warp__0_3_1//:warp",
    },
}

# EXPERIMENTAL -- MAY CHANGE AT ANY TIME: A mapping of package names to a set of proc_macro dependencies for the Rust targets of that package.
_PROC_MACRO_DEPENDENCIES = {
    "awair-exporter": {
    },
}

# EXPERIMENTAL -- MAY CHANGE AT ANY TIME: A mapping of package names to a set of normal dev dependencies for the Rust targets of that package.
_DEV_DEPENDENCIES = {
    "awair-exporter": {
    },
}

# EXPERIMENTAL -- MAY CHANGE AT ANY TIME: A mapping of package names to a set of proc_macro dev dependencies for the Rust targets of that package.
_DEV_PROC_MACRO_DEPENDENCIES = {
    "awair-exporter": {
    },
}

def crate_deps(deps, package_name = None):
    """EXPERIMENTAL -- MAY CHANGE AT ANY TIME: Finds the fully qualified label of the requested crates for the package where this macro is called.

    WARNING: This macro is part of an expeirmental API and is subject to change.

    Args:
        deps (list): The desired list of crate targets.
        package_name (str, optional): The package name of the set of dependencies to look up.
            Defaults to `native.package_name()`.
    Returns:
        list: A list of labels to cargo-raze generated targets (str)
    """

    if not package_name:
        package_name = native.package_name()

    # Join both sets of dependencies
    dependencies = _flatten_dependency_maps([
        _DEPENDENCIES,
        _PROC_MACRO_DEPENDENCIES,
        _DEV_DEPENDENCIES,
        _DEV_PROC_MACRO_DEPENDENCIES,
    ])

    if not deps:
        return []

    missing_crates = []
    crate_targets = []
    for crate_target in deps:
        if crate_target not in dependencies[package_name]:
            missing_crates.append(crate_target)
        else:
            crate_targets.append(dependencies[package_name][crate_target])

    if missing_crates:
        fail("Could not find crates `{}` among dependencies of `{}`. Available dependencies were `{}`".format(
            missing_crates,
            package_name,
            dependencies[package_name],
        ))

    return crate_targets

def all_crate_deps(normal = False, normal_dev = False, proc_macro = False, proc_macro_dev = False, package_name = None):
    """EXPERIMENTAL -- MAY CHANGE AT ANY TIME: Finds the fully qualified label of all requested direct crate dependencies \
    for the package where this macro is called.

    If no parameters are set, all normal dependencies are returned. Setting any one flag will
    otherwise impact the contents of the returned list.

    Args:
        normal (bool, optional): If True, normal dependencies are included in the
            output list. Defaults to False.
        normal_dev (bool, optional): If True, normla dev dependencies will be
            included in the output list. Defaults to False.
        proc_macro (bool, optional): If True, proc_macro dependencies are included
            in the output list. Defaults to False.
        proc_macro_dev (bool, optional): If True, dev proc_macro dependencies are
            included in the output list. Defaults to False.
        package_name (str, optional): The package name of the set of dependencies to look up.
            Defaults to `native.package_name()`.

    Returns:
        list: A list of labels to cargo-raze generated targets (str)
    """

    if not package_name:
        package_name = native.package_name()

    # Determine the relevant maps to use
    all_dependency_maps = []
    if normal:
        all_dependency_maps.append(_DEPENDENCIES)
    if normal_dev:
        all_dependency_maps.append(_DEV_DEPENDENCIES)
    if proc_macro:
        all_dependency_maps.append(_PROC_MACRO_DEPENDENCIES)
    if proc_macro_dev:
        all_dependency_maps.append(_DEV_PROC_MACRO_DEPENDENCIES)

    # Default to always using normal dependencies
    if not all_dependency_maps:
        all_dependency_maps.append(_DEPENDENCIES)

    dependencies = _flatten_dependency_maps(all_dependency_maps)

    if not dependencies:
        return []

    return dependencies[package_name].values()

def _flatten_dependency_maps(all_dependency_maps):
    """Flatten a list of dependency maps into one dictionary.

    Dependency maps have the following structure:

    ```python
    DEPENDENCIES_MAP = {
        # The first key in the map is a Bazel package
        # name of the workspace this file is defined in.
        "package_name": {

            # An alias to a crate target.     # The label of the crate target the
            # Aliases are only crate names.   # alias refers to.
            "alias":                          "@full//:label",
        }
    }
    ```

    Args:
        all_dependency_maps (list): A list of dicts as described above

    Returns:
        dict: A dictionary as described above
    """
    dependencies = {}

    for dep_map in all_dependency_maps:
        for pkg_name in dep_map:
            if pkg_name not in dependencies:
                # Add a non-frozen dict to the collection of dependencies
                dependencies.setdefault(pkg_name, dict(dep_map[pkg_name].items()))
                continue

            duplicate_crate_aliases = [key for key in dependencies[pkg_name] if key in dep_map[pkg_name]]
            if duplicate_crate_aliases:
                fail("There should be no duplicate crate aliases: {}".format(duplicate_crate_aliases))

            dependencies[pkg_name].update(dep_map[pkg_name])

    return dependencies

def raze_fetch_remote_crates():
    """This function defines a collection of repos and should be called in a WORKSPACE file"""
    maybe(
        http_archive,
        name = "raze__adler__1_0_2",
        url = "https://crates.io/api/v1/crates/adler/1.0.2/download",
        type = "tar.gz",
        sha256 = "f26201604c87b1e01bd3d98f8d5d9a8fcbb815e8cedb41ffccbeb4bf593a35fe",
        strip_prefix = "adler-1.0.2",
        build_file = Label("//cargo/remote:BUILD.adler-1.0.2.bazel"),
    )

    maybe(
        http_archive,
        name = "raze__ansi_term__0_12_1",
        url = "https://crates.io/api/v1/crates/ansi_term/0.12.1/download",
        type = "tar.gz",
        sha256 = "d52a9bb7ec0cf484c551830a7ce27bd20d67eac647e1befb56b0be4ee39a55d2",
        strip_prefix = "ansi_term-0.12.1",
        build_file = Label("//cargo/remote:BUILD.ansi_term-0.12.1.bazel"),
    )

    maybe(
        http_archive,
        name = "raze__anyhow__1_0_43",
        url = "https://crates.io/api/v1/crates/anyhow/1.0.43/download",
        type = "tar.gz",
        sha256 = "28ae2b3dec75a406790005a200b1bd89785afc02517a00ca99ecfe093ee9e6cf",
        strip_prefix = "anyhow-1.0.43",
        build_file = Label("//cargo/remote:BUILD.anyhow-1.0.43.bazel"),
    )

    maybe(
        http_archive,
        name = "raze__atty__0_2_14",
        url = "https://crates.io/api/v1/crates/atty/0.2.14/download",
        type = "tar.gz",
        sha256 = "d9b39be18770d11421cdb1b9947a45dd3f37e93092cbf377614828a319d5fee8",
        strip_prefix = "atty-0.2.14",
        build_file = Label("//cargo/remote:BUILD.atty-0.2.14.bazel"),
    )

    maybe(
        http_archive,
        name = "raze__autocfg__1_0_1",
        url = "https://crates.io/api/v1/crates/autocfg/1.0.1/download",
        type = "tar.gz",
        sha256 = "cdb031dd78e28731d87d56cc8ffef4a8f36ca26c38fe2de700543e627f8a464a",
        strip_prefix = "autocfg-1.0.1",
        build_file = Label("//cargo/remote:BUILD.autocfg-1.0.1.bazel"),
    )

    maybe(
        http_archive,
        name = "raze__base64__0_13_0",
        url = "https://crates.io/api/v1/crates/base64/0.13.0/download",
        type = "tar.gz",
        sha256 = "904dfeac50f3cdaba28fc6f57fdcddb75f49ed61346676a78c4ffe55877802fd",
        strip_prefix = "base64-0.13.0",
        build_file = Label("//cargo/remote:BUILD.base64-0.13.0.bazel"),
    )

    maybe(
        http_archive,
        name = "raze__bitflags__1_2_1",
        url = "https://crates.io/api/v1/crates/bitflags/1.2.1/download",
        type = "tar.gz",
        sha256 = "cf1de2fe8c75bc145a2f577add951f8134889b4795d47466a54a5c846d691693",
        strip_prefix = "bitflags-1.2.1",
        build_file = Label("//cargo/remote:BUILD.bitflags-1.2.1.bazel"),
    )

    maybe(
        http_archive,
        name = "raze__block_buffer__0_9_0",
        url = "https://crates.io/api/v1/crates/block-buffer/0.9.0/download",
        type = "tar.gz",
        sha256 = "4152116fd6e9dadb291ae18fc1ec3575ed6d84c29642d97890f4b4a3417297e4",
        strip_prefix = "block-buffer-0.9.0",
        build_file = Label("//cargo/remote:BUILD.block-buffer-0.9.0.bazel"),
    )

    maybe(
        http_archive,
        name = "raze__buf_redux__0_8_4",
        url = "https://crates.io/api/v1/crates/buf_redux/0.8.4/download",
        type = "tar.gz",
        sha256 = "b953a6887648bb07a535631f2bc00fbdb2a2216f135552cb3f534ed136b9c07f",
        strip_prefix = "buf_redux-0.8.4",
        build_file = Label("//cargo/remote:BUILD.buf_redux-0.8.4.bazel"),
    )

    maybe(
        http_archive,
        name = "raze__bumpalo__3_7_0",
        url = "https://crates.io/api/v1/crates/bumpalo/3.7.0/download",
        type = "tar.gz",
        sha256 = "9c59e7af012c713f529e7a3ee57ce9b31ddd858d4b512923602f74608b009631",
        strip_prefix = "bumpalo-3.7.0",
        build_file = Label("//cargo/remote:BUILD.bumpalo-3.7.0.bazel"),
    )

    maybe(
        http_archive,
        name = "raze__byteorder__1_4_3",
        url = "https://crates.io/api/v1/crates/byteorder/1.4.3/download",
        type = "tar.gz",
        sha256 = "14c189c53d098945499cdfa7ecc63567cf3886b3332b312a5b4585d8d3a6a610",
        strip_prefix = "byteorder-1.4.3",
        build_file = Label("//cargo/remote:BUILD.byteorder-1.4.3.bazel"),
    )

    maybe(
        http_archive,
        name = "raze__bytes__1_0_1",
        url = "https://crates.io/api/v1/crates/bytes/1.0.1/download",
        type = "tar.gz",
        sha256 = "b700ce4376041dcd0a327fd0097c41095743c4c8af8887265942faf1100bd040",
        strip_prefix = "bytes-1.0.1",
        build_file = Label("//cargo/remote:BUILD.bytes-1.0.1.bazel"),
    )

    maybe(
        http_archive,
        name = "raze__cc__1_0_69",
        url = "https://crates.io/api/v1/crates/cc/1.0.69/download",
        type = "tar.gz",
        sha256 = "e70cc2f62c6ce1868963827bd677764c62d07c3d9a3e1fb1177ee1a9ab199eb2",
        strip_prefix = "cc-1.0.69",
        build_file = Label("//cargo/remote:BUILD.cc-1.0.69.bazel"),
    )

    maybe(
        http_archive,
        name = "raze__cfg_if__1_0_0",
        url = "https://crates.io/api/v1/crates/cfg-if/1.0.0/download",
        type = "tar.gz",
        sha256 = "baf1de4339761588bc0619e3cbc0120ee582ebb74b53b4efbf79117bd2da40fd",
        strip_prefix = "cfg-if-1.0.0",
        build_file = Label("//cargo/remote:BUILD.cfg-if-1.0.0.bazel"),
    )

    maybe(
        http_archive,
        name = "raze__chrono__0_4_19",
        url = "https://crates.io/api/v1/crates/chrono/0.4.19/download",
        type = "tar.gz",
        sha256 = "670ad68c9088c2a963aaa298cb369688cf3f9465ce5e2d4ca10e6e0098a1ce73",
        strip_prefix = "chrono-0.4.19",
        build_file = Label("//cargo/remote:BUILD.chrono-0.4.19.bazel"),
    )

    maybe(
        http_archive,
        name = "raze__clap__3_0_0_beta_2",
        url = "https://crates.io/api/v1/crates/clap/3.0.0-beta.2/download",
        type = "tar.gz",
        sha256 = "4bd1061998a501ee7d4b6d449020df3266ca3124b941ec56cf2005c3779ca142",
        strip_prefix = "clap-3.0.0-beta.2",
        build_file = Label("//cargo/remote:BUILD.clap-3.0.0-beta.2.bazel"),
    )

    maybe(
        http_archive,
        name = "raze__clap_derive__3_0_0_beta_2",
        url = "https://crates.io/api/v1/crates/clap_derive/3.0.0-beta.2/download",
        type = "tar.gz",
        sha256 = "370f715b81112975b1b69db93e0b56ea4cd4e5002ac43b2da8474106a54096a1",
        strip_prefix = "clap_derive-3.0.0-beta.2",
        build_file = Label("//cargo/remote:BUILD.clap_derive-3.0.0-beta.2.bazel"),
    )

    maybe(
        http_archive,
        name = "raze__core_foundation__0_9_1",
        url = "https://crates.io/api/v1/crates/core-foundation/0.9.1/download",
        type = "tar.gz",
        sha256 = "0a89e2ae426ea83155dccf10c0fa6b1463ef6d5fcb44cee0b224a408fa640a62",
        strip_prefix = "core-foundation-0.9.1",
        build_file = Label("//cargo/remote:BUILD.core-foundation-0.9.1.bazel"),
    )

    maybe(
        http_archive,
        name = "raze__core_foundation_sys__0_8_2",
        url = "https://crates.io/api/v1/crates/core-foundation-sys/0.8.2/download",
        type = "tar.gz",
        sha256 = "ea221b5284a47e40033bf9b66f35f984ec0ea2931eb03505246cd27a963f981b",
        strip_prefix = "core-foundation-sys-0.8.2",
        build_file = Label("//cargo/remote:BUILD.core-foundation-sys-0.8.2.bazel"),
    )

    maybe(
        http_archive,
        name = "raze__cpufeatures__0_1_5",
        url = "https://crates.io/api/v1/crates/cpufeatures/0.1.5/download",
        type = "tar.gz",
        sha256 = "66c99696f6c9dd7f35d486b9d04d7e6e202aa3e8c40d553f2fdf5e7e0c6a71ef",
        strip_prefix = "cpufeatures-0.1.5",
        build_file = Label("//cargo/remote:BUILD.cpufeatures-0.1.5.bazel"),
    )

    maybe(
        http_archive,
        name = "raze__crc32fast__1_2_1",
        url = "https://crates.io/api/v1/crates/crc32fast/1.2.1/download",
        type = "tar.gz",
        sha256 = "81156fece84ab6a9f2afdb109ce3ae577e42b1228441eded99bd77f627953b1a",
        strip_prefix = "crc32fast-1.2.1",
        build_file = Label("//cargo/remote:BUILD.crc32fast-1.2.1.bazel"),
    )

    maybe(
        http_archive,
        name = "raze__digest__0_9_0",
        url = "https://crates.io/api/v1/crates/digest/0.9.0/download",
        type = "tar.gz",
        sha256 = "d3dd60d1080a57a05ab032377049e0591415d2b31afd7028356dbf3cc6dcb066",
        strip_prefix = "digest-0.9.0",
        build_file = Label("//cargo/remote:BUILD.digest-0.9.0.bazel"),
    )

    maybe(
        http_archive,
        name = "raze__dtoa__0_4_8",
        url = "https://crates.io/api/v1/crates/dtoa/0.4.8/download",
        type = "tar.gz",
        sha256 = "56899898ce76aaf4a0f24d914c97ea6ed976d42fec6ad33fcbb0a1103e07b2b0",
        strip_prefix = "dtoa-0.4.8",
        build_file = Label("//cargo/remote:BUILD.dtoa-0.4.8.bazel"),
    )

    maybe(
        http_archive,
        name = "raze__encoding_rs__0_8_28",
        url = "https://crates.io/api/v1/crates/encoding_rs/0.8.28/download",
        type = "tar.gz",
        sha256 = "80df024fbc5ac80f87dfef0d9f5209a252f2a497f7f42944cff24d8253cac065",
        strip_prefix = "encoding_rs-0.8.28",
        build_file = Label("//cargo/remote:BUILD.encoding_rs-0.8.28.bazel"),
    )

    maybe(
        http_archive,
        name = "raze__flate2__1_0_20",
        url = "https://crates.io/api/v1/crates/flate2/1.0.20/download",
        type = "tar.gz",
        sha256 = "cd3aec53de10fe96d7d8c565eb17f2c687bb5518a2ec453b5b1252964526abe0",
        strip_prefix = "flate2-1.0.20",
        build_file = Label("//cargo/remote:BUILD.flate2-1.0.20.bazel"),
    )

    maybe(
        http_archive,
        name = "raze__fnv__1_0_7",
        url = "https://crates.io/api/v1/crates/fnv/1.0.7/download",
        type = "tar.gz",
        sha256 = "3f9eec918d3f24069decb9af1554cad7c880e2da24a9afd88aca000531ab82c1",
        strip_prefix = "fnv-1.0.7",
        build_file = Label("//cargo/remote:BUILD.fnv-1.0.7.bazel"),
    )

    maybe(
        http_archive,
        name = "raze__foreign_types__0_3_2",
        url = "https://crates.io/api/v1/crates/foreign-types/0.3.2/download",
        type = "tar.gz",
        sha256 = "f6f339eb8adc052cd2ca78910fda869aefa38d22d5cb648e6485e4d3fc06f3b1",
        strip_prefix = "foreign-types-0.3.2",
        build_file = Label("//cargo/remote:BUILD.foreign-types-0.3.2.bazel"),
    )

    maybe(
        http_archive,
        name = "raze__foreign_types_shared__0_1_1",
        url = "https://crates.io/api/v1/crates/foreign-types-shared/0.1.1/download",
        type = "tar.gz",
        sha256 = "00b0228411908ca8685dba7fc2cdd70ec9990a6e753e89b6ac91a84c40fbaf4b",
        strip_prefix = "foreign-types-shared-0.1.1",
        build_file = Label("//cargo/remote:BUILD.foreign-types-shared-0.1.1.bazel"),
    )

    maybe(
        http_archive,
        name = "raze__form_urlencoded__1_0_1",
        url = "https://crates.io/api/v1/crates/form_urlencoded/1.0.1/download",
        type = "tar.gz",
        sha256 = "5fc25a87fa4fd2094bffb06925852034d90a17f0d1e05197d4956d3555752191",
        strip_prefix = "form_urlencoded-1.0.1",
        build_file = Label("//cargo/remote:BUILD.form_urlencoded-1.0.1.bazel"),
    )

    maybe(
        http_archive,
        name = "raze__futures__0_3_16",
        url = "https://crates.io/api/v1/crates/futures/0.3.16/download",
        type = "tar.gz",
        sha256 = "1adc00f486adfc9ce99f77d717836f0c5aa84965eb0b4f051f4e83f7cab53f8b",
        strip_prefix = "futures-0.3.16",
        build_file = Label("//cargo/remote:BUILD.futures-0.3.16.bazel"),
    )

    maybe(
        http_archive,
        name = "raze__futures_channel__0_3_16",
        url = "https://crates.io/api/v1/crates/futures-channel/0.3.16/download",
        type = "tar.gz",
        sha256 = "74ed2411805f6e4e3d9bc904c95d5d423b89b3b25dc0250aa74729de20629ff9",
        strip_prefix = "futures-channel-0.3.16",
        build_file = Label("//cargo/remote:BUILD.futures-channel-0.3.16.bazel"),
    )

    maybe(
        http_archive,
        name = "raze__futures_core__0_3_16",
        url = "https://crates.io/api/v1/crates/futures-core/0.3.16/download",
        type = "tar.gz",
        sha256 = "af51b1b4a7fdff033703db39de8802c673eb91855f2e0d47dcf3bf2c0ef01f99",
        strip_prefix = "futures-core-0.3.16",
        build_file = Label("//cargo/remote:BUILD.futures-core-0.3.16.bazel"),
    )

    maybe(
        http_archive,
        name = "raze__futures_executor__0_3_16",
        url = "https://crates.io/api/v1/crates/futures-executor/0.3.16/download",
        type = "tar.gz",
        sha256 = "4d0d535a57b87e1ae31437b892713aee90cd2d7b0ee48727cd11fc72ef54761c",
        strip_prefix = "futures-executor-0.3.16",
        build_file = Label("//cargo/remote:BUILD.futures-executor-0.3.16.bazel"),
    )

    maybe(
        http_archive,
        name = "raze__futures_io__0_3_16",
        url = "https://crates.io/api/v1/crates/futures-io/0.3.16/download",
        type = "tar.gz",
        sha256 = "0b0e06c393068f3a6ef246c75cdca793d6a46347e75286933e5e75fd2fd11582",
        strip_prefix = "futures-io-0.3.16",
        build_file = Label("//cargo/remote:BUILD.futures-io-0.3.16.bazel"),
    )

    maybe(
        http_archive,
        name = "raze__futures_macro__0_3_16",
        url = "https://crates.io/api/v1/crates/futures-macro/0.3.16/download",
        type = "tar.gz",
        sha256 = "c54913bae956fb8df7f4dc6fc90362aa72e69148e3f39041fbe8742d21e0ac57",
        strip_prefix = "futures-macro-0.3.16",
        build_file = Label("//cargo/remote:BUILD.futures-macro-0.3.16.bazel"),
    )

    maybe(
        http_archive,
        name = "raze__futures_sink__0_3_16",
        url = "https://crates.io/api/v1/crates/futures-sink/0.3.16/download",
        type = "tar.gz",
        sha256 = "c0f30aaa67363d119812743aa5f33c201a7a66329f97d1a887022971feea4b53",
        strip_prefix = "futures-sink-0.3.16",
        build_file = Label("//cargo/remote:BUILD.futures-sink-0.3.16.bazel"),
    )

    maybe(
        http_archive,
        name = "raze__futures_task__0_3_16",
        url = "https://crates.io/api/v1/crates/futures-task/0.3.16/download",
        type = "tar.gz",
        sha256 = "bbe54a98670017f3be909561f6ad13e810d9a51f3f061b902062ca3da80799f2",
        strip_prefix = "futures-task-0.3.16",
        build_file = Label("//cargo/remote:BUILD.futures-task-0.3.16.bazel"),
    )

    maybe(
        http_archive,
        name = "raze__futures_util__0_3_16",
        url = "https://crates.io/api/v1/crates/futures-util/0.3.16/download",
        type = "tar.gz",
        sha256 = "67eb846bfd58e44a8481a00049e82c43e0ccb5d61f8dc071057cb19249dd4d78",
        strip_prefix = "futures-util-0.3.16",
        build_file = Label("//cargo/remote:BUILD.futures-util-0.3.16.bazel"),
    )

    maybe(
        http_archive,
        name = "raze__generic_array__0_14_4",
        url = "https://crates.io/api/v1/crates/generic-array/0.14.4/download",
        type = "tar.gz",
        sha256 = "501466ecc8a30d1d3b7fc9229b122b2ce8ed6e9d9223f1138d4babb253e51817",
        strip_prefix = "generic-array-0.14.4",
        build_file = Label("//cargo/remote:BUILD.generic-array-0.14.4.bazel"),
    )

    maybe(
        http_archive,
        name = "raze__getrandom__0_1_16",
        url = "https://crates.io/api/v1/crates/getrandom/0.1.16/download",
        type = "tar.gz",
        sha256 = "8fc3cb4d91f53b50155bdcfd23f6a4c39ae1969c2ae85982b135750cccaf5fce",
        strip_prefix = "getrandom-0.1.16",
        build_file = Label("//cargo/remote:BUILD.getrandom-0.1.16.bazel"),
    )

    maybe(
        http_archive,
        name = "raze__getrandom__0_2_3",
        url = "https://crates.io/api/v1/crates/getrandom/0.2.3/download",
        type = "tar.gz",
        sha256 = "7fcd999463524c52659517fe2cea98493cfe485d10565e7b0fb07dbba7ad2753",
        strip_prefix = "getrandom-0.2.3",
        build_file = Label("//cargo/remote:BUILD.getrandom-0.2.3.bazel"),
    )

    maybe(
        http_archive,
        name = "raze__h2__0_3_3",
        url = "https://crates.io/api/v1/crates/h2/0.3.3/download",
        type = "tar.gz",
        sha256 = "825343c4eef0b63f541f8903f395dc5beb362a979b5799a84062527ef1e37726",
        strip_prefix = "h2-0.3.3",
        build_file = Label("//cargo/remote:BUILD.h2-0.3.3.bazel"),
    )

    maybe(
        http_archive,
        name = "raze__hashbrown__0_11_2",
        url = "https://crates.io/api/v1/crates/hashbrown/0.11.2/download",
        type = "tar.gz",
        sha256 = "ab5ef0d4909ef3724cc8cce6ccc8572c5c817592e9285f5464f8e86f8bd3726e",
        strip_prefix = "hashbrown-0.11.2",
        build_file = Label("//cargo/remote:BUILD.hashbrown-0.11.2.bazel"),
    )

    maybe(
        http_archive,
        name = "raze__headers__0_3_4",
        url = "https://crates.io/api/v1/crates/headers/0.3.4/download",
        type = "tar.gz",
        sha256 = "f0b7591fb62902706ae8e7aaff416b1b0fa2c0fd0878b46dc13baa3712d8a855",
        strip_prefix = "headers-0.3.4",
        build_file = Label("//cargo/remote:BUILD.headers-0.3.4.bazel"),
    )

    maybe(
        http_archive,
        name = "raze__headers_core__0_2_0",
        url = "https://crates.io/api/v1/crates/headers-core/0.2.0/download",
        type = "tar.gz",
        sha256 = "e7f66481bfee273957b1f20485a4ff3362987f85b2c236580d81b4eb7a326429",
        strip_prefix = "headers-core-0.2.0",
        build_file = Label("//cargo/remote:BUILD.headers-core-0.2.0.bazel"),
    )

    maybe(
        http_archive,
        name = "raze__heck__0_3_3",
        url = "https://crates.io/api/v1/crates/heck/0.3.3/download",
        type = "tar.gz",
        sha256 = "6d621efb26863f0e9924c6ac577e8275e5e6b77455db64ffa6c65c904e9e132c",
        strip_prefix = "heck-0.3.3",
        build_file = Label("//cargo/remote:BUILD.heck-0.3.3.bazel"),
    )

    maybe(
        http_archive,
        name = "raze__hermit_abi__0_1_19",
        url = "https://crates.io/api/v1/crates/hermit-abi/0.1.19/download",
        type = "tar.gz",
        sha256 = "62b467343b94ba476dcb2500d242dadbb39557df889310ac77c5d99100aaac33",
        strip_prefix = "hermit-abi-0.1.19",
        build_file = Label("//cargo/remote:BUILD.hermit-abi-0.1.19.bazel"),
    )

    maybe(
        http_archive,
        name = "raze__hex__0_4_3",
        url = "https://crates.io/api/v1/crates/hex/0.4.3/download",
        type = "tar.gz",
        sha256 = "7f24254aa9a54b5c858eaee2f5bccdb46aaf0e486a595ed5fd8f86ba55232a70",
        strip_prefix = "hex-0.4.3",
        build_file = Label("//cargo/remote:BUILD.hex-0.4.3.bazel"),
    )

    maybe(
        http_archive,
        name = "raze__http__0_2_4",
        url = "https://crates.io/api/v1/crates/http/0.2.4/download",
        type = "tar.gz",
        sha256 = "527e8c9ac747e28542699a951517aa9a6945af506cd1f2e1b53a576c17b6cc11",
        strip_prefix = "http-0.2.4",
        build_file = Label("//cargo/remote:BUILD.http-0.2.4.bazel"),
    )

    maybe(
        http_archive,
        name = "raze__http_body__0_4_3",
        url = "https://crates.io/api/v1/crates/http-body/0.4.3/download",
        type = "tar.gz",
        sha256 = "399c583b2979440c60be0821a6199eca73bc3c8dcd9d070d75ac726e2c6186e5",
        strip_prefix = "http-body-0.4.3",
        build_file = Label("//cargo/remote:BUILD.http-body-0.4.3.bazel"),
    )

    maybe(
        http_archive,
        name = "raze__httparse__1_4_1",
        url = "https://crates.io/api/v1/crates/httparse/1.4.1/download",
        type = "tar.gz",
        sha256 = "f3a87b616e37e93c22fb19bcd386f02f3af5ea98a25670ad0fce773de23c5e68",
        strip_prefix = "httparse-1.4.1",
        build_file = Label("//cargo/remote:BUILD.httparse-1.4.1.bazel"),
    )

    maybe(
        http_archive,
        name = "raze__httpdate__1_0_1",
        url = "https://crates.io/api/v1/crates/httpdate/1.0.1/download",
        type = "tar.gz",
        sha256 = "6456b8a6c8f33fee7d958fcd1b60d55b11940a79e63ae87013e6d22e26034440",
        strip_prefix = "httpdate-1.0.1",
        build_file = Label("//cargo/remote:BUILD.httpdate-1.0.1.bazel"),
    )

    maybe(
        http_archive,
        name = "raze__hyper__0_14_11",
        url = "https://crates.io/api/v1/crates/hyper/0.14.11/download",
        type = "tar.gz",
        sha256 = "0b61cf2d1aebcf6e6352c97b81dc2244ca29194be1b276f5d8ad5c6330fffb11",
        strip_prefix = "hyper-0.14.11",
        build_file = Label("//cargo/remote:BUILD.hyper-0.14.11.bazel"),
    )

    maybe(
        http_archive,
        name = "raze__hyper_tls__0_5_0",
        url = "https://crates.io/api/v1/crates/hyper-tls/0.5.0/download",
        type = "tar.gz",
        sha256 = "d6183ddfa99b85da61a140bea0efc93fdf56ceaa041b37d553518030827f9905",
        strip_prefix = "hyper-tls-0.5.0",
        build_file = Label("//cargo/remote:BUILD.hyper-tls-0.5.0.bazel"),
    )

    maybe(
        http_archive,
        name = "raze__idna__0_2_3",
        url = "https://crates.io/api/v1/crates/idna/0.2.3/download",
        type = "tar.gz",
        sha256 = "418a0a6fab821475f634efe3ccc45c013f742efe03d853e8d3355d5cb850ecf8",
        strip_prefix = "idna-0.2.3",
        build_file = Label("//cargo/remote:BUILD.idna-0.2.3.bazel"),
    )

    maybe(
        http_archive,
        name = "raze__indexmap__1_7_0",
        url = "https://crates.io/api/v1/crates/indexmap/1.7.0/download",
        type = "tar.gz",
        sha256 = "bc633605454125dec4b66843673f01c7df2b89479b32e0ed634e43a91cff62a5",
        strip_prefix = "indexmap-1.7.0",
        build_file = Label("//cargo/remote:BUILD.indexmap-1.7.0.bazel"),
    )

    maybe(
        http_archive,
        name = "raze__input_buffer__0_4_0",
        url = "https://crates.io/api/v1/crates/input_buffer/0.4.0/download",
        type = "tar.gz",
        sha256 = "f97967975f448f1a7ddb12b0bc41069d09ed6a1c161a92687e057325db35d413",
        strip_prefix = "input_buffer-0.4.0",
        build_file = Label("//cargo/remote:BUILD.input_buffer-0.4.0.bazel"),
    )

    maybe(
        http_archive,
        name = "raze__instant__0_1_10",
        url = "https://crates.io/api/v1/crates/instant/0.1.10/download",
        type = "tar.gz",
        sha256 = "bee0328b1209d157ef001c94dd85b4f8f64139adb0eac2659f4b08382b2f474d",
        strip_prefix = "instant-0.1.10",
        build_file = Label("//cargo/remote:BUILD.instant-0.1.10.bazel"),
    )

    maybe(
        http_archive,
        name = "raze__ipnet__2_3_1",
        url = "https://crates.io/api/v1/crates/ipnet/2.3.1/download",
        type = "tar.gz",
        sha256 = "68f2d64f2edebec4ce84ad108148e67e1064789bee435edc5b60ad398714a3a9",
        strip_prefix = "ipnet-2.3.1",
        build_file = Label("//cargo/remote:BUILD.ipnet-2.3.1.bazel"),
    )

    maybe(
        http_archive,
        name = "raze__itoa__0_4_7",
        url = "https://crates.io/api/v1/crates/itoa/0.4.7/download",
        type = "tar.gz",
        sha256 = "dd25036021b0de88a0aff6b850051563c6516d0bf53f8638938edbb9de732736",
        strip_prefix = "itoa-0.4.7",
        build_file = Label("//cargo/remote:BUILD.itoa-0.4.7.bazel"),
    )

    maybe(
        http_archive,
        name = "raze__js_sys__0_3_52",
        url = "https://crates.io/api/v1/crates/js-sys/0.3.52/download",
        type = "tar.gz",
        sha256 = "ce791b7ca6638aae45be056e068fc756d871eb3b3b10b8efa62d1c9cec616752",
        strip_prefix = "js-sys-0.3.52",
        build_file = Label("//cargo/remote:BUILD.js-sys-0.3.52.bazel"),
    )

    maybe(
        http_archive,
        name = "raze__lazy_static__1_4_0",
        url = "https://crates.io/api/v1/crates/lazy_static/1.4.0/download",
        type = "tar.gz",
        sha256 = "e2abad23fbc42b3700f2f279844dc832adb2b2eb069b2df918f455c4e18cc646",
        strip_prefix = "lazy_static-1.4.0",
        build_file = Label("//cargo/remote:BUILD.lazy_static-1.4.0.bazel"),
    )

    maybe(
        http_archive,
        name = "raze__libc__0_2_98",
        url = "https://crates.io/api/v1/crates/libc/0.2.98/download",
        type = "tar.gz",
        sha256 = "320cfe77175da3a483efed4bc0adc1968ca050b098ce4f2f1c13a56626128790",
        strip_prefix = "libc-0.2.98",
        build_file = Label("//cargo/remote:BUILD.libc-0.2.98.bazel"),
    )

    maybe(
        http_archive,
        name = "raze__linked_hash_map__0_5_4",
        url = "https://crates.io/api/v1/crates/linked-hash-map/0.5.4/download",
        type = "tar.gz",
        sha256 = "7fb9b38af92608140b86b693604b9ffcc5824240a484d1ecd4795bacb2fe88f3",
        strip_prefix = "linked-hash-map-0.5.4",
        build_file = Label("//cargo/remote:BUILD.linked-hash-map-0.5.4.bazel"),
    )

    maybe(
        http_archive,
        name = "raze__lock_api__0_4_4",
        url = "https://crates.io/api/v1/crates/lock_api/0.4.4/download",
        type = "tar.gz",
        sha256 = "0382880606dff6d15c9476c416d18690b72742aa7b605bb6dd6ec9030fbf07eb",
        strip_prefix = "lock_api-0.4.4",
        build_file = Label("//cargo/remote:BUILD.lock_api-0.4.4.bazel"),
    )

    maybe(
        http_archive,
        name = "raze__log__0_4_14",
        url = "https://crates.io/api/v1/crates/log/0.4.14/download",
        type = "tar.gz",
        sha256 = "51b9bbe6c47d51fc3e1a9b945965946b4c44142ab8792c50835a980d362c2710",
        strip_prefix = "log-0.4.14",
        build_file = Label("//cargo/remote:BUILD.log-0.4.14.bazel"),
    )

    maybe(
        http_archive,
        name = "raze__matchers__0_0_1",
        url = "https://crates.io/api/v1/crates/matchers/0.0.1/download",
        type = "tar.gz",
        sha256 = "f099785f7595cc4b4553a174ce30dd7589ef93391ff414dbb67f62392b9e0ce1",
        strip_prefix = "matchers-0.0.1",
        build_file = Label("//cargo/remote:BUILD.matchers-0.0.1.bazel"),
    )

    maybe(
        http_archive,
        name = "raze__matches__0_1_8",
        url = "https://crates.io/api/v1/crates/matches/0.1.8/download",
        type = "tar.gz",
        sha256 = "7ffc5c5338469d4d3ea17d269fa8ea3512ad247247c30bd2df69e68309ed0a08",
        strip_prefix = "matches-0.1.8",
        build_file = Label("//cargo/remote:BUILD.matches-0.1.8.bazel"),
    )

    maybe(
        http_archive,
        name = "raze__memchr__2_4_0",
        url = "https://crates.io/api/v1/crates/memchr/2.4.0/download",
        type = "tar.gz",
        sha256 = "b16bd47d9e329435e309c58469fe0791c2d0d1ba96ec0954152a5ae2b04387dc",
        strip_prefix = "memchr-2.4.0",
        build_file = Label("//cargo/remote:BUILD.memchr-2.4.0.bazel"),
    )

    maybe(
        http_archive,
        name = "raze__mime__0_3_16",
        url = "https://crates.io/api/v1/crates/mime/0.3.16/download",
        type = "tar.gz",
        sha256 = "2a60c7ce501c71e03a9c9c0d35b861413ae925bd979cc7a4e30d060069aaac8d",
        strip_prefix = "mime-0.3.16",
        build_file = Label("//cargo/remote:BUILD.mime-0.3.16.bazel"),
    )

    maybe(
        http_archive,
        name = "raze__mime_guess__2_0_3",
        url = "https://crates.io/api/v1/crates/mime_guess/2.0.3/download",
        type = "tar.gz",
        sha256 = "2684d4c2e97d99848d30b324b00c8fcc7e5c897b7cbb5819b09e7c90e8baf212",
        strip_prefix = "mime_guess-2.0.3",
        build_file = Label("//cargo/remote:BUILD.mime_guess-2.0.3.bazel"),
    )

    maybe(
        http_archive,
        name = "raze__miniz_oxide__0_4_4",
        url = "https://crates.io/api/v1/crates/miniz_oxide/0.4.4/download",
        type = "tar.gz",
        sha256 = "a92518e98c078586bc6c934028adcca4c92a53d6a958196de835170a01d84e4b",
        strip_prefix = "miniz_oxide-0.4.4",
        build_file = Label("//cargo/remote:BUILD.miniz_oxide-0.4.4.bazel"),
    )

    maybe(
        http_archive,
        name = "raze__mio__0_7_13",
        url = "https://crates.io/api/v1/crates/mio/0.7.13/download",
        type = "tar.gz",
        sha256 = "8c2bdb6314ec10835cd3293dd268473a835c02b7b352e788be788b3c6ca6bb16",
        strip_prefix = "mio-0.7.13",
        build_file = Label("//cargo/remote:BUILD.mio-0.7.13.bazel"),
    )

    maybe(
        http_archive,
        name = "raze__miow__0_3_7",
        url = "https://crates.io/api/v1/crates/miow/0.3.7/download",
        type = "tar.gz",
        sha256 = "b9f1c5b025cda876f66ef43a113f91ebc9f4ccef34843000e0adf6ebbab84e21",
        strip_prefix = "miow-0.3.7",
        build_file = Label("//cargo/remote:BUILD.miow-0.3.7.bazel"),
    )

    maybe(
        http_archive,
        name = "raze__multipart__0_17_1",
        url = "https://crates.io/api/v1/crates/multipart/0.17.1/download",
        type = "tar.gz",
        sha256 = "d050aeedc89243f5347c3e237e3e13dc76fbe4ae3742a57b94dc14f69acf76d4",
        strip_prefix = "multipart-0.17.1",
        build_file = Label("//cargo/remote:BUILD.multipart-0.17.1.bazel"),
    )

    maybe(
        http_archive,
        name = "raze__native_tls__0_2_8",
        url = "https://crates.io/api/v1/crates/native-tls/0.2.8/download",
        type = "tar.gz",
        sha256 = "48ba9f7719b5a0f42f338907614285fb5fd70e53858141f69898a1fb7203b24d",
        strip_prefix = "native-tls-0.2.8",
        build_file = Label("//cargo/remote:BUILD.native-tls-0.2.8.bazel"),
    )

    maybe(
        http_archive,
        name = "raze__ntapi__0_3_6",
        url = "https://crates.io/api/v1/crates/ntapi/0.3.6/download",
        type = "tar.gz",
        sha256 = "3f6bb902e437b6d86e03cce10a7e2af662292c5dfef23b65899ea3ac9354ad44",
        strip_prefix = "ntapi-0.3.6",
        build_file = Label("//cargo/remote:BUILD.ntapi-0.3.6.bazel"),
    )

    maybe(
        http_archive,
        name = "raze__num_integer__0_1_44",
        url = "https://crates.io/api/v1/crates/num-integer/0.1.44/download",
        type = "tar.gz",
        sha256 = "d2cc698a63b549a70bc047073d2949cce27cd1c7b0a4a862d08a8031bc2801db",
        strip_prefix = "num-integer-0.1.44",
        build_file = Label("//cargo/remote:BUILD.num-integer-0.1.44.bazel"),
    )

    maybe(
        http_archive,
        name = "raze__num_traits__0_2_14",
        url = "https://crates.io/api/v1/crates/num-traits/0.2.14/download",
        type = "tar.gz",
        sha256 = "9a64b1ec5cda2586e284722486d802acf1f7dbdc623e2bfc57e65ca1cd099290",
        strip_prefix = "num-traits-0.2.14",
        build_file = Label("//cargo/remote:BUILD.num-traits-0.2.14.bazel"),
    )

    maybe(
        http_archive,
        name = "raze__num_cpus__1_13_0",
        url = "https://crates.io/api/v1/crates/num_cpus/1.13.0/download",
        type = "tar.gz",
        sha256 = "05499f3756671c15885fee9034446956fff3f243d6077b91e5767df161f766b3",
        strip_prefix = "num_cpus-1.13.0",
        build_file = Label("//cargo/remote:BUILD.num_cpus-1.13.0.bazel"),
    )

    maybe(
        http_archive,
        name = "raze__once_cell__1_8_0",
        url = "https://crates.io/api/v1/crates/once_cell/1.8.0/download",
        type = "tar.gz",
        sha256 = "692fcb63b64b1758029e0a96ee63e049ce8c5948587f2f7208df04625e5f6b56",
        strip_prefix = "once_cell-1.8.0",
        build_file = Label("//cargo/remote:BUILD.once_cell-1.8.0.bazel"),
    )

    maybe(
        http_archive,
        name = "raze__opaque_debug__0_3_0",
        url = "https://crates.io/api/v1/crates/opaque-debug/0.3.0/download",
        type = "tar.gz",
        sha256 = "624a8340c38c1b80fd549087862da4ba43e08858af025b236e509b6649fc13d5",
        strip_prefix = "opaque-debug-0.3.0",
        build_file = Label("//cargo/remote:BUILD.opaque-debug-0.3.0.bazel"),
    )

    maybe(
        http_archive,
        name = "raze__openssl__0_10_35",
        url = "https://crates.io/api/v1/crates/openssl/0.10.35/download",
        type = "tar.gz",
        sha256 = "549430950c79ae24e6d02e0b7404534ecf311d94cc9f861e9e4020187d13d885",
        strip_prefix = "openssl-0.10.35",
        build_file = Label("//cargo/remote:BUILD.openssl-0.10.35.bazel"),
    )

    maybe(
        http_archive,
        name = "raze__openssl_probe__0_1_4",
        url = "https://crates.io/api/v1/crates/openssl-probe/0.1.4/download",
        type = "tar.gz",
        sha256 = "28988d872ab76095a6e6ac88d99b54fd267702734fd7ffe610ca27f533ddb95a",
        strip_prefix = "openssl-probe-0.1.4",
        build_file = Label("//cargo/remote:BUILD.openssl-probe-0.1.4.bazel"),
    )

    maybe(
        http_archive,
        name = "raze__openssl_sys__0_9_65",
        url = "https://crates.io/api/v1/crates/openssl-sys/0.9.65/download",
        type = "tar.gz",
        sha256 = "7a7907e3bfa08bb85105209cdfcb6c63d109f8f6c1ed6ca318fff5c1853fbc1d",
        strip_prefix = "openssl-sys-0.9.65",
        build_file = Label("//cargo/remote:BUILD.openssl-sys-0.9.65.bazel"),
    )

    maybe(
        http_archive,
        name = "raze__os_str_bytes__2_4_0",
        url = "https://crates.io/api/v1/crates/os_str_bytes/2.4.0/download",
        type = "tar.gz",
        sha256 = "afb2e1c3ee07430c2cf76151675e583e0f19985fa6efae47d6848a3e2c824f85",
        strip_prefix = "os_str_bytes-2.4.0",
        build_file = Label("//cargo/remote:BUILD.os_str_bytes-2.4.0.bazel"),
    )

    maybe(
        http_archive,
        name = "raze__parking_lot__0_11_1",
        url = "https://crates.io/api/v1/crates/parking_lot/0.11.1/download",
        type = "tar.gz",
        sha256 = "6d7744ac029df22dca6284efe4e898991d28e3085c706c972bcd7da4a27a15eb",
        strip_prefix = "parking_lot-0.11.1",
        build_file = Label("//cargo/remote:BUILD.parking_lot-0.11.1.bazel"),
    )

    maybe(
        http_archive,
        name = "raze__parking_lot_core__0_8_3",
        url = "https://crates.io/api/v1/crates/parking_lot_core/0.8.3/download",
        type = "tar.gz",
        sha256 = "fa7a782938e745763fe6907fc6ba86946d72f49fe7e21de074e08128a99fb018",
        strip_prefix = "parking_lot_core-0.8.3",
        build_file = Label("//cargo/remote:BUILD.parking_lot_core-0.8.3.bazel"),
    )

    maybe(
        http_archive,
        name = "raze__percent_encoding__2_1_0",
        url = "https://crates.io/api/v1/crates/percent-encoding/2.1.0/download",
        type = "tar.gz",
        sha256 = "d4fd5641d01c8f18a23da7b6fe29298ff4b55afcccdf78973b24cf3175fee32e",
        strip_prefix = "percent-encoding-2.1.0",
        build_file = Label("//cargo/remote:BUILD.percent-encoding-2.1.0.bazel"),
    )

    maybe(
        http_archive,
        name = "raze__pin_project__1_0_8",
        url = "https://crates.io/api/v1/crates/pin-project/1.0.8/download",
        type = "tar.gz",
        sha256 = "576bc800220cc65dac09e99e97b08b358cfab6e17078de8dc5fee223bd2d0c08",
        strip_prefix = "pin-project-1.0.8",
        build_file = Label("//cargo/remote:BUILD.pin-project-1.0.8.bazel"),
    )

    maybe(
        http_archive,
        name = "raze__pin_project_internal__1_0_8",
        url = "https://crates.io/api/v1/crates/pin-project-internal/1.0.8/download",
        type = "tar.gz",
        sha256 = "6e8fe8163d14ce7f0cdac2e040116f22eac817edabff0be91e8aff7e9accf389",
        strip_prefix = "pin-project-internal-1.0.8",
        build_file = Label("//cargo/remote:BUILD.pin-project-internal-1.0.8.bazel"),
    )

    maybe(
        http_archive,
        name = "raze__pin_project_lite__0_2_7",
        url = "https://crates.io/api/v1/crates/pin-project-lite/0.2.7/download",
        type = "tar.gz",
        sha256 = "8d31d11c69a6b52a174b42bdc0c30e5e11670f90788b2c471c31c1d17d449443",
        strip_prefix = "pin-project-lite-0.2.7",
        build_file = Label("//cargo/remote:BUILD.pin-project-lite-0.2.7.bazel"),
    )

    maybe(
        http_archive,
        name = "raze__pin_utils__0_1_0",
        url = "https://crates.io/api/v1/crates/pin-utils/0.1.0/download",
        type = "tar.gz",
        sha256 = "8b870d8c151b6f2fb93e84a13146138f05d02ed11c7e7c54f8826aaaf7c9f184",
        strip_prefix = "pin-utils-0.1.0",
        build_file = Label("//cargo/remote:BUILD.pin-utils-0.1.0.bazel"),
    )

    maybe(
        http_archive,
        name = "raze__pkg_config__0_3_19",
        url = "https://crates.io/api/v1/crates/pkg-config/0.3.19/download",
        type = "tar.gz",
        sha256 = "3831453b3449ceb48b6d9c7ad7c96d5ea673e9b470a1dc578c2ce6521230884c",
        strip_prefix = "pkg-config-0.3.19",
        build_file = Label("//cargo/remote:BUILD.pkg-config-0.3.19.bazel"),
    )

    maybe(
        http_archive,
        name = "raze__ppv_lite86__0_2_10",
        url = "https://crates.io/api/v1/crates/ppv-lite86/0.2.10/download",
        type = "tar.gz",
        sha256 = "ac74c624d6b2d21f425f752262f42188365d7b8ff1aff74c82e45136510a4857",
        strip_prefix = "ppv-lite86-0.2.10",
        build_file = Label("//cargo/remote:BUILD.ppv-lite86-0.2.10.bazel"),
    )

    maybe(
        http_archive,
        name = "raze__proc_macro_error__1_0_4",
        url = "https://crates.io/api/v1/crates/proc-macro-error/1.0.4/download",
        type = "tar.gz",
        sha256 = "da25490ff9892aab3fcf7c36f08cfb902dd3e71ca0f9f9517bea02a73a5ce38c",
        strip_prefix = "proc-macro-error-1.0.4",
        build_file = Label("//cargo/remote:BUILD.proc-macro-error-1.0.4.bazel"),
    )

    maybe(
        http_archive,
        name = "raze__proc_macro_error_attr__1_0_4",
        url = "https://crates.io/api/v1/crates/proc-macro-error-attr/1.0.4/download",
        type = "tar.gz",
        sha256 = "a1be40180e52ecc98ad80b184934baf3d0d29f979574e439af5a55274b35f869",
        strip_prefix = "proc-macro-error-attr-1.0.4",
        build_file = Label("//cargo/remote:BUILD.proc-macro-error-attr-1.0.4.bazel"),
    )

    maybe(
        http_archive,
        name = "raze__proc_macro_hack__0_5_19",
        url = "https://crates.io/api/v1/crates/proc-macro-hack/0.5.19/download",
        type = "tar.gz",
        sha256 = "dbf0c48bc1d91375ae5c3cd81e3722dff1abcf81a30960240640d223f59fe0e5",
        strip_prefix = "proc-macro-hack-0.5.19",
        build_file = Label("//cargo/remote:BUILD.proc-macro-hack-0.5.19.bazel"),
    )

    maybe(
        http_archive,
        name = "raze__proc_macro_nested__0_1_7",
        url = "https://crates.io/api/v1/crates/proc-macro-nested/0.1.7/download",
        type = "tar.gz",
        sha256 = "bc881b2c22681370c6a780e47af9840ef841837bc98118431d4e1868bd0c1086",
        strip_prefix = "proc-macro-nested-0.1.7",
        build_file = Label("//cargo/remote:BUILD.proc-macro-nested-0.1.7.bazel"),
    )

    maybe(
        http_archive,
        name = "raze__proc_macro2__1_0_28",
        url = "https://crates.io/api/v1/crates/proc-macro2/1.0.28/download",
        type = "tar.gz",
        sha256 = "5c7ed8b8c7b886ea3ed7dde405212185f423ab44682667c8c6dd14aa1d9f6612",
        strip_prefix = "proc-macro2-1.0.28",
        build_file = Label("//cargo/remote:BUILD.proc-macro2-1.0.28.bazel"),
    )

    maybe(
        http_archive,
        name = "raze__procfs__0_9_1",
        url = "https://crates.io/api/v1/crates/procfs/0.9.1/download",
        type = "tar.gz",
        sha256 = "ab8809e0c18450a2db0f236d2a44ec0b4c1412d0eb936233579f0990faa5d5cd",
        strip_prefix = "procfs-0.9.1",
        build_file = Label("//cargo/remote:BUILD.procfs-0.9.1.bazel"),
    )

    maybe(
        http_archive,
        name = "raze__prometheus__0_12_0",
        url = "https://crates.io/api/v1/crates/prometheus/0.12.0/download",
        type = "tar.gz",
        sha256 = "5986aa8d62380092d2f50f8b1cdba9cb9b6731ffd4b25b51fd126b6c3e05b99c",
        strip_prefix = "prometheus-0.12.0",
        build_file = Label("//cargo/remote:BUILD.prometheus-0.12.0.bazel"),
    )

    maybe(
        http_archive,
        name = "raze__protobuf__2_25_0",
        url = "https://crates.io/api/v1/crates/protobuf/2.25.0/download",
        type = "tar.gz",
        sha256 = "020f86b07722c5c4291f7c723eac4676b3892d47d9a7708dc2779696407f039b",
        strip_prefix = "protobuf-2.25.0",
        build_file = Label("//cargo/remote:BUILD.protobuf-2.25.0.bazel"),
    )

    maybe(
        http_archive,
        name = "raze__quick_error__1_2_3",
        url = "https://crates.io/api/v1/crates/quick-error/1.2.3/download",
        type = "tar.gz",
        sha256 = "a1d01941d82fa2ab50be1e79e6714289dd7cde78eba4c074bc5a4374f650dfe0",
        strip_prefix = "quick-error-1.2.3",
        build_file = Label("//cargo/remote:BUILD.quick-error-1.2.3.bazel"),
    )

    maybe(
        http_archive,
        name = "raze__quote__1_0_9",
        url = "https://crates.io/api/v1/crates/quote/1.0.9/download",
        type = "tar.gz",
        sha256 = "c3d0b9745dc2debf507c8422de05d7226cc1f0644216dfdfead988f9b1ab32a7",
        strip_prefix = "quote-1.0.9",
        build_file = Label("//cargo/remote:BUILD.quote-1.0.9.bazel"),
    )

    maybe(
        http_archive,
        name = "raze__rand__0_7_3",
        url = "https://crates.io/api/v1/crates/rand/0.7.3/download",
        type = "tar.gz",
        sha256 = "6a6b1679d49b24bbfe0c803429aa1874472f50d9b363131f0e89fc356b544d03",
        strip_prefix = "rand-0.7.3",
        build_file = Label("//cargo/remote:BUILD.rand-0.7.3.bazel"),
    )

    maybe(
        http_archive,
        name = "raze__rand__0_8_4",
        url = "https://crates.io/api/v1/crates/rand/0.8.4/download",
        type = "tar.gz",
        sha256 = "2e7573632e6454cf6b99d7aac4ccca54be06da05aca2ef7423d22d27d4d4bcd8",
        strip_prefix = "rand-0.8.4",
        build_file = Label("//cargo/remote:BUILD.rand-0.8.4.bazel"),
    )

    maybe(
        http_archive,
        name = "raze__rand_chacha__0_2_2",
        url = "https://crates.io/api/v1/crates/rand_chacha/0.2.2/download",
        type = "tar.gz",
        sha256 = "f4c8ed856279c9737206bf725bf36935d8666ead7aa69b52be55af369d193402",
        strip_prefix = "rand_chacha-0.2.2",
        build_file = Label("//cargo/remote:BUILD.rand_chacha-0.2.2.bazel"),
    )

    maybe(
        http_archive,
        name = "raze__rand_chacha__0_3_1",
        url = "https://crates.io/api/v1/crates/rand_chacha/0.3.1/download",
        type = "tar.gz",
        sha256 = "e6c10a63a0fa32252be49d21e7709d4d4baf8d231c2dbce1eaa8141b9b127d88",
        strip_prefix = "rand_chacha-0.3.1",
        build_file = Label("//cargo/remote:BUILD.rand_chacha-0.3.1.bazel"),
    )

    maybe(
        http_archive,
        name = "raze__rand_core__0_5_1",
        url = "https://crates.io/api/v1/crates/rand_core/0.5.1/download",
        type = "tar.gz",
        sha256 = "90bde5296fc891b0cef12a6d03ddccc162ce7b2aff54160af9338f8d40df6d19",
        strip_prefix = "rand_core-0.5.1",
        build_file = Label("//cargo/remote:BUILD.rand_core-0.5.1.bazel"),
    )

    maybe(
        http_archive,
        name = "raze__rand_core__0_6_3",
        url = "https://crates.io/api/v1/crates/rand_core/0.6.3/download",
        type = "tar.gz",
        sha256 = "d34f1408f55294453790c48b2f1ebbb1c5b4b7563eb1f418bcfcfdbb06ebb4e7",
        strip_prefix = "rand_core-0.6.3",
        build_file = Label("//cargo/remote:BUILD.rand_core-0.6.3.bazel"),
    )

    maybe(
        http_archive,
        name = "raze__rand_hc__0_2_0",
        url = "https://crates.io/api/v1/crates/rand_hc/0.2.0/download",
        type = "tar.gz",
        sha256 = "ca3129af7b92a17112d59ad498c6f81eaf463253766b90396d39ea7a39d6613c",
        strip_prefix = "rand_hc-0.2.0",
        build_file = Label("//cargo/remote:BUILD.rand_hc-0.2.0.bazel"),
    )

    maybe(
        http_archive,
        name = "raze__rand_hc__0_3_1",
        url = "https://crates.io/api/v1/crates/rand_hc/0.3.1/download",
        type = "tar.gz",
        sha256 = "d51e9f596de227fda2ea6c84607f5558e196eeaf43c986b724ba4fb8fdf497e7",
        strip_prefix = "rand_hc-0.3.1",
        build_file = Label("//cargo/remote:BUILD.rand_hc-0.3.1.bazel"),
    )

    maybe(
        http_archive,
        name = "raze__redox_syscall__0_2_10",
        url = "https://crates.io/api/v1/crates/redox_syscall/0.2.10/download",
        type = "tar.gz",
        sha256 = "8383f39639269cde97d255a32bdb68c047337295414940c68bdd30c2e13203ff",
        strip_prefix = "redox_syscall-0.2.10",
        build_file = Label("//cargo/remote:BUILD.redox_syscall-0.2.10.bazel"),
    )

    maybe(
        http_archive,
        name = "raze__regex__1_5_4",
        url = "https://crates.io/api/v1/crates/regex/1.5.4/download",
        type = "tar.gz",
        sha256 = "d07a8629359eb56f1e2fb1652bb04212c072a87ba68546a04065d525673ac461",
        strip_prefix = "regex-1.5.4",
        build_file = Label("//cargo/remote:BUILD.regex-1.5.4.bazel"),
    )

    maybe(
        http_archive,
        name = "raze__regex_automata__0_1_10",
        url = "https://crates.io/api/v1/crates/regex-automata/0.1.10/download",
        type = "tar.gz",
        sha256 = "6c230d73fb8d8c1b9c0b3135c5142a8acee3a0558fb8db5cf1cb65f8d7862132",
        strip_prefix = "regex-automata-0.1.10",
        build_file = Label("//cargo/remote:BUILD.regex-automata-0.1.10.bazel"),
    )

    maybe(
        http_archive,
        name = "raze__regex_syntax__0_6_25",
        url = "https://crates.io/api/v1/crates/regex-syntax/0.6.25/download",
        type = "tar.gz",
        sha256 = "f497285884f3fcff424ffc933e56d7cbca511def0c9831a7f9b5f6153e3cc89b",
        strip_prefix = "regex-syntax-0.6.25",
        build_file = Label("//cargo/remote:BUILD.regex-syntax-0.6.25.bazel"),
    )

    maybe(
        http_archive,
        name = "raze__remove_dir_all__0_5_3",
        url = "https://crates.io/api/v1/crates/remove_dir_all/0.5.3/download",
        type = "tar.gz",
        sha256 = "3acd125665422973a33ac9d3dd2df85edad0f4ae9b00dafb1a05e43a9f5ef8e7",
        strip_prefix = "remove_dir_all-0.5.3",
        build_file = Label("//cargo/remote:BUILD.remove_dir_all-0.5.3.bazel"),
    )

    maybe(
        http_archive,
        name = "raze__reqwest__0_11_4",
        url = "https://crates.io/api/v1/crates/reqwest/0.11.4/download",
        type = "tar.gz",
        sha256 = "246e9f61b9bb77df069a947682be06e31ac43ea37862e244a69f177694ea6d22",
        strip_prefix = "reqwest-0.11.4",
        build_file = Label("//cargo/remote:BUILD.reqwest-0.11.4.bazel"),
    )

    maybe(
        http_archive,
        name = "raze__ryu__1_0_5",
        url = "https://crates.io/api/v1/crates/ryu/1.0.5/download",
        type = "tar.gz",
        sha256 = "71d301d4193d031abdd79ff7e3dd721168a9572ef3fe51a1517aba235bd8f86e",
        strip_prefix = "ryu-1.0.5",
        build_file = Label("//cargo/remote:BUILD.ryu-1.0.5.bazel"),
    )

    maybe(
        http_archive,
        name = "raze__safemem__0_3_3",
        url = "https://crates.io/api/v1/crates/safemem/0.3.3/download",
        type = "tar.gz",
        sha256 = "ef703b7cb59335eae2eb93ceb664c0eb7ea6bf567079d843e09420219668e072",
        strip_prefix = "safemem-0.3.3",
        build_file = Label("//cargo/remote:BUILD.safemem-0.3.3.bazel"),
    )

    maybe(
        http_archive,
        name = "raze__schannel__0_1_19",
        url = "https://crates.io/api/v1/crates/schannel/0.1.19/download",
        type = "tar.gz",
        sha256 = "8f05ba609c234e60bee0d547fe94a4c7e9da733d1c962cf6e59efa4cd9c8bc75",
        strip_prefix = "schannel-0.1.19",
        build_file = Label("//cargo/remote:BUILD.schannel-0.1.19.bazel"),
    )

    maybe(
        http_archive,
        name = "raze__scoped_tls__1_0_0",
        url = "https://crates.io/api/v1/crates/scoped-tls/1.0.0/download",
        type = "tar.gz",
        sha256 = "ea6a9290e3c9cf0f18145ef7ffa62d68ee0bf5fcd651017e586dc7fd5da448c2",
        strip_prefix = "scoped-tls-1.0.0",
        build_file = Label("//cargo/remote:BUILD.scoped-tls-1.0.0.bazel"),
    )

    maybe(
        http_archive,
        name = "raze__scopeguard__1_1_0",
        url = "https://crates.io/api/v1/crates/scopeguard/1.1.0/download",
        type = "tar.gz",
        sha256 = "d29ab0c6d3fc0ee92fe66e2d99f700eab17a8d57d1c1d3b748380fb20baa78cd",
        strip_prefix = "scopeguard-1.1.0",
        build_file = Label("//cargo/remote:BUILD.scopeguard-1.1.0.bazel"),
    )

    maybe(
        http_archive,
        name = "raze__security_framework__2_3_1",
        url = "https://crates.io/api/v1/crates/security-framework/2.3.1/download",
        type = "tar.gz",
        sha256 = "23a2ac85147a3a11d77ecf1bc7166ec0b92febfa4461c37944e180f319ece467",
        strip_prefix = "security-framework-2.3.1",
        build_file = Label("//cargo/remote:BUILD.security-framework-2.3.1.bazel"),
    )

    maybe(
        http_archive,
        name = "raze__security_framework_sys__2_3_0",
        url = "https://crates.io/api/v1/crates/security-framework-sys/2.3.0/download",
        type = "tar.gz",
        sha256 = "7e4effb91b4b8b6fb7732e670b6cee160278ff8e6bf485c7805d9e319d76e284",
        strip_prefix = "security-framework-sys-2.3.0",
        build_file = Label("//cargo/remote:BUILD.security-framework-sys-2.3.0.bazel"),
    )

    maybe(
        http_archive,
        name = "raze__serde__1_0_127",
        url = "https://crates.io/api/v1/crates/serde/1.0.127/download",
        type = "tar.gz",
        sha256 = "f03b9878abf6d14e6779d3f24f07b2cfa90352cfec4acc5aab8f1ac7f146fae8",
        strip_prefix = "serde-1.0.127",
        build_file = Label("//cargo/remote:BUILD.serde-1.0.127.bazel"),
    )

    maybe(
        http_archive,
        name = "raze__serde_derive__1_0_127",
        url = "https://crates.io/api/v1/crates/serde_derive/1.0.127/download",
        type = "tar.gz",
        sha256 = "a024926d3432516606328597e0f224a51355a493b49fdd67e9209187cbe55ecc",
        strip_prefix = "serde_derive-1.0.127",
        build_file = Label("//cargo/remote:BUILD.serde_derive-1.0.127.bazel"),
    )

    maybe(
        http_archive,
        name = "raze__serde_json__1_0_66",
        url = "https://crates.io/api/v1/crates/serde_json/1.0.66/download",
        type = "tar.gz",
        sha256 = "336b10da19a12ad094b59d870ebde26a45402e5b470add4b5fd03c5048a32127",
        strip_prefix = "serde_json-1.0.66",
        build_file = Label("//cargo/remote:BUILD.serde_json-1.0.66.bazel"),
    )

    maybe(
        http_archive,
        name = "raze__serde_urlencoded__0_7_0",
        url = "https://crates.io/api/v1/crates/serde_urlencoded/0.7.0/download",
        type = "tar.gz",
        sha256 = "edfa57a7f8d9c1d260a549e7224100f6c43d43f9103e06dd8b4095a9b2b43ce9",
        strip_prefix = "serde_urlencoded-0.7.0",
        build_file = Label("//cargo/remote:BUILD.serde_urlencoded-0.7.0.bazel"),
    )

    maybe(
        http_archive,
        name = "raze__serde_yaml__0_8_17",
        url = "https://crates.io/api/v1/crates/serde_yaml/0.8.17/download",
        type = "tar.gz",
        sha256 = "15654ed4ab61726bf918a39cb8d98a2e2995b002387807fa6ba58fdf7f59bb23",
        strip_prefix = "serde_yaml-0.8.17",
        build_file = Label("//cargo/remote:BUILD.serde_yaml-0.8.17.bazel"),
    )

    maybe(
        http_archive,
        name = "raze__sha_1__0_9_7",
        url = "https://crates.io/api/v1/crates/sha-1/0.9.7/download",
        type = "tar.gz",
        sha256 = "1a0c8611594e2ab4ebbf06ec7cbbf0a99450b8570e96cbf5188b5d5f6ef18d81",
        strip_prefix = "sha-1-0.9.7",
        build_file = Label("//cargo/remote:BUILD.sha-1-0.9.7.bazel"),
    )

    maybe(
        http_archive,
        name = "raze__sharded_slab__0_1_3",
        url = "https://crates.io/api/v1/crates/sharded-slab/0.1.3/download",
        type = "tar.gz",
        sha256 = "740223c51853f3145fe7c90360d2d4232f2b62e3449489c207eccde818979982",
        strip_prefix = "sharded-slab-0.1.3",
        build_file = Label("//cargo/remote:BUILD.sharded-slab-0.1.3.bazel"),
    )

    maybe(
        http_archive,
        name = "raze__signal_hook_registry__1_4_0",
        url = "https://crates.io/api/v1/crates/signal-hook-registry/1.4.0/download",
        type = "tar.gz",
        sha256 = "e51e73328dc4ac0c7ccbda3a494dfa03df1de2f46018127f60c693f2648455b0",
        strip_prefix = "signal-hook-registry-1.4.0",
        build_file = Label("//cargo/remote:BUILD.signal-hook-registry-1.4.0.bazel"),
    )

    maybe(
        http_archive,
        name = "raze__slab__0_4_4",
        url = "https://crates.io/api/v1/crates/slab/0.4.4/download",
        type = "tar.gz",
        sha256 = "c307a32c1c5c437f38c7fd45d753050587732ba8628319fbdf12a7e289ccc590",
        strip_prefix = "slab-0.4.4",
        build_file = Label("//cargo/remote:BUILD.slab-0.4.4.bazel"),
    )

    maybe(
        http_archive,
        name = "raze__smallvec__1_6_1",
        url = "https://crates.io/api/v1/crates/smallvec/1.6.1/download",
        type = "tar.gz",
        sha256 = "fe0f37c9e8f3c5a4a66ad655a93c74daac4ad00c441533bf5c6e7990bb42604e",
        strip_prefix = "smallvec-1.6.1",
        build_file = Label("//cargo/remote:BUILD.smallvec-1.6.1.bazel"),
    )

    maybe(
        http_archive,
        name = "raze__socket2__0_4_1",
        url = "https://crates.io/api/v1/crates/socket2/0.4.1/download",
        type = "tar.gz",
        sha256 = "765f090f0e423d2b55843402a07915add955e7d60657db13707a159727326cad",
        strip_prefix = "socket2-0.4.1",
        build_file = Label("//cargo/remote:BUILD.socket2-0.4.1.bazel"),
    )

    maybe(
        http_archive,
        name = "raze__strsim__0_10_0",
        url = "https://crates.io/api/v1/crates/strsim/0.10.0/download",
        type = "tar.gz",
        sha256 = "73473c0e59e6d5812c5dfe2a064a6444949f089e20eec9a2e5506596494e4623",
        strip_prefix = "strsim-0.10.0",
        build_file = Label("//cargo/remote:BUILD.strsim-0.10.0.bazel"),
    )

    maybe(
        http_archive,
        name = "raze__syn__1_0_74",
        url = "https://crates.io/api/v1/crates/syn/1.0.74/download",
        type = "tar.gz",
        sha256 = "1873d832550d4588c3dbc20f01361ab00bfe741048f71e3fecf145a7cc18b29c",
        strip_prefix = "syn-1.0.74",
        build_file = Label("//cargo/remote:BUILD.syn-1.0.74.bazel"),
    )

    maybe(
        http_archive,
        name = "raze__tempfile__3_2_0",
        url = "https://crates.io/api/v1/crates/tempfile/3.2.0/download",
        type = "tar.gz",
        sha256 = "dac1c663cfc93810f88aed9b8941d48cabf856a1b111c29a40439018d870eb22",
        strip_prefix = "tempfile-3.2.0",
        build_file = Label("//cargo/remote:BUILD.tempfile-3.2.0.bazel"),
    )

    maybe(
        http_archive,
        name = "raze__termcolor__1_1_2",
        url = "https://crates.io/api/v1/crates/termcolor/1.1.2/download",
        type = "tar.gz",
        sha256 = "2dfed899f0eb03f32ee8c6a0aabdb8a7949659e3466561fc0adf54e26d88c5f4",
        strip_prefix = "termcolor-1.1.2",
        build_file = Label("//cargo/remote:BUILD.termcolor-1.1.2.bazel"),
    )

    maybe(
        http_archive,
        name = "raze__textwrap__0_12_1",
        url = "https://crates.io/api/v1/crates/textwrap/0.12.1/download",
        type = "tar.gz",
        sha256 = "203008d98caf094106cfaba70acfed15e18ed3ddb7d94e49baec153a2b462789",
        strip_prefix = "textwrap-0.12.1",
        build_file = Label("//cargo/remote:BUILD.textwrap-0.12.1.bazel"),
    )

    maybe(
        http_archive,
        name = "raze__thiserror__1_0_26",
        url = "https://crates.io/api/v1/crates/thiserror/1.0.26/download",
        type = "tar.gz",
        sha256 = "93119e4feac1cbe6c798c34d3a53ea0026b0b1de6a120deef895137c0529bfe2",
        strip_prefix = "thiserror-1.0.26",
        build_file = Label("//cargo/remote:BUILD.thiserror-1.0.26.bazel"),
    )

    maybe(
        http_archive,
        name = "raze__thiserror_impl__1_0_26",
        url = "https://crates.io/api/v1/crates/thiserror-impl/1.0.26/download",
        type = "tar.gz",
        sha256 = "060d69a0afe7796bf42e9e2ff91f5ee691fb15c53d38b4b62a9a53eb23164745",
        strip_prefix = "thiserror-impl-1.0.26",
        build_file = Label("//cargo/remote:BUILD.thiserror-impl-1.0.26.bazel"),
    )

    maybe(
        http_archive,
        name = "raze__thread_local__1_1_3",
        url = "https://crates.io/api/v1/crates/thread_local/1.1.3/download",
        type = "tar.gz",
        sha256 = "8018d24e04c95ac8790716a5987d0fec4f8b27249ffa0f7d33f1369bdfb88cbd",
        strip_prefix = "thread_local-1.1.3",
        build_file = Label("//cargo/remote:BUILD.thread_local-1.1.3.bazel"),
    )

    maybe(
        http_archive,
        name = "raze__time__0_1_43",
        url = "https://crates.io/api/v1/crates/time/0.1.43/download",
        type = "tar.gz",
        sha256 = "ca8a50ef2360fbd1eeb0ecd46795a87a19024eb4b53c5dc916ca1fd95fe62438",
        strip_prefix = "time-0.1.43",
        build_file = Label("//cargo/remote:BUILD.time-0.1.43.bazel"),
    )

    maybe(
        http_archive,
        name = "raze__tinyvec__1_3_1",
        url = "https://crates.io/api/v1/crates/tinyvec/1.3.1/download",
        type = "tar.gz",
        sha256 = "848a1e1181b9f6753b5e96a092749e29b11d19ede67dfbbd6c7dc7e0f49b5338",
        strip_prefix = "tinyvec-1.3.1",
        build_file = Label("//cargo/remote:BUILD.tinyvec-1.3.1.bazel"),
    )

    maybe(
        http_archive,
        name = "raze__tinyvec_macros__0_1_0",
        url = "https://crates.io/api/v1/crates/tinyvec_macros/0.1.0/download",
        type = "tar.gz",
        sha256 = "cda74da7e1a664f795bb1f8a87ec406fb89a02522cf6e50620d016add6dbbf5c",
        strip_prefix = "tinyvec_macros-0.1.0",
        build_file = Label("//cargo/remote:BUILD.tinyvec_macros-0.1.0.bazel"),
    )

    maybe(
        http_archive,
        name = "raze__tokio__1_9_0",
        url = "https://crates.io/api/v1/crates/tokio/1.9.0/download",
        type = "tar.gz",
        sha256 = "4b7b349f11a7047e6d1276853e612d152f5e8a352c61917887cc2169e2366b4c",
        strip_prefix = "tokio-1.9.0",
        build_file = Label("//cargo/remote:BUILD.tokio-1.9.0.bazel"),
    )

    maybe(
        http_archive,
        name = "raze__tokio_macros__1_3_0",
        url = "https://crates.io/api/v1/crates/tokio-macros/1.3.0/download",
        type = "tar.gz",
        sha256 = "54473be61f4ebe4efd09cec9bd5d16fa51d70ea0192213d754d2d500457db110",
        strip_prefix = "tokio-macros-1.3.0",
        build_file = Label("//cargo/remote:BUILD.tokio-macros-1.3.0.bazel"),
    )

    maybe(
        http_archive,
        name = "raze__tokio_native_tls__0_3_0",
        url = "https://crates.io/api/v1/crates/tokio-native-tls/0.3.0/download",
        type = "tar.gz",
        sha256 = "f7d995660bd2b7f8c1568414c1126076c13fbb725c40112dc0120b78eb9b717b",
        strip_prefix = "tokio-native-tls-0.3.0",
        build_file = Label("//cargo/remote:BUILD.tokio-native-tls-0.3.0.bazel"),
    )

    maybe(
        http_archive,
        name = "raze__tokio_stream__0_1_7",
        url = "https://crates.io/api/v1/crates/tokio-stream/0.1.7/download",
        type = "tar.gz",
        sha256 = "7b2f3f698253f03119ac0102beaa64f67a67e08074d03a22d18784104543727f",
        strip_prefix = "tokio-stream-0.1.7",
        build_file = Label("//cargo/remote:BUILD.tokio-stream-0.1.7.bazel"),
    )

    maybe(
        http_archive,
        name = "raze__tokio_tungstenite__0_13_0",
        url = "https://crates.io/api/v1/crates/tokio-tungstenite/0.13.0/download",
        type = "tar.gz",
        sha256 = "e1a5f475f1b9d077ea1017ecbc60890fda8e54942d680ca0b1d2b47cfa2d861b",
        strip_prefix = "tokio-tungstenite-0.13.0",
        build_file = Label("//cargo/remote:BUILD.tokio-tungstenite-0.13.0.bazel"),
    )

    maybe(
        http_archive,
        name = "raze__tokio_util__0_6_7",
        url = "https://crates.io/api/v1/crates/tokio-util/0.6.7/download",
        type = "tar.gz",
        sha256 = "1caa0b0c8d94a049db56b5acf8cba99dc0623aab1b26d5b5f5e2d945846b3592",
        strip_prefix = "tokio-util-0.6.7",
        build_file = Label("//cargo/remote:BUILD.tokio-util-0.6.7.bazel"),
    )

    maybe(
        http_archive,
        name = "raze__tower_service__0_3_1",
        url = "https://crates.io/api/v1/crates/tower-service/0.3.1/download",
        type = "tar.gz",
        sha256 = "360dfd1d6d30e05fda32ace2c8c70e9c0a9da713275777f5a4dbb8a1893930c6",
        strip_prefix = "tower-service-0.3.1",
        build_file = Label("//cargo/remote:BUILD.tower-service-0.3.1.bazel"),
    )

    maybe(
        http_archive,
        name = "raze__tracing__0_1_26",
        url = "https://crates.io/api/v1/crates/tracing/0.1.26/download",
        type = "tar.gz",
        sha256 = "09adeb8c97449311ccd28a427f96fb563e7fd31aabf994189879d9da2394b89d",
        strip_prefix = "tracing-0.1.26",
        build_file = Label("//cargo/remote:BUILD.tracing-0.1.26.bazel"),
    )

    maybe(
        http_archive,
        name = "raze__tracing_attributes__0_1_15",
        url = "https://crates.io/api/v1/crates/tracing-attributes/0.1.15/download",
        type = "tar.gz",
        sha256 = "c42e6fa53307c8a17e4ccd4dc81cf5ec38db9209f59b222210375b54ee40d1e2",
        strip_prefix = "tracing-attributes-0.1.15",
        build_file = Label("//cargo/remote:BUILD.tracing-attributes-0.1.15.bazel"),
    )

    maybe(
        http_archive,
        name = "raze__tracing_core__0_1_18",
        url = "https://crates.io/api/v1/crates/tracing-core/0.1.18/download",
        type = "tar.gz",
        sha256 = "a9ff14f98b1a4b289c6248a023c1c2fa1491062964e9fed67ab29c4e4da4a052",
        strip_prefix = "tracing-core-0.1.18",
        build_file = Label("//cargo/remote:BUILD.tracing-core-0.1.18.bazel"),
    )

    maybe(
        http_archive,
        name = "raze__tracing_log__0_1_2",
        url = "https://crates.io/api/v1/crates/tracing-log/0.1.2/download",
        type = "tar.gz",
        sha256 = "a6923477a48e41c1951f1999ef8bb5a3023eb723ceadafe78ffb65dc366761e3",
        strip_prefix = "tracing-log-0.1.2",
        build_file = Label("//cargo/remote:BUILD.tracing-log-0.1.2.bazel"),
    )

    maybe(
        http_archive,
        name = "raze__tracing_serde__0_1_2",
        url = "https://crates.io/api/v1/crates/tracing-serde/0.1.2/download",
        type = "tar.gz",
        sha256 = "fb65ea441fbb84f9f6748fd496cf7f63ec9af5bca94dd86456978d055e8eb28b",
        strip_prefix = "tracing-serde-0.1.2",
        build_file = Label("//cargo/remote:BUILD.tracing-serde-0.1.2.bazel"),
    )

    maybe(
        http_archive,
        name = "raze__tracing_subscriber__0_2_19",
        url = "https://crates.io/api/v1/crates/tracing-subscriber/0.2.19/download",
        type = "tar.gz",
        sha256 = "ab69019741fca4d98be3c62d2b75254528b5432233fd8a4d2739fec20278de48",
        strip_prefix = "tracing-subscriber-0.2.19",
        build_file = Label("//cargo/remote:BUILD.tracing-subscriber-0.2.19.bazel"),
    )

    maybe(
        http_archive,
        name = "raze__try_lock__0_2_3",
        url = "https://crates.io/api/v1/crates/try-lock/0.2.3/download",
        type = "tar.gz",
        sha256 = "59547bce71d9c38b83d9c0e92b6066c4253371f15005def0c30d9657f50c7642",
        strip_prefix = "try-lock-0.2.3",
        build_file = Label("//cargo/remote:BUILD.try-lock-0.2.3.bazel"),
    )

    maybe(
        http_archive,
        name = "raze__tungstenite__0_12_0",
        url = "https://crates.io/api/v1/crates/tungstenite/0.12.0/download",
        type = "tar.gz",
        sha256 = "8ada8297e8d70872fa9a551d93250a9f407beb9f37ef86494eb20012a2ff7c24",
        strip_prefix = "tungstenite-0.12.0",
        build_file = Label("//cargo/remote:BUILD.tungstenite-0.12.0.bazel"),
    )

    maybe(
        http_archive,
        name = "raze__twoway__0_1_8",
        url = "https://crates.io/api/v1/crates/twoway/0.1.8/download",
        type = "tar.gz",
        sha256 = "59b11b2b5241ba34be09c3cc85a36e56e48f9888862e19cedf23336d35316ed1",
        strip_prefix = "twoway-0.1.8",
        build_file = Label("//cargo/remote:BUILD.twoway-0.1.8.bazel"),
    )

    maybe(
        http_archive,
        name = "raze__typenum__1_13_0",
        url = "https://crates.io/api/v1/crates/typenum/1.13.0/download",
        type = "tar.gz",
        sha256 = "879f6906492a7cd215bfa4cf595b600146ccfac0c79bcbd1f3000162af5e8b06",
        strip_prefix = "typenum-1.13.0",
        build_file = Label("//cargo/remote:BUILD.typenum-1.13.0.bazel"),
    )

    maybe(
        http_archive,
        name = "raze__unicase__2_6_0",
        url = "https://crates.io/api/v1/crates/unicase/2.6.0/download",
        type = "tar.gz",
        sha256 = "50f37be617794602aabbeee0be4f259dc1778fabe05e2d67ee8f79326d5cb4f6",
        strip_prefix = "unicase-2.6.0",
        build_file = Label("//cargo/remote:BUILD.unicase-2.6.0.bazel"),
    )

    maybe(
        http_archive,
        name = "raze__unicode_bidi__0_3_5",
        url = "https://crates.io/api/v1/crates/unicode-bidi/0.3.5/download",
        type = "tar.gz",
        sha256 = "eeb8be209bb1c96b7c177c7420d26e04eccacb0eeae6b980e35fcb74678107e0",
        strip_prefix = "unicode-bidi-0.3.5",
        build_file = Label("//cargo/remote:BUILD.unicode-bidi-0.3.5.bazel"),
    )

    maybe(
        http_archive,
        name = "raze__unicode_normalization__0_1_19",
        url = "https://crates.io/api/v1/crates/unicode-normalization/0.1.19/download",
        type = "tar.gz",
        sha256 = "d54590932941a9e9266f0832deed84ebe1bf2e4c9e4a3554d393d18f5e854bf9",
        strip_prefix = "unicode-normalization-0.1.19",
        build_file = Label("//cargo/remote:BUILD.unicode-normalization-0.1.19.bazel"),
    )

    maybe(
        http_archive,
        name = "raze__unicode_segmentation__1_8_0",
        url = "https://crates.io/api/v1/crates/unicode-segmentation/1.8.0/download",
        type = "tar.gz",
        sha256 = "8895849a949e7845e06bd6dc1aa51731a103c42707010a5b591c0038fb73385b",
        strip_prefix = "unicode-segmentation-1.8.0",
        build_file = Label("//cargo/remote:BUILD.unicode-segmentation-1.8.0.bazel"),
    )

    maybe(
        http_archive,
        name = "raze__unicode_width__0_1_8",
        url = "https://crates.io/api/v1/crates/unicode-width/0.1.8/download",
        type = "tar.gz",
        sha256 = "9337591893a19b88d8d87f2cec1e73fad5cdfd10e5a6f349f498ad6ea2ffb1e3",
        strip_prefix = "unicode-width-0.1.8",
        build_file = Label("//cargo/remote:BUILD.unicode-width-0.1.8.bazel"),
    )

    maybe(
        http_archive,
        name = "raze__unicode_xid__0_2_2",
        url = "https://crates.io/api/v1/crates/unicode-xid/0.2.2/download",
        type = "tar.gz",
        sha256 = "8ccb82d61f80a663efe1f787a51b16b5a51e3314d6ac365b08639f52387b33f3",
        strip_prefix = "unicode-xid-0.2.2",
        build_file = Label("//cargo/remote:BUILD.unicode-xid-0.2.2.bazel"),
    )

    maybe(
        http_archive,
        name = "raze__url__2_2_2",
        url = "https://crates.io/api/v1/crates/url/2.2.2/download",
        type = "tar.gz",
        sha256 = "a507c383b2d33b5fc35d1861e77e6b383d158b2da5e14fe51b83dfedf6fd578c",
        strip_prefix = "url-2.2.2",
        build_file = Label("//cargo/remote:BUILD.url-2.2.2.bazel"),
    )

    maybe(
        http_archive,
        name = "raze__utf_8__0_7_6",
        url = "https://crates.io/api/v1/crates/utf-8/0.7.6/download",
        type = "tar.gz",
        sha256 = "09cc8ee72d2a9becf2f2febe0205bbed8fc6615b7cb429ad062dc7b7ddd036a9",
        strip_prefix = "utf-8-0.7.6",
        build_file = Label("//cargo/remote:BUILD.utf-8-0.7.6.bazel"),
    )

    maybe(
        http_archive,
        name = "raze__vcpkg__0_2_15",
        url = "https://crates.io/api/v1/crates/vcpkg/0.2.15/download",
        type = "tar.gz",
        sha256 = "accd4ea62f7bb7a82fe23066fb0957d48ef677f6eeb8215f372f52e48bb32426",
        strip_prefix = "vcpkg-0.2.15",
        build_file = Label("//cargo/remote:BUILD.vcpkg-0.2.15.bazel"),
    )

    maybe(
        http_archive,
        name = "raze__vec_map__0_8_2",
        url = "https://crates.io/api/v1/crates/vec_map/0.8.2/download",
        type = "tar.gz",
        sha256 = "f1bddf1187be692e79c5ffeab891132dfb0f236ed36a43c7ed39f1165ee20191",
        strip_prefix = "vec_map-0.8.2",
        build_file = Label("//cargo/remote:BUILD.vec_map-0.8.2.bazel"),
    )

    maybe(
        http_archive,
        name = "raze__version_check__0_9_3",
        url = "https://crates.io/api/v1/crates/version_check/0.9.3/download",
        type = "tar.gz",
        sha256 = "5fecdca9a5291cc2b8dcf7dc02453fee791a280f3743cb0905f8822ae463b3fe",
        strip_prefix = "version_check-0.9.3",
        build_file = Label("//cargo/remote:BUILD.version_check-0.9.3.bazel"),
    )

    maybe(
        http_archive,
        name = "raze__want__0_3_0",
        url = "https://crates.io/api/v1/crates/want/0.3.0/download",
        type = "tar.gz",
        sha256 = "1ce8a968cb1cd110d136ff8b819a556d6fb6d919363c61534f6860c7eb172ba0",
        strip_prefix = "want-0.3.0",
        build_file = Label("//cargo/remote:BUILD.want-0.3.0.bazel"),
    )

    maybe(
        http_archive,
        name = "raze__warp__0_3_1",
        url = "https://crates.io/api/v1/crates/warp/0.3.1/download",
        type = "tar.gz",
        sha256 = "332d47745e9a0c38636dbd454729b147d16bd1ed08ae67b3ab281c4506771054",
        strip_prefix = "warp-0.3.1",
        build_file = Label("//cargo/remote:BUILD.warp-0.3.1.bazel"),
    )

    maybe(
        http_archive,
        name = "raze__wasi__0_10_2_wasi_snapshot_preview1",
        url = "https://crates.io/api/v1/crates/wasi/0.10.2+wasi-snapshot-preview1/download",
        type = "tar.gz",
        sha256 = "fd6fbd9a79829dd1ad0cc20627bf1ed606756a7f77edff7b66b7064f9cb327c6",
        strip_prefix = "wasi-0.10.2+wasi-snapshot-preview1",
        build_file = Label("//cargo/remote:BUILD.wasi-0.10.2+wasi-snapshot-preview1.bazel"),
    )

    maybe(
        http_archive,
        name = "raze__wasi__0_9_0_wasi_snapshot_preview1",
        url = "https://crates.io/api/v1/crates/wasi/0.9.0+wasi-snapshot-preview1/download",
        type = "tar.gz",
        sha256 = "cccddf32554fecc6acb585f82a32a72e28b48f8c4c1883ddfeeeaa96f7d8e519",
        strip_prefix = "wasi-0.9.0+wasi-snapshot-preview1",
        build_file = Label("//cargo/remote:BUILD.wasi-0.9.0+wasi-snapshot-preview1.bazel"),
    )

    maybe(
        http_archive,
        name = "raze__wasm_bindgen__0_2_75",
        url = "https://crates.io/api/v1/crates/wasm-bindgen/0.2.75/download",
        type = "tar.gz",
        sha256 = "b608ecc8f4198fe8680e2ed18eccab5f0cd4caaf3d83516fa5fb2e927fda2586",
        strip_prefix = "wasm-bindgen-0.2.75",
        build_file = Label("//cargo/remote:BUILD.wasm-bindgen-0.2.75.bazel"),
    )

    maybe(
        http_archive,
        name = "raze__wasm_bindgen_backend__0_2_75",
        url = "https://crates.io/api/v1/crates/wasm-bindgen-backend/0.2.75/download",
        type = "tar.gz",
        sha256 = "580aa3a91a63d23aac5b6b267e2d13cb4f363e31dce6c352fca4752ae12e479f",
        strip_prefix = "wasm-bindgen-backend-0.2.75",
        build_file = Label("//cargo/remote:BUILD.wasm-bindgen-backend-0.2.75.bazel"),
    )

    maybe(
        http_archive,
        name = "raze__wasm_bindgen_futures__0_4_25",
        url = "https://crates.io/api/v1/crates/wasm-bindgen-futures/0.4.25/download",
        type = "tar.gz",
        sha256 = "16646b21c3add8e13fdb8f20172f8a28c3dbf62f45406bcff0233188226cfe0c",
        strip_prefix = "wasm-bindgen-futures-0.4.25",
        build_file = Label("//cargo/remote:BUILD.wasm-bindgen-futures-0.4.25.bazel"),
    )

    maybe(
        http_archive,
        name = "raze__wasm_bindgen_macro__0_2_75",
        url = "https://crates.io/api/v1/crates/wasm-bindgen-macro/0.2.75/download",
        type = "tar.gz",
        sha256 = "171ebf0ed9e1458810dfcb31f2e766ad6b3a89dbda42d8901f2b268277e5f09c",
        strip_prefix = "wasm-bindgen-macro-0.2.75",
        build_file = Label("//cargo/remote:BUILD.wasm-bindgen-macro-0.2.75.bazel"),
    )

    maybe(
        http_archive,
        name = "raze__wasm_bindgen_macro_support__0_2_75",
        url = "https://crates.io/api/v1/crates/wasm-bindgen-macro-support/0.2.75/download",
        type = "tar.gz",
        sha256 = "6c2657dd393f03aa2a659c25c6ae18a13a4048cebd220e147933ea837efc589f",
        strip_prefix = "wasm-bindgen-macro-support-0.2.75",
        build_file = Label("//cargo/remote:BUILD.wasm-bindgen-macro-support-0.2.75.bazel"),
    )

    maybe(
        http_archive,
        name = "raze__wasm_bindgen_shared__0_2_75",
        url = "https://crates.io/api/v1/crates/wasm-bindgen-shared/0.2.75/download",
        type = "tar.gz",
        sha256 = "2e0c4a743a309662d45f4ede961d7afa4ba4131a59a639f29b0069c3798bbcc2",
        strip_prefix = "wasm-bindgen-shared-0.2.75",
        build_file = Label("//cargo/remote:BUILD.wasm-bindgen-shared-0.2.75.bazel"),
    )

    maybe(
        http_archive,
        name = "raze__web_sys__0_3_52",
        url = "https://crates.io/api/v1/crates/web-sys/0.3.52/download",
        type = "tar.gz",
        sha256 = "01c70a82d842c9979078c772d4a1344685045f1a5628f677c2b2eab4dd7d2696",
        strip_prefix = "web-sys-0.3.52",
        build_file = Label("//cargo/remote:BUILD.web-sys-0.3.52.bazel"),
    )

    maybe(
        http_archive,
        name = "raze__winapi__0_3_9",
        url = "https://crates.io/api/v1/crates/winapi/0.3.9/download",
        type = "tar.gz",
        sha256 = "5c839a674fcd7a98952e593242ea400abe93992746761e38641405d28b00f419",
        strip_prefix = "winapi-0.3.9",
        build_file = Label("//cargo/remote:BUILD.winapi-0.3.9.bazel"),
    )

    maybe(
        http_archive,
        name = "raze__winapi_i686_pc_windows_gnu__0_4_0",
        url = "https://crates.io/api/v1/crates/winapi-i686-pc-windows-gnu/0.4.0/download",
        type = "tar.gz",
        sha256 = "ac3b87c63620426dd9b991e5ce0329eff545bccbbb34f3be09ff6fb6ab51b7b6",
        strip_prefix = "winapi-i686-pc-windows-gnu-0.4.0",
        build_file = Label("//cargo/remote:BUILD.winapi-i686-pc-windows-gnu-0.4.0.bazel"),
    )

    maybe(
        http_archive,
        name = "raze__winapi_util__0_1_5",
        url = "https://crates.io/api/v1/crates/winapi-util/0.1.5/download",
        type = "tar.gz",
        sha256 = "70ec6ce85bb158151cae5e5c87f95a8e97d2c0c4b001223f33a334e3ce5de178",
        strip_prefix = "winapi-util-0.1.5",
        build_file = Label("//cargo/remote:BUILD.winapi-util-0.1.5.bazel"),
    )

    maybe(
        http_archive,
        name = "raze__winapi_x86_64_pc_windows_gnu__0_4_0",
        url = "https://crates.io/api/v1/crates/winapi-x86_64-pc-windows-gnu/0.4.0/download",
        type = "tar.gz",
        sha256 = "712e227841d057c1ee1cd2fb22fa7e5a5461ae8e48fa2ca79ec42cfc1931183f",
        strip_prefix = "winapi-x86_64-pc-windows-gnu-0.4.0",
        build_file = Label("//cargo/remote:BUILD.winapi-x86_64-pc-windows-gnu-0.4.0.bazel"),
    )

    maybe(
        http_archive,
        name = "raze__winreg__0_7_0",
        url = "https://crates.io/api/v1/crates/winreg/0.7.0/download",
        type = "tar.gz",
        sha256 = "0120db82e8a1e0b9fb3345a539c478767c0048d842860994d96113d5b667bd69",
        strip_prefix = "winreg-0.7.0",
        build_file = Label("//cargo/remote:BUILD.winreg-0.7.0.bazel"),
    )

    maybe(
        http_archive,
        name = "raze__yaml_rust__0_4_5",
        url = "https://crates.io/api/v1/crates/yaml-rust/0.4.5/download",
        type = "tar.gz",
        sha256 = "56c1936c4cc7a1c9ab21a1ebb602eb942ba868cbd44a99cb7cdc5892335e1c85",
        strip_prefix = "yaml-rust-0.4.5",
        build_file = Label("//cargo/remote:BUILD.yaml-rust-0.4.5.bazel"),
    )
