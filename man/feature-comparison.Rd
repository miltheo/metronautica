\name{feature-comparison}
\alias{feature-comparison}
\title{Compare feature pipelines over one dynamic recording}
\description{\if{latex}{\out{\sloppy}} Compare epoch summaries from the same decoded recording with common time bounds and explicit processing settings.}
\details{\if{latex}{\out{\sloppy}} ENMO, mean gravity-subtracted SVM and band-pass SVM share a m\eqn{g} scale; MAD has a separate panel. Values are not amplitude-normalised. Only band-pass SVM applies the 0.69--10 Hz axis filter; no prefiltering, resampling or additional VM calibration is requested. Five-second epochs use start labels. Shading marks ten six-minute stages, retaining intervening adjustments. This within-recording comparison does not establish device equivalence or behavioural validity.}
\section{Inputs}{\if{latex}{\out{\sloppy}} Obtain the LEAP dynamic attachment and catalogue from the canonical WAM sample guide, \url{https://github.com/miltheo/wam/blob/main/samples/README.md}, then configure the \code{metronautica.sample_dir} option with the local sample directory. This comparison does not require the reference recording.}
\value{\if{latex}{\out{\sloppy}} The example creates \code{comparison}, containing long/wide feature tables and resolved settings, and, in the complete guide, \code{comparison_plot}, a ggplot object. Plot grouping changes only the display; retain the original result and settings for subsequent analysis.}
\section{Example execution}{\if{latex}{\out{\sloppy}} The \code{Not run} block requires external recordings; it was executed locally for the guide figure.}
\examples{
\dontrun{
# Requires the LEAP dynamic sample.
path <- m_load_sample_data("LEAP", "dynamic", include_reference = FALSE)
info <- attr(path, "sample_info")
recording <- parse_raw_auto(path, return = "bundle",
    time_shift_s = info$time_shift_s,
    full_scale_range_g = info$full_scale_range_g)
comparison <- compute_accel_summaries(recording,
    measures = c("ENMO", "SVMGMEAN", "SVMBP_069_10", "MAD"),
    epoch_s = 5, epoch_anchor = "start", quiet = TRUE)
head(comparison$data_long)
comparison$settings$metric_units
}
}

\seealso{\href{https://github.com/miltheo/metronautica/blob/main/docs/REAL_DATA_EXAMPLES.md#feature-comparison}{Complete comparison and plot}, \code{\link{compute_accel_summaries}}}
