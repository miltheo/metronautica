# Metronautica Tibble 0.1.0: four required columns, no supplied metadata.
library(metronautica)

fs <- 100
seconds <- (0:1999) / fs
x <- as_accel_tbl(
    as.POSIXct("2026-01-01", tz = "UTC") + seconds,
    0.2 * sin(2 * pi * 2 * seconds),
    0.2 * cos(2 * pi * 2 * seconds),
    rep(1, length(seconds)))
stopifnot(identical(names(x), c("time", "ax_g", "ay_g", "az_g")),
    identical(accel_meta(x), list()))

# Diagnostic results are optional pipeline additions.
q <- qc_accel_tbl(x)
stopifnot(q$n_samples == 2000, is.na(q$near_limit_pct))
# Near-limit diagnostics need a known measurement range; it is not inferred.
x_with_qc <- attach_qc(x, scope = "synthetic minimal example")

# These metrics can use the retained samples without acquisition metadata.
features <- compute_accel_summaries(x, measures = c("ENMO", "MAD"),
    epoch_s = 5, quiet = TRUE)
stopifnot(nrow(features$data_wide) == 4)

# RDS retains typed timestamps and optional pipeline additions.
path <- tempfile(fileext = ".rds")
saveRDS(x_with_qc, path)
stopifnot(identical(readRDS(path), x_with_qc))
unlink(path)
