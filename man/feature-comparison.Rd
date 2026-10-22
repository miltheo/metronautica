\name{feature-comparison}
\alias{feature-comparison}
\title{Compare feature pipelines over one dynamic recording}
\description{Compare epoch summaries from the same decoded recording with common time bounds and explicit processing settings.}
\details{ENMO, mean gravity-subtracted SVM and band-pass SVM are overlaid on a common m\eqn{g} axis. MAD uses a separate scale in the same figure because its range is smaller in this recording. Values are not amplitude-normalised. The band-pass feature applies its own 0.69--10 Hz axis filter; do not prefilter the recording to request it. Five-second epochs use the same start label for these sample-level features. No resampling or additional VM calibration is requested. Shaded intervals indicate the ten six-minute excitation stages; the intervening adjustments remain visible. This is a within-recording comparison, not evidence of device equivalence or behavioural validity.}
\section{Inputs}{\if{latex}{\out{\sloppy}} Obtain the LEAP dynamic attachment and catalogue from the canonical WAM sample guide, \url{https://github.com/miltheo/wam/blob/main/samples/README.md}, then configure the \code{metronautica.sample_dir} option with the local sample directory. This comparison does not require the reference recording.}
\value{The example creates \code{comparison}, containing long/wide feature tables and resolved settings, and \code{comparison_plot}, a ggplot object. Plot grouping changes only the display; retain the original result and settings for subsequent analysis.}
\examples{
\dontrun{
library(metronautica)
library(ggplot2)

path <- m_load_sample_data(device = "LEAP", type = "dynamic",
    include_reference = FALSE)
info <- attr(path, "sample_info")
recording <- parse_raw_auto(path, return = "bundle",
    time_shift_s = info$time_shift_s,
    full_scale_range_g = info$full_scale_range_g)
comparison <- compute_accel_summaries(recording,
    measures = c("ENMO", "SVMGMEAN", "SVMBP_069_10", "MAD"),
    epoch_s = 5, epoch_anchor = "start", quiet = TRUE)
comparison$settings$metric_units

plot_data <- comparison$data_long
main_panel <- "ENMO, mean gravity-subtracted SVM and band-pass SVM"
plot_data$panel <- factor(ifelse(plot_data$measure == "MAD",
    "MAD", main_panel), levels = c(main_panel, "MAD"))
start <- as.POSIXct(info$trial_start_utc, tz = "UTC")
stages <- data.frame(start = start + (0:9) * 8 * 60,
    end = start + (0:9) * 8 * 60 + 6 * 60, rpm = seq(50, 500, 50))
comparison_plot <- ggplot(plot_data, aes(time, value, colour = measure, linetype = measure)) +
    geom_rect(data = stages, aes(xmin = start, xmax = end,
        ymin = -Inf, ymax = Inf), inherit.aes = FALSE,
        fill = "grey92", colour = NA) +
    geom_line(linewidth = 0.5) +
    geom_text(data = stages, aes(x = start + 3 * 60, y = Inf,
        label = paste(rpm, "RPM")), inherit.aes = FALSE,
        vjust = 1.4, size = 2.7) +
    facet_wrap(~panel, ncol = 1, scales = "free_y") +
    scale_colour_manual(values = c(ENMO = "#0072B2", SVMGMEAN = "#D55E00",
        SVMBP_069_10 = "#009E73", MAD = "#CC79A7"),
        breaks = c("ENMO", "SVMGMEAN", "SVMBP_069_10", "MAD"),
        labels = c("ENMO", "Mean gravity-subtracted SVM",
            "Band-pass SVM (0.69-10 Hz)", "MAD")) +
    guides(colour = guide_legend(override.aes = list(
        linetype = c("solid", "22", "solid", "solid")))) +
    scale_linetype_manual(values = c(ENMO = "solid", SVMGMEAN = "22",
        SVMBP_069_10 = "solid", MAD = "solid"), guide = "none") +
    scale_x_datetime(date_labels = "\%H:\%M", date_breaks = "10 min",
        timezone = "UTC", expand = expansion(mult = c(0, 0.01))) +
    scale_y_continuous(expand = expansion(mult = c(0.03, 0.18))) +
    labs(x = "Time (UTC)", y = expression("Epoch mean (m"*italic(g)*")"),
        colour = NULL,
        title = "LEAP: feature pipelines over one dynamic trial",
        subtitle = paste("Five-second epochs; native decoded signal;",
            "no additional VM calibration")) +
    theme_bw(base_size = 11) +
    theme(legend.position = "bottom", strip.text.y = element_text(angle = 0),
        strip.background = element_rect(fill = "white"))
comparison_plot
}
}
\seealso{\itemize{
\item \code{\link{compute_accel_summaries}}
\item \code{\link{accel_metric_enmo}}
\item \code{\link{accel_metric_mad}}
\item \code{\link{accel_metric_svmg}}
\item \code{\link{accel_metric_svmbp}}
}}
