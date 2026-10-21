\name{measurement-definitions}
\alias{measurement-definitions}
\title{Calculation definitions and interpretation}
\description{\if{latex}{\out{\sloppy}} Units, normalisation and implemented arithmetic for the public metrology functions.}
\details{\if{latex}{\out{\sloppy}}
Vector magnitude is \eqn{v=\sqrt{a_x^2+a_y^2+a_z^2}} in g.
\describe{
\item{Signed 1-g VM offset bias}{\if{latex}{\out{\sloppy}} Initial one-second mean VM minus 1 g, averaged over elapsed time up to and including five minutes. This is a VM offset relative to gravity, not a complete axis calibration.}
\item{Signed VM drift rate}{\if{latex}{\out{\sloppy}} Ordinary least-squares slope against elapsed hours, g/h. Extrapolation beyond the stationary recording requires an explicitly stated model.}
\item{Static noise floor}{\if{latex}{\out{\sloppy}} Maximum axis-specific residual SD after linear detrending over the selected stationary window; the study uses 24 hours and reports mg. The first-five-minute maximum-axis SD is raw, not detrended. Raw sample SD uses denominator n-1; linearly detrended residual SD uses n-2. Static CV is 100 times SD divided by absolute mean, with a near-zero guard.}
\item{Allan deviation}{\if{latex}{\out{\sloppy}} For non-overlapping cluster means \eqn{\bar{x}_j}, \eqn{\sigma_A=\sqrt{\operatorname{mean}[(\bar{x}_{j+1}-\bar{x}_j)^2]/2}}. Cluster duration is in seconds and deviation is in g.}
\item{Dynamic response and signed VM bias}{\if{latex}{\out{\sloppy}} OLS of test VM on length-matched reference VM. Slope is dimensionless; intercept and mean signed test-minus-reference bias are in g. Scale-factor error is slope minus one; the study multiplies it by 100 for percentage reporting. Absolute VM bias is the absolute value of the stage-mean signed difference, not the mean absolute paired difference.}
\item{VM integral non-linearity}{\if{latex}{\out{\sloppy}} 100 times the maximum absolute fitted residual divided by \eqn{\sqrt{3}F}, where F is the test-axis peak-to-peak span in g.}
\item{Trial-level composite error}{\if{latex}{\out{\sloppy}} 100 times the maximum absolute residual from the pooled response fit divided by \eqn{\sqrt{3}F/2}. This denominator differs from stage VM integral non-linearity by a factor of two. The study normalising span is not the nonnegative VM output range.}
\item{Within-stage epoch-mean VM CV}{\if{latex}{\out{\sloppy}} SD of within-stage epoch mean VM divided by their mean. The retained field \code{repeatability_error_cv} is a fraction. It is distinct from the manuscript's trial-to-trial VM repeatability CV, which the study calculates as 100 times SD divided by mean of stage-mean VM across repeated trials for the same unit, stage and pipeline.}
\item{Maximum-axis Allan minimum}{\if{latex}{\out{\sloppy}} Maximum across axes of their individual minimum Allan deviations over the evaluated averaging times; the study reports micro-g. This is distinct from the axis-specific curves.}
\item{ENMO}{\if{latex}{\out{\sloppy}} Epoch mean of \eqn{\max(v-1,0)}. Negative differences are truncated to zero per sample before averaging.}
\item{MAD}{\if{latex}{\out{\sloppy}} Epoch mean of \eqn{|v-\bar{v}|}, with \eqn{\bar{v}} defined within the epoch. ENMO and MAD are multiplied by 1000 for default mg output.}
}
Index-based dynamic reference matching is not timestamp correction. No equivalence margin or universal fit-for-purpose decision is embedded in these functions. Report the reference, tested range, rate, filtering, epoch settings, signal calibration state, error normalisation and relevant timing diagnostics with every application.
}
\seealso{
\itemize{
\item \code{\link{metronautica-package}}.
\item \code{\link{static_metrology_from_tbl}}.
\item \code{\link{dynamic_metrology_report}}.
\item \code{\link{compute_accel_summaries}}.
}
}
