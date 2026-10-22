\name{m_dynamic_response}
\alias{m_dynamic_response}
\title{Compute vector-magnitude response and reference-dependent error}
\description{\if{latex}{\out{\sloppy}} Compute vector-magnitude response and reference-dependent error.}
\usage{
m_dynamic_response(test, reference, axis_fsr_g)
}
\arguments{
\item{test}{\if{latex}{\out{\sloppy}} Test-device vector magnitude in g, or an acceleration table/bundle converted to vector magnitude.}
\item{reference}{\if{latex}{\out{\sloppy}} Reference vector magnitude in g, or an acceleration table/bundle. Nearest evenly spaced reference indices match the test length.}
\item{axis_fsr_g}{\if{latex}{\out{\sloppy}} Required finite positive scalar. Configured single-axis peak-to-peak span in g. The VM normalising span is sqrt(3) times this value.}
}
\value{\if{latex}{\out{\sloppy}} A list with vm_bias_vs_reference (signed mean difference, g), response_slope (dimensionless), response_intercept (g), scale_factor_error (slope minus one), linearity_error_vs_reference and composite_error (percentages using the full and half normalising spans respectively), maximum_absolute_residual_g, and predicted_vm_g (fitted test VM values in g).}
\details{\if{latex}{\out{\sloppy}} The least-squares test-VM-on-reference-VM regression and nearest-index length matching are the same calculations used by dynamic_metrology_report. The signed bias is the mean test-minus-reference VM. Scale-factor error is slope minus one, dimensionless. Integral non-linearity uses the maximum absolute residual divided by the VM normalising span, times 100. The composite-error field uses half that span; it represents trial composite error only when the supplied vectors contain the complete pooled trial assessment. It is not a measurement-uncertainty budget. This function applies no new calibration or timestamp correction.}
\seealso{\code{\link{metronautica-package}}}

\section{Implementation}{\if{latex}{\out{\sloppy}} Implemented by \code{m_dynamic_response} in \code{R/m_dynamic.R}. See \code{\link{implementation-guide}} for the framework and function map.}

\examples{
reference_vm <- seq(.1, 2, length.out = 100)
test_vm <- .02 + 1.1 * reference_vm
response <- m_dynamic_response(test_vm, reference_vm, axis_fsr_g = 16)
response[c("response_slope", "response_intercept", "composite_error")]
}
