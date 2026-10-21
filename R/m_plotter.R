# Plotting is optional; package loading never attaches or installs Plotly.
.m_require_plotly <- function() {
    if (!requireNamespace("plotly", quietly = TRUE))
        stop("Install the optional plotly package to plot signals.", call. = FALSE)
    invisible(TRUE)
}

#----------- Helper: internal display downsampling ------------------------------
.ds_idx <- function(n, max_points = 50000) {                                      # Create index for display only
    if (n <= max_points) return(seq_len(n))                                       # Keep all points if not too large
    unique(round(seq(1, n, length.out = max_points)))                             # Evenly thin very long series
}

#----------- Helper: initial x-axis spacing -------------------------------------
.pick_dtick <- function(span_s) {                                                 # Pick sensible initial datetime spacing
    if (span_s <= 120) return(1000)                                               # 1 second
    if (span_s <= 600) return(5000)                                               # 5 seconds
    if (span_s <= 1800) return(15000)                                             # 15 seconds
    if (span_s <= 3600) return(60000)                                             # 1 minute
    if (span_s <= 6 * 3600) return(300000)                                        # 5 minutes
    if (span_s <= 24 * 3600) return(1800000)                                      # 30 minutes
    if (span_s <= 72 * 3600) return(7200000)                                      # 2 hours
    21600000                                                                       # 6 hours
}

#----------- Main function ------------------------------------------------------
# Unwrap only; retain timestamps, values, row order and the original input.
.plot_input_data <- function(x, fields = c("full", "data")) {
    if (is.data.frame(x)) return(x)
    if (is.list(x)) {
        for (field in fields) {
            if (is.data.frame(x[[field]])) return(x[[field]])
        }
    }
    stop("Expected a data table or a bundle containing $",
         paste(fields, collapse = " or $"), ".", call. = FALSE)
}

# x: an acceleration table, parser bundle ($data), or clip bundle ($full).
plot_accel_clip <- function(x, include_vm = FALSE, demean_vm = FALSE, title = NULL) {
    .m_require_plotly()
    x <- .plot_input_data(x)
    stopifnot(inherits(x$time, "POSIXct"))                                        # Require POSIXct time
    stopifnot(all(c("time","ax_g","ay_g","az_g") %in% names(x)))                  # Require canonical columns

    d <- x[.ds_idx(nrow(x)), , drop = FALSE]                                      # Downsample only for plotting

    channels <- c("ax_g","ay_g","az_g")                                           # Default plotted channels

    if (include_vm) {                                                             # Add vector magnitude if requested
        vm <- sqrt(d$ax_g^2 + d$ay_g^2 + d$az_g^2)                                # Compute vector magnitude
        d$vm_g <- if (demean_vm) pmax(vm - 1, 0) else vm                          # Optional gravity-adjusted VM
        channels <- c(channels, "vm_g")                                           # Add VM channel to plot
    }

    span_s <- as.numeric(diff(range(d$time, na.rm = TRUE)), units = "secs")       # Total plotted duration
    dtick0 <- .pick_dtick(span_s)                                                 # Initial tick spacing

    p <- plotly::plot_ly()                                                        # Start Plotly object

    for (ch in channels) {                                                        # Add each signal trace
        p <- plotly::add_lines(
            p,
            x = d$time,
            y = d[[ch]],
            name = ch,
            line = list(width = 0.6),
            hovertemplate = paste0(
                "<b>", ch, "</b><br>",
                "Time: %{x|%Y-%m-%d %H:%M:%OS3}<br>",
                "Value: %{y:.4f} g",
                "<extra></extra>"
            )
        )
    }

    if (is.null(title)) title <- "Accelerometer signal for clipping"              # Default title

    plotly::layout(
        p,
        title = list(text = title),
        xaxis = list(
            title = "Time (UTC)",
            type = "date",
            dtick = dtick0,
            rangeslider = list(visible = TRUE),
            tickformatstops = list(
                list(dtickrange = list(NULL, 1000), value = "%H:%M:%OS3"),
                list(dtickrange = list(1000, 60000), value = "%H:%M:%S"),
                list(dtickrange = list(60000, 3600000), value = "%H:%M"),
                list(dtickrange = list(3600000, 86400000), value = "%d %b %H:%M"),
                list(dtickrange = list(86400000, NULL), value = "%d %b\n%H:%M")
            )
        ),
        yaxis = list(title = "Acceleration (g)"),
        hovermode = "x unified",
        legend = list(orientation = "h", x = 0, y = 1.08)
    )
}

plot_processed_metric <- function(result, metric, unit = NULL,
                                  title = metric) {
    .m_require_plotly()
    # Accept the summary result or its data_wide table directly.
    d <- .plot_input_data(result, fields = "data_wide")
    if (!inherits(d$time, "POSIXct")) {
        stop("Column 'time' must be POSIXct.", call. = FALSE)
    }
    if (!is.character(metric) || length(metric) != 1L || is.na(metric) ||
        !metric %in% names(d) || !is.numeric(d[[metric]])) {
        stop("metric must name one numeric column in the processed data.", call. = FALSE)
    }

    if (is.null(unit) && is.list(result) && !is.data.frame(result)) {
        unit <- unname(result$settings$metric_units[metric])
    }
    if (!is.character(unit) || length(unit) != 1L || is.na(unit) || !nzchar(unit)) {
        stop("Supply unit explicitly when resolved metric_units metadata is unavailable; values are not rescaled.", call. = FALSE)
    }

    plotly::plot_ly(
        data = d,
        x = ~time,
        y = d[[metric]],
        type = "scatter",
        mode = "lines",
        name = metric,
        line = list(width = 1.6)
    ) |>
        plotly::layout(
            title = list(text = title),
            xaxis = list(
                title = "Time (UTC)",
                type = "date",
                rangeslider = list(visible = TRUE)
            ),
            yaxis = list(title = paste0(metric, " (", unit, ")")),
            hovermode = "x unified",
            dragmode = "zoom",
            legend = list(orientation = "h", y = 1.12)
        ) |>
        plotly::config(responsive = TRUE, displaylogo = FALSE)
}
