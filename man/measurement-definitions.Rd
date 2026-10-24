\name{measurement-definitions}
\alias{measurement-definitions}
\title{Calculation definitions and interpretation}
\description{\if{latex}{\out{\sloppy}} Units, normalisation and implemented arithmetic for the public metrology functions.}
\details{\if{latex}{\out{\sloppy}}
Vector magnitude is \eqn{v=\sqrt{a_x^2+a_y^2+a_z^2}} in \eqn{g}.
\describe{
\item{Signed 1-\eqn{g} VM offset bias}{\if{latex}{\out{\sloppy}} Initial one-second mean VM minus 1 \eqn{g}, averaged over elapsed time up to and including five minutes. This is a VM offset relative to gravity, not a complete axis calibration.}
\item{Signed VM drift rate}{\if{latex}{\out{\sloppy}} Ordinary least-squares slope against elapsed hours, \eqn{g}/h. Extrapolation beyond the stationary recording requires an explicitly stated model.}
\item{Static noise floor}{\if{latex}{\out{\sloppy}} Maximum axis-specific residual SD after linear detrending over the selected stationary window; reporting in m\eqn{g} requires a factor of 1000. The first-five-minute maximum-axis SD is raw, not detrended. Raw sample SD uses denominator n-1; linearly detrended residual SD uses n-2. Static CV is 100 times SD divided by absolute mean, with a near-zero guard.}
\item{Allan deviation}{\if{latex}{\out{\sloppy}} For non-overlapping cluster means \eqn{\bar{x}_j}, \eqn{\sigma_A=\sqrt{\operatorname{mean}[(\bar{x}_{j+1}-\bar{x}_j)^2]/2}}. Cluster duration is in seconds and deviation is in \eqn{g}.}
\item{Dynamic response and signed VM bias}{\if{latex}{\out{\sloppy}} OLS of test VM on length-matched reference VM. Slope is dimensionless; intercept and mean signed test-minus-reference bias are in \eqn{g}. Scale-factor error is slope minus one; multiply it by 100 for percentage reporting. Absolute VM bias is the absolute value of the stage-mean signed difference, not the mean absolute paired difference.}
\item{VM integral non-linearity}{\if{latex}{\out{\sloppy}} 100 times the maximum absolute fitted residual divided by \eqn{\sqrt{3}F}, where F is the test-axis peak-to-peak span in \eqn{g}.}
\item{Trial-level composite error}{\if{latex}{\out{\sloppy}} 100 times the maximum absolute residual from the pooled response fit divided by \eqn{\sqrt{3}F/2}. This denominator differs from stage VM integral non-linearity by a factor of two. The implemented normalising span is not the nonnegative VM output range.}
\item{Within-stage epoch-mean VM CV}{\if{latex}{\out{\sloppy}} SD of within-stage epoch mean VM divided by their mean. The retained field \code{repeatability_error_cv} is a fraction. It is distinct from trial-to-trial VM repeatability CV, defined as 100 times SD divided by mean of stage-mean VM across repeated trials for the same unit, stage and pipeline.}
\item{Maximum-axis Allan minimum}{\if{latex}{\out{\sloppy}} Maximum across axes of their individual minimum Allan deviations over the evaluated averaging times; reporting in micro-\eqn{g} requires a factor of one million. This is distinct from the axis-specific curves.}
\item{ENMO}{\if{latex}{\out{\sloppy}} Epoch mean of \eqn{\max(v-1,0)}. Negative differences are truncated to zero per sample before averaging.}
\item{MAD}{\if{latex}{\out{\sloppy}} Epoch mean of \eqn{|v-\bar{v}|}, with \eqn{\bar{v}} defined within the epoch. ENMO and MAD are multiplied by 1000 for default m\eqn{g} output.}
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

\section{Assessment scope}{\if{latex}{\out{\sloppy}} Establish stationary or synchronous excitation conditions separately. Error estimates are not a complete uncertainty budget. WAM (\url{https://github.com/miltheo/wam}) supplies cohort aggregation, trial-to-trial repeatability, activation/deadband estimation and inter-device equivalence tests.}
\references{\if{latex}{\out{\sloppy}}
Joint Committee for Guides in Metrology (2012). International vocabulary of metrology: Basic and general concepts and associated terms, JCGM 200:2012. \doi{10.59161/JCGM200-2012}.

IEEE (2018). IEEE Std 2700-2017, Standard for Sensor Performance Parameter Definitions. \doi{10.1109/IEEESTD.2018.8277147}.

IEEE (2019). IEEE Std 1293-2018, Standard Specification Format Guide and Test Procedure for Linear Single-Axis, Nongyroscopic Accelerometers. \doi{10.1109/IEEESTD.2019.8653544}.

}
