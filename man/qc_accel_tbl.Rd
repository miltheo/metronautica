\name{qc_accel_tbl}
\alias{qc_accel_tbl}
\title{Quantify signal and timestamp integrity}
\description{\if{latex}{\out{\sloppy}} Report integrity diagnostics without sorting, repairing or removing samples.}
\usage{
qc_accel_tbl(x)
}
\arguments{
\item{x}{\if{latex}{\out{\sloppy}} Acceleration table or parser/clip bundle. Requires exactly time (POSIXct), ax_g, ay_g, az_g (numeric \eqn{g}), in that order; metadata precedence follows \code{\link{common-data-format}}.}
}
\value{\if{latex}{\out{\sloppy}} A named list of scalar diagnostics. Counts are sample counts except \code{invalid_axis}, \code{near_limit_n} and \code{finite_axis_n}, which count axis observations. Percentages are on the 0--100 scale.}
\details{\if{latex}{\out{\sloppy}}
The primary-five rules follow Supplementary Table S2 of the research article under submission.
\describe{
\item{1. Data integrity}{\if{latex}{\out{\sloppy}} Count non-finite timestamps. Count repeated finite timestamps after their first occurrence. Count negative differences between adjacent finite timestamps. Count non-finite acceleration values across X, Y and Z.

\emph{Reported output:} Four separate counts; total rows and total axis values retained as denominators.

\emph{Source:} Study-defined availability and ordering checks.}
\item{2. Sample timing}{\if{latex}{\out{\sloppy}} Select finite, positive differences between adjacent timestamps. Report their median, interquartile range (IQR) and maximum.

\emph{Reported output:} Typical spacing, spacing spread and longest spacing (ms).

\emph{Source:} Study-defined application; IQR is an established measure of spread (NIST/SEMATECH, n.d.).}
\item{3. Axis-zero proportion}{\if{latex}{\out{\sloppy}} For each axis, divide the number of exact-zero values by the number of finite values and multiply by 100.

\emph{Reported output:} Zero values (\%) separately for X, Y and Z.

\emph{Source:} Study-defined descriptive diagnostic.}
\item{4. Unusual cross-axis patterns}{\if{latex}{\out{\sloppy}} Count samples with \eqn{X = Y = Z = 0}. Count samples with \eqn{X = Y = Z} and \eqn{X \neq 0}. Flag each pattern separately when it occurs in at least two consecutive eligible samples.

\emph{Reported output:} Sample count and sequence-present flag for each pattern.

\emph{Source:} Adapted from NHANES all-zero and equal-axis flags (CDC/NCHS, 2022); the two-sample all-zero minimum is study-defined.}
\item{5. Near-limit values}{\if{latex}{\out{\sloppy}} Pool the finite acceleration values from X, Y and Z. Report the percentage whose absolute value is at least \eqn{0.98L}, where \eqn{L} is the configured positive axis limit.

\emph{Reported output:} Near-limit values (\%); retain \eqn{L}, threshold, numerator and denominator.

\emph{Source:} NHANES range-limit concept (CDC/NCHS, 2022); 98\% and pooling are study-defined. Span terminology follows JCGM (2012, entries 4.4--4.5).}
}
Finite excludes missing values, NaN and infinities. Unavailable quantities are reported as NA. IQR requires at least two positive intervals and uses linearly interpolated quartiles. For symmetric limits, \eqn{L} is half the configured full-scale span. Eligible pattern samples have finite timestamps and XYZ values. Consecutive samples are adjacent recorded rows with strictly increasing timestamps; an ineligible row or non-increasing step breaks a sequence. The equal non-zero value may vary between samples. No gap-duration cutoff is imposed. The intended all-axis NHANES zero condition is used, not its documented X-only implementation error; the original minute-level flag algorithm is not reproduced.
}

\seealso{\code{\link{attach_qc}}, \code{\link{common-data-format}}}
\examples{
path <- system.file("extdata", "example_motion.csv",
    package = "metronautica", mustWork = TRUE)
x <- parse_raw_auto(path)
q <- qc_accel_tbl(x)
q[c("n_samples", "median_dt_ms", "near_limit_pct")]
}

\references{NIST/SEMATECH (n.d.). e-Handbook of Statistical Methods, Section 1.3.5.6: Measures of Scale. \url{https://www.itl.nist.gov/div898/handbook/eda/section3/eda356.htm}.

CDC/NCHS (2022). Data Quality Flag Summary Table for the Physical Activity Monitor (PAM) Data Collected in NHANES 2011--2014 and NNYFS. \url{https://wwwn.cdc.gov/nchs/nhanes/Pam/}.

JCGM (2012). International vocabulary of metrology, JCGM 200:2012, entries 4.4--4.5. \doi{10.59161/JCGM200-2012}.}
