# Canonical real-recording comparison and plot.
# Requires configured WAM sample recordings.
library(metronautica)
library(ggplot2)

# Load native trial sample ----
path <- m_load_sample_data(device = "LEAP", type = "dynamic", include_reference = FALSE)
info <- attr(path, "sample_info")
recording <- parse_raw_auto(path, return = "bundle", time_shift_s = info$time_shift_s, full_scale_range_g = info$full_scale_range_g)

# Select and compute feature pipelines ----
comparison <- compute_accel_summaries(recording, measures = c("ENMO", "SVMGMEAN", "SVMBP_069_10", "MAD"),
    epoch_s = 5, epoch_anchor = "start", quiet = TRUE)
comparison$settings$metric_units

# Group compatible feature scales ----
plot_data <- comparison$data_long
main_panel <- "ENMO, mean gravity-subtracted SVM and band-pass SVM"
plot_data$panel <- factor(ifelse(plot_data$measure == "MAD", "MAD", main_panel), levels = c(main_panel,
    "MAD"))

# Mark scheduled excitation intervals ----
start <- as.POSIXct(info$trial_start_utc, tz = "UTC")
stages <- data.frame(start = start + (0:9) * 8 * 60, end = start + (0:9) * 8 * 60 + 6 * 60, rpm = seq(50,
    500, 50))

# Plot features over shared time ----
comparison_plot <- ggplot(plot_data, aes(time, value, colour = measure, linetype = measure)) +
    geom_rect(data = stages,
        aes(xmin = start, xmax = end, ymin = -Inf, ymax = Inf), inherit.aes = FALSE, fill = "grey92", colour = NA) +
    geom_line(linewidth = 0.5) +
    geom_text(data = stages, aes(x = start + 3 * 60, y = Inf, label = paste(rpm,
        "RPM")), inherit.aes = FALSE, vjust = 1.4, size = 2.7) +
    facet_wrap(~panel, ncol = 1, scales = "free_y") +
    scale_colour_manual(values = c(ENMO = "#0072B2", SVMGMEAN = "#D55E00", SVMBP_069_10 = "#009E73",
        MAD = "#CC79A7"), breaks = c("ENMO", "SVMGMEAN", "SVMBP_069_10", "MAD"), labels = c("ENMO", "Mean gravity-subtracted SVM",
        "Band-pass SVM (0.69-10 Hz)", "MAD")) +
    guides(colour = guide_legend(override.aes = list(linetype = c("solid",
        "22", "solid", "solid")))) +
    scale_linetype_manual(values = c(ENMO = "solid", SVMGMEAN = "22", SVMBP_069_10 = "solid",
        MAD = "solid"), guide = "none") +
    scale_x_datetime(date_labels = "%H:%M", date_breaks = "10 min",
        timezone = "UTC", expand = expansion(mult = c(0, 0.01))) +
    scale_y_continuous(expand = expansion(mult = c(0.03,
        0.18))) +
    labs(x = "Time (UTC)", y = expression("Epoch mean (m" * italic(g) * ")"), colour = NULL,
        title = "LEAP: feature pipelines over one dynamic trial", subtitle = paste("Five-second epochs; native decoded signal;",
        "no additional VM calibration")) +
    theme_bw(base_size = 11) +
    theme(legend.position = "bottom",
        strip.text.y = element_text(angle = 0), strip.background = element_rect(fill = "white"))
comparison_plot
