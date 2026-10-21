\name{getting-started}
\alias{getting-started}
\title{Start with an offline acceleration workflow}
\description{Construct a small common-format recording, inspect diagnostics, calculate features and retain their settings without external data or optional packages.}
\details{\if{latex}{\out{\sloppy}} Install metronautica and its Imports dependencies, then load it with \code{library(metronautica)}. The example below runs offline. The waveform is synthetic and demonstrates the interface; it is not a validation recording or a stationary noise measurement.

For a native recording, replace the constructor with \code{\link{parse_raw_auto}} and inspect the returned metadata. Parsing attaches QC by default; the constructor requires explicit \code{\link{attach_qc}}. Optional native decoders depend on format. Interactive signal plots require plotly; calculations below do not.

For stationary metrology, select a stationary window with \code{\link{static_clip}}, then use \code{\link{static_metrology_from_tbl}} or its direct outcome helpers. For stepped excitation, apply any intended filter to the recording before \code{\link{clip_dynamic_stages}}, construct test/reference stages and call \code{\link{dynamic_metrology_report}}. \code{\link{native-study-examples}} supplies the full laboratory workflow with external samples. The \code{\link{implementation-guide}} maps these stages to source functions and measurement outcomes.}
\examples{
library(metronautica)
fs <- 100
seconds <- (0:1999) / fs
meta <- list(acquisition = list(fs_nominal_hz = fs,
    fs_derived_hz = fs, full_scale_range_g = 16))
x <- as_accel_tbl(as.POSIXct("2026-01-01", tz = "UTC") + seconds,
    .2 * sin(2*pi*2*seconds), .2 * cos(2*pi*2*seconds),
    rep(1, length(seconds)), meta)
x <- attach_qc(x, scope = "synthetic 20-second recording")
accel_meta(x)$processing$qc[c("n_samples", "median_dt_ms")]

features <- compute_accel_summaries(x, measures = c("ENMO", "MAD"),
    epoch_s = 5, fs_hz = fs, quiet = TRUE)
head(features$data_wide)
features$settings$metric_units
stopifnot(nrow(features$data_wide) == 4)

# AI uses one-second bin-start labels rather than sample-level labels.
# Explicit zero disables noise subtraction only for this interface demonstration.
mixed <- compute_accel_summaries(x, measures = c("ENMO", "AI"),
    epoch_s = 5, fs_hz = fs, ai_noise_var = 0, quiet = TRUE)
table(mixed$data_long$measure)  # Four epochs per feature
nrow(mixed$data_wide)          # Eight rows: different timestamp labels
stopifnot(nrow(mixed$data_wide) == 8)
}
\seealso{\code{\link{common-data-format}}, \code{\link{compute_accel_summaries}}, \code{\link{native-study-examples}}}
