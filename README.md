# Metronautica

R functions for wearable accelerometer parsing, signal diagnostics, clipping,
static and dynamic characterisation, filtering and time-domain features.
Standalone activity counts support the published filter or custom cutoffs.

## Installation

Install the packages listed in `Imports` in [DESCRIPTION](DESCRIPTION), then:

```sh
R CMD INSTALL .
```

Optional dependencies support particular native formats, MIMS, entropy or
interactive plots; see the [Getting Started guide](docs/GETTING_STARTED.md).

## Example

This example uses the small synthetic recording installed with the package.

```r
library(metronautica)
path <- system.file("extdata", "example_motion.csv", package = "metronautica")
x <- read.csv(path)
names(x) <- c("time", "ax_g", "ay_g", "az_g")
x$time <- as.POSIXct(x$time, tz = "UTC")
enmo <- compute_accel_summaries(x, measures = "ENMO", epoch_s = 5)
enmo$data_wide
```

For the complete offline workflow, run
`example("getting-started", package = "metronautica")`.

Native static and dynamic examples are distributed separately through
[WAM](https://github.com/miltheo/wam). See the
[worked examples](docs/REAL_DATA_EXAMPLES.md) for sample retrieval and metrology.
No recordings are downloaded during installation or package loading.

## Documentation

- [Getting Started](docs/GETTING_STARTED.md): workflow, settings and source layout.
- [Reference manual](docs/metronautica-reference.pdf): functions, parameters and methods.
- [Measurement definitions](docs/MEASUREMENT_DEFINITIONS.md): technical terminology.
- [Activity-count validation](docs/ACTIGRAPH_COUNTS.md): benchmarks and limitations.

## Repository structure

| Directory | Contents |
|---|---|
| `R/` | Ten flat `m_*.R` engine scripts |
| `man/` | R help and installed guides |
| `inst/extdata/` | Small offline fixtures and native-sample catalogue |
| `tests/` | Numerical and interface checks, with count reference fixtures |
| `docs/` | Guides, manual and `validation/` benchmark tables |
| `examples/` | Native-data quick start |
| `tools/` | Manual build and complete validation runner |

After installing the package, run from the repository root:

```sh
Rscript tools/validate.R
Rscript tools/build_manual.R
```

## Citation and licence

Citation metadata: [CITATION.cff](CITATION.cff). Software: **GPL-3**;
see [LICENSE.md](LICENSE.md) and [dependency notices](docs/DEPENDENCY_LICENSING.md).
Native sample data have separate distribution terms documented by WAM.

Maintainer: [Millen J. Theophilus](https://github.com/miltheo).
