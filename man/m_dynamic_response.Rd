\name{m_dynamic_response}
\alias{m_dynamic_response}
\title{Compute vector-magnitude response and reference-dependent error}
\description{\if{latex}{\out{\sloppy}} OLS test-on-reference VM response with signed bias and range-normalised residual errors.}
\usage{
m_dynamic_response(test, reference, axis_fsr_g)
}
\arguments{
\item{test}{\if{latex}{\out{\sloppy}} Test-device vector magnitude in \eqn{g}, or an acceleration table/bundle converted to vector magnitude.}
\item{reference}{\if{latex}{\out{\sloppy}} Reference vector magnitude in \eqn{g}, or an acceleration table/bundle. Nearest evenly spaced reference indices match the test length.}
\item{axis_fsr_g}{\if{latex}{\out{\sloppy}} Required finite positive scalar. Configured single-axis peak-to-peak span in \eqn{g}. The VM normalising span is sqrt(3) times this value.}
}
\value{\if{latex}{\out{\sloppy}} A list with vm_bias_vs_reference (signed mean difference, \eqn{g}), response_slope (dimensionless), response_intercept (\eqn{g}), scale_factor_error (slope minus one), linearity_error_vs_reference and composite_error (percentages using the full and half normalising spans respectively), maximum_absolute_residual_g, and predicted_vm_g (fitted test VM values in \eqn{g}).}
\details{\if{latex}{\out{\sloppy}} Uses the OLS and nearest-index pairing in \code{\link{dynamic_metrology_report}}. Integral non-linearity = 100 times maximum absolute residual/VM normalising span; composite error uses half that span. The latter represents trial composite error only for complete pooled-trial vectors. No calibration, timestamp correction or uncertainty budget is supplied.}
\seealso{\code{\link{dynamic_metrology_report}}, \code{\link{measurement-definitions}}}

\examples{
reference_vm <- seq(.1, 2, length.out = 100)
test_vm <- .02 + 1.1 * reference_vm
response <- m_dynamic_response(test_vm, reference_vm, axis_fsr_g = 16)
response[c("response_slope", "response_intercept", "composite_error")]
}
