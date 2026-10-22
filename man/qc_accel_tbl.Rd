\name{qc_accel_tbl}
\alias{qc_accel_tbl}
\title{Quantify signal and timestamp integrity}
\description{\if{latex}{\out{\sloppy}} Report integrity diagnostics without sorting, repairing or removing samples.}
\usage{
qc_accel_tbl(x)
}
\arguments{
\item{x}{\if{latex}{\out{\sloppy}} Acceleration data frame/tibble with POSIXct time and numeric ax_g, ay_g, az_g in \eqn{g}, or a parser/clip bundle containing data/full and optional meta. The data attribute takes precedence over bundle metadata. For this diagnostic function the table must have exactly time, ax_g, ay_g and az_g in that order. No samples are repaired by input conversion.}
}
\value{\if{latex}{\out{\sloppy}} A named list of scalar diagnostics. Counts are sample counts except \code{invalid_axis}, \code{near_limit_n} and \code{finite_axis_n}, which count axis observations. Percentages are on the 0--100 scale.}
\details{\if{latex}{\out{\sloppy}}
The ruleset is named primary-five. The five groups below describe the decoded recording, without exclusion, sorting, interpolation or repair. Finite means neither missing, NaN nor infinite. Rounding tolerances are not introduced into exact equality tests.
\describe{
\item{1. Data integrity}{\if{latex}{\out{\sloppy}} n_samples counts recorded rows. missing_time counts non-finite timestamps. duplicate_time counts repeated finite timestamps after their first occurrence. backward_time counts negative finite differences between adjacent timestamps. invalid_axis counts non-finite scalar axis values across X, Y and Z, so its denominator is three times the row count rather than the number of rows.}
\item{2. Sample timing}{\if{latex}{\out{\sloppy}} Select only finite, strictly positive differences between adjacent recorded timestamps. median_dt_ms is their median, iqr_dt_ms is their interquartile range using R type-7 quartiles, and longest_dt_ms is their maximum, all in milliseconds. IQR requires at least two positive intervals. No positive intervals yields NA. These summaries expose spacing and gaps; they do not count missing samples or establish synchronisation with another recording.}
\item{3. Axis-zero proportion}{\if{latex}{\out{\sloppy}} For each axis, zero_x_n/zero_y_n/zero_z_n count exact zero values. finite_x_n/finite_y_n/finite_z_n count finite values independently. Each zero percentage is 100 times its axis zero count divided by its finite count; no finite values gives NA. A single zero axis can be expected at some stationary orientations and is not an automatic failure.}
\item{4. Unusual cross-axis patterns}{\if{latex}{\out{\sloppy}} all_zero_samples counts rows with X=Y=Z=0; equal_nonzero_samples counts rows with X=Y=Z and X not zero. Pattern counts require finite XYZ values. Each sequence flag is TRUE if its pattern occurs in at least two adjacent eligible rows: both timestamps and all axes must be finite and the timestamp step must be strictly positive. An invalid row, repeated timestamp or reversal breaks the sequence. No gap-duration limit is imposed. Equal non-zero values may differ between adjacent rows. These sample-level rules adapt the NHANES pattern concepts; they do not reproduce its minute-level algorithm or imply every flagged sample is defective.}
\item{5. Near-limit values}{\if{latex}{\out{\sloppy}} limit_g is half the configured symmetric peak-to-peak axis span from acquisition$full_scale_range_g. near_limit_fraction is the fixed screening fraction 0.98. Pool finite scalar observations from all three axes and count those satisfying abs(a) >= 0.98*limit_g as near_limit_n. finite_axis_n is the pooled finite count, and near_limit_pct is 100 times their ratio. Missing/invalid range metadata yields an undefined limit/count and percentage. This is a proximity-to-range screen, not proof of clipping or a calibrated saturation threshold.}
}
The diagnostic thresholds, numerators and denominators are retained with the output so they can be reported. The 0.98 near-limit fraction and pooled-axis denominator are screening conventions; VIM measurement-span terminology does not prescribe that fraction. Stored QC describes only the signal and interval on which it was calculated. Recompute after processing changes or a new clip.
}

\seealso{\code{\link{metronautica-package}}}
\examples{
t0 <- as.POSIXct("2026-01-01 00:00:00", tz = "UTC")
fs <- 100
s <- (0:5999) / fs
meta <- list(acquisition = list(fs_derived_hz = fs,
    fs_nominal_hz = fs, full_scale_range_g = 16))
x <- as_accel_tbl(t0 + s, 0.1 * sin(2 * pi * 2 * s),
    0.1 * cos(2 * pi * 2 * s), 1 + 0.1 * sin(2 * pi * s), meta)
q <- qc_accel_tbl(x)
q[c("n_samples", "median_dt_ms", "near_limit_pct")]
}

\section{Implementation}{\if{latex}{\out{\sloppy}} Implemented by \code{qc_accel_tbl} in \code{R/m_qc.R}. See \code{\link{implementation-guide}} for the framework and function map.}
