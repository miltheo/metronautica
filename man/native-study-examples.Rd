\name{native-study-examples}
\alias{native-study-examples}
\title{Worked examples using native laboratory recordings}
\description{\if{latex}{\out{\sloppy}} Parse study recordings, inspect primary-five diagnostics, compute time-domain features and characterise static and dynamic signals using direct functions.}
\details{\if{latex}{\out{\sloppy}} Use one laboratory unit each of LEAP, AX3, SENS or GENEActiv. Static recordings cover the analysed 24 hours. Dynamic recordings contain the continuous 78-minute first primary trial: ten six-minute stages at 50--500 RPM and nine two-minute adjustments. These are native analysis-window derivatives, not complete original downloads. Original measurement packets or CSV rows and stored coefficients are retained, with boundary padding and necessary container bookkeeping recorded in provenance. The data are controlled laboratory recordings, not behavioural validation data.}
\section{Input and processing}{\if{latex}{\out{\sloppy}} The sample loader copies native files to the project, checks their SHA-256 digests and writes provenance sidecars. Dynamic examples include the primary HBK reference by default. The returned path carries sample_info, reference_file and reference_info attributes. Apply each file's documented timestamp shift explicitly when parsing. Parsing runs signal diagnostics by default without repairing or removing observations. Tables and parser bundles are accepted by the calculation functions. Optional GENEAread is needed for GENEActiv; optional plotly is needed for the interactive plots.}
\section{Interpreting the examples}{\if{latex}{\out{\sloppy}} The static window is selected explicitly before drift, noise and Allan-deviation calculations. Full static parsing can take several minutes and substantial memory. The study example explicitly supplies one-minute trimming at each stage end; the native recording remains unchanged. Reference matching uses the retained nearest sample-index method, separate from timestamp-shift and alignment diagnostics. One unit and one trial illustrate calculations, not between-unit inference, trial-to-trial repeatability or device equivalence. Consult the individual help pages for normalising spans and units.}
\seealso{\itemize{
\item{\code{\link{m_load_sample_data}}}
\item{\code{\link{parse_raw_auto}}}
\item{\code{\link{static_metrology_from_tbl}}}
\item{\code{\link{dynamic_metrology_report}}}
\item{\code{\link{m_dynamic_response}}}
\item{\code{\link{measurement-definitions}}}
}}
\section{Sample distribution}{\if{latex}{\out{\sloppy}} Native payloads are distributed as companion WAM release attachments outside Git history. For offline use, place attachments alongside the catalogue in WAM samples; provenance is documented there. These files are outside the installed R package. Configure \code{options(metronautica.sample_dir = path)} for local samples, or \code{metronautica.sample_base_url} with the fixed HTTPS release-asset directory after publication. Existing identical restored files are reused offline. No data are downloaded during package installation or loading.}
\examples{
\dontrun{
# For sibling local checkouts; adjust for the current project.
options(metronautica.sample_dir =
    "../wam/samples")

# Parse, inspect and compute features
library(metronautica)
path <- m_load_sample_data(device = "LEAP", type = "dynamic")
info <- attr(path, "sample_info")
accel <- parse_raw_auto(path, return = "bundle",
    time_shift_s = info$time_shift_s,
    full_scale_range_g = info$full_scale_range_g)
accel_meta(accel)$processing$qc
plot_accel_clip(accel, include_vm = TRUE)
enmo <- compute_accel_summaries(accel, measures = "ENMO", epoch_s = 5)
plot_processed_metric(enmo, "ENMO")

# Static characterisation (24 hours)
path <- m_load_sample_data(device = "LEAP", type = "static")
info <- attr(path, "sample_info")
stationary <- parse_raw_auto(path, return = "bundle",
    time_shift_s = info$time_shift_s,
    full_scale_range_g = info$full_scale_range_g)
window <- static_clip(stationary, start_utc = info$analysis_start_utc,
                      duration_h = 24)
one_second <- static_1hz_means(window)
static_offset_vm_5min(one_second)  # g
drift <- static_drift(one_second)  # slopes in g/h
noise <- static_noise_summary_from_tbl(window,
    start_utc = info$analysis_start_utc, duration_h = 24)
allan <- static_allan(window)
plot_static_drift_vm(one_second, drift$fit_vm)
plot_static_allan(allan)

# Dynamic characterisation against the primary reference
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
response <- dynamic_metrology_report(test_stages, ref_stages,
    test_axis_fsr_g = info$full_scale_range_g,
    ref_axis_fsr_g = ref_info$full_scale_range_g,
    compute_entropy = FALSE, inspect_alignment = FALSE, add_plot = FALSE,
    progress = FALSE)
response$stages
response$overall
}
}
