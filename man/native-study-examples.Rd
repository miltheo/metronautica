\name{native-recording-examples}
\alias{native-recording-examples}
\alias{native-study-examples}
\title{Worked examples using stationary and orbital-shaker recordings}
\description{\if{latex}{\out{\sloppy}} Parse native recordings, inspect primary-five diagnostics, compute time-domain features and characterise static and dynamic signals using direct functions.}
\details{\if{latex}{\out{\sloppy}} Recording contents, selection boundaries, provenance and distribution terms are documented in the canonical WAM sample guide: \url{https://github.com/miltheo/wam/blob/main/samples/README.md}. The examples below demonstrate the loader and direct processing functions; they do not establish between-device equivalence or behavioural validity.}
\section{Input and processing}{\if{latex}{\out{\sloppy}} The sample loader copies native files to the project, checks their SHA-256 digests and writes provenance sidecars. Dynamic examples include the primary HBK reference by default. The returned path carries sample_info, reference_file and reference_info attributes. Apply each file's documented timestamp shift explicitly when parsing. Parsing runs signal diagnostics by default without repairing or removing observations. Tables and parser bundles are accepted by the calculation functions. Optional GENEAread is needed for GENEActiv; optional plotly is needed for the interactive plots.}
\section{Interpreting the examples}{\if{latex}{\out{\sloppy}} The static window is selected explicitly before drift, noise and Allan-deviation calculations. Full static parsing can take several minutes and substantial memory. The ten-stage example supplies one-minute trimming at each stage end; the native recording remains unchanged. Reference matching uses the retained nearest sample-index method, separate from timestamp-shift and alignment diagnostics. One unit and one trial illustrate calculations, not between-unit inference, trial-to-trial repeatability or device equivalence. Consult the individual help pages for normalising spans and units.}
\seealso{\itemize{
\item{\code{\link{m_load_sample_data}}}
\item{\code{\link{parse_raw_auto}}}
\item{\code{\link{static_metrology_from_tbl}}}
\item{\code{\link{dynamic_metrology_report}}}
\item{\code{\link{m_dynamic_response}}}
\item{\code{\link{measurement-definitions}}}
}}
\section{Sample distribution}{\if{latex}{\out{\sloppy}} Distribution and provenance are specified by the canonical WAM sample guide linked above. Configure \code{options(metronautica.sample_dir = path)} for local samples, or \code{metronautica.sample_base_url} with the fixed HTTPS release-asset directory after publication. Existing identical restored files are reused offline. No data are downloaded during package installation or loading.}
\examples{
\dontrun{
# Configure metronautica.sample_dir with the catalogue and recording attachments.
library(metronautica)

# Static characterisation
path <- m_load_sample_data(device = "LEAP", type = "static")
info <- attr(path, "sample_info")
stationary <- parse_raw_auto(path, return = "bundle",
    time_shift_s = info$time_shift_s,
    full_scale_range_g = info$full_scale_range_g)
static_result <- static_metrology_from_tbl(stationary,
    start_utc = info$analysis_start_utc, duration_h = 24, progress = FALSE)
static_result$summary
static_result$drift_plot
static_result$allan_plot

# Dynamic characterisation
path <- m_load_sample_data(device = "LEAP", type = "dynamic")
info <- attr(path, "sample_info")
ref_info <- attr(path, "reference_info")
test <- parse_raw_auto(path, return = "bundle",
    time_shift_s = info$time_shift_s,
    full_scale_range_g = info$full_scale_range_g)
reference <- parse_raw_auto(attr(path, "reference_file"), return = "bundle",
    time_shift_s = ref_info$time_shift_s,
    full_scale_range_g = ref_info$full_scale_range_g)
test_stages <- clip_dynamic_stages(test, start_utc = info$trial_start_utc,
    n_stages = 10L, stage_min = 6, buffer_min = 2, rpm_start = 50, rpm_step = 50,
    trim_start_min = 1, trim_end_min = 1)
ref_stages <- clip_dynamic_stages(reference, start_utc = ref_info$trial_start_utc,
    n_stages = 10L, stage_min = 6, buffer_min = 2, rpm_start = 50, rpm_step = 50,
    trim_start_min = 1, trim_end_min = 1)
dynamic_result <- dynamic_metrology_report(test_stages, ref_stages,
    test_axis_fsr_g = info$full_scale_range_g,
    ref_axis_fsr_g = ref_info$full_scale_range_g,
    compute_entropy = FALSE, inspect_alignment = FALSE, add_plot = TRUE,
    progress = FALSE)
dynamic_result$stages
dynamic_result$overall
dynamic_result$plots$vm_mean_vs_rpm
dynamic_result$plots$linearity_vs_rpm

# Feature extraction
features <- compute_accel_summaries(test, measures = c("ENMO", "MAD"), epoch_s = 5)
head(features$data_wide)
features$settings$metric_units
if (requireNamespace("plotly", quietly = TRUE)) {
    plot_processed_metric(features, "ENMO")
}
}
}
