\name{dynamic_metrology_report}
\alias{dynamic_metrology_report}
\title{Characterise response relative to a reference}
\description{\if{latex}{\out{\sloppy}} Estimate VM response slope, signed VM bias, integral non-linearity and pooled composite error against a reference.}
\usage{
dynamic_metrology_report(test_clips, ref_clips, test_axis_fsr_g =
    NULL, ref_axis_fsr_g = NULL, window_s = 5, epoch_time = c("end",
    "center", "start"), compute_entropy = TRUE, entropy_m = 2,
    entropy_r = NULL, entropy_tau = 1, verbose = FALSE, progress =
    TRUE, add_plot = TRUE, inspect_alignment = TRUE, align_hz = 10,
    align_max_lag_s = 7200, align_by = c("vm", "ax", "ay", "az"),
    align_plot_stages_n = 3, compute_stage_xcorr = FALSE,
    comp_plot_max_n = 20000L, comp_plot_ylim = NULL,
    attach_report = TRUE)
}
\arguments{
\item{test_clips}{\if{latex}{\out{\sloppy}} Test-device stage bundle returned by \code{clip_dynamic_stages}.}
\item{ref_clips}{\if{latex}{\out{\sloppy}} Reference-device stage bundle with matching stage names.}
\item{test_axis_fsr_g}{\if{latex}{\out{\sloppy}} Test-axis peak-to-peak span (\eqn{g}); NULL uses acquisition metadata. Supplied values must be finite positive scalars; invalid values error without fallback. Required for range-normalised errors. Example: 16 for +/-8 \eqn{g}.}
\item{ref_axis_fsr_g}{\if{latex}{\out{\sloppy}} Reference-axis peak-to-peak span (\eqn{g}); NULL uses acquisition metadata. Supplied values must be finite positive scalars. Missing range remains unavailable; test-error normalisation does not require it. Example: 16 for +/-8 \eqn{g}.}
\item{window_s}{\if{latex}{\out{\sloppy}} Within-stage VM averaging-bin duration (s), for repeatability_error_cv; separate from pooled sample-level fitting and trial-to-trial repeatability.}
\item{epoch_time}{\if{latex}{\out{\sloppy}} Retained end/center/start metadata setting; does not change within-stage repeatability bins.}
\item{compute_entropy}{\if{latex}{\out{\sloppy}} Compute diagnostic sample/approximate entropy through optional TSEntropies. Disabled/unavailable implementations return NA; not an equivalence decision.}
\item{entropy_m}{\if{latex}{\out{\sloppy}} Embedding dimension passed as dim to SampEn/ApEn; default two, on standardised VM.}
\item{entropy_r}{\if{latex}{\out{\sloppy}} Matching tolerance in standardised-VM units; NULL uses 0.2 times sample SD. Not an acceleration equivalence margin.}
\item{entropy_tau}{\if{latex}{\out{\sloppy}} Embedding lag passed to TSEntropies; default one sample, with duration dependent on sampling rate.}
\item{verbose}{\if{latex}{\out{\sloppy}} Print processing messages.}
\item{progress}{\if{latex}{\out{\sloppy}} Show a text progress bar.}
\item{add_plot}{\if{latex}{\out{\sloppy}} Return diagnostic ggplot objects.}
\item{inspect_alignment}{\if{latex}{\out{\sloppy}} Estimate diagnostic lags without correcting timestamps or response metrics.}
\item{align_hz}{\if{latex}{\out{\sloppy}} Uniform diagnostic resampling rate (Hz) for lag estimation; response/error inputs are unchanged.}
\item{align_max_lag_s}{\if{latex}{\out{\sloppy}} Maximum cross-correlation lag magnitude (s), default 7200. Repetitive excitation can produce ambiguous peaks; estimated lags are not applied.}
\item{align_by}{\if{latex}{\out{\sloppy}} Lag-inspection channel: vm (recombined axes), ax, ay or az.}
\item{align_plot_stages_n}{\if{latex}{\out{\sloppy}} Inactive compatibility argument; does not select stages or limit plots/calculations.}
\item{compute_stage_xcorr}{\if{latex}{\out{\sloppy}} Also estimate matched-stage lags when inspect_alignment is TRUE, separately from whole-trial diagnostics. No lag is applied.}
\item{comp_plot_max_n}{\if{latex}{\out{\sloppy}} Maximum displayed composite-trace samples, selected at evenly spaced indices. Fitting/errors use all data.}
\item{comp_plot_ylim}{\if{latex}{\out{\sloppy}} Composite-trace display limits: lower/upper \eqn{g} pair, or NULL for observed range. Fitting is unaffected.}
\item{attach_report}{\if{latex}{\out{\sloppy}} TRUE (default) appends a compact assessment to processing$reports$dynamic on returned data and the test_clips tables. FALSE adds no record. Input objects and reference tables are not modified in place.}
}
\value{\if{latex}{\out{\sloppy}} A list: \code{stages} (one row per paired stage), \code{overall} (pooled response/composite error), \code{plots} (ggplot objects, possibly empty), and \code{meta} (ranges, windows, stage names and alignment diagnostics). Slope and scale-factor error are dimensionless; intercept/bias/SD are in \eqn{g}. VM integral non-linearity (retained field \code{linearity_error_vs_reference}) and composite error are percentages. Within-stage epoch-mean VM CV (retained field \code{repeatability_error_cv}) and other CV/utilisation fields are fractions. Trial-to-trial repeatability requires repeated assessments and separate aggregation.}
\details{\if{latex}{\out{\sloppy}} OLS regresses test VM on reference VM. Unequal lengths use nearest positions on an evenly spaced sample-index grid, without timestamp alignment or continuous interpolation. Stage and pooled matching differ: the pooled reference is length-matched once after concatenation. Select synchronous, suitable stages and assess timing sensitivity; meta records pairing policy/range sources.

With F the test-axis peak-to-peak span, stage VM integral non-linearity uses \eqn{\sqrt{3}F}; pooled composite error uses \eqn{\sqrt{3}F/2}. Neither is the nonnegative VM output range. Absolute VM bias is abs(mean(test - reference)); percentage scale-factor error is 100(slope - 1).

Frequency diagnostics are included; frequency-domain features and inter-device equivalence tests are in WAM (\url{https://github.com/miltheo/wam}).}
\seealso{\code{\link{clip_dynamic_stages}}, \code{\link{m_dynamic_response}}, \code{\link{measurement-definitions}}}

\section{Returned stage fields}{
The returned \code{data} is the full test clip when available, otherwise its data table or the concatenated matched test stages. \code{test_clips} retains the input bundle structure with optional assessments attached to its tables and synchronised metadata. Attached results include stage/overall tables and test/reference diagnostics with reference provenance; shared record fields and retention follow \code{\link{common-data-format}}.

\if{latex}{\out{\sloppy}}
Here F is the test-axis peak-to-peak span; v and r are paired test/reference VM in \eqn{g}.
\describe{
\item{stage, rpm}{\if{latex}{\out{\sloppy}} Matched stage name and its parsed numerical RPM label.}
\item{fs_hz_test, fs_hz_ref, n}{\if{latex}{\out{\sloppy}} Timestamp-derived sampling frequencies in Hz and the number of test samples.}
\item{vm_mean, vm_standard_deviation, vm_mean_amplitude_deviation}{\if{latex}{\out{\sloppy}} Mean, sample SD and mean absolute deviation from the stage mean of v, all in \eqn{g}.}
\item{vm_coefficient_of_variation}{\if{latex}{\out{\sloppy}} Sample SD divided by mean VM, a fraction; undefined for zero mean.}
\item{signal_power_vm}{\if{latex}{\out{\sloppy}} Mean of squared sample VM, in \eqn{g} squared, including its mean component. This is a signal mean square, not physical mechanical power.}
\item{dominant_frequency}{\if{latex}{\out{\sloppy}} Maximum-magnitude Fourier bin of demeaned stage VM (Hz). The grid has floor(N/2) entries spanning zero to half the derived rate; N is the finite series length. This whole-stage diagnostic differs from five-second pooled-triaxial features.}
\item{dominant_frequency_magnitude}{\if{latex}{\out{\sloppy}} Maximum absolute Fourier coefficient of demeaned stage VM over the retained half spectrum. No sample-count, single-sided-amplitude or spectral-density normalisation is applied. It scales with record length; it is neither calibrated sinusoidal amplitude nor power spectral density.}
\item{sample_entropy, approximate_entropy}{\if{latex}{\out{\sloppy}} Dimensionless SampEn/ApEn of standardised VM with the supplied parameters; NA when disabled, unavailable or unsuccessful.}
\item{vm_bias_vs_reference}{\if{latex}{\out{\sloppy}} Mean signed v minus r, in \eqn{g}; not mean absolute paired error.}
\item{response_slope, response_intercept, scale_factor_error}{\if{latex}{\out{\sloppy}} OLS test-on-reference slope (dimensionless), intercept (\eqn{g}) and slope minus one (fraction).}
\item{linearity_error_vs_reference}{\if{latex}{\out{\sloppy}} 100 times the maximum absolute fitted residual divided by sqrt(3) F, a percentage.}
\item{snr_time_domain}{\if{latex}{\out{\sloppy}} Mean VM divided by sample SD of VM. A linear dimensionless ratio, not decibels or a separately measured signal/noise decomposition.}
\item{snr_frequency_domain}{\if{latex}{\out{\sloppy}} Squared dominant Fourier magnitude divided by the sum of squared remaining retained magnitudes. A linear dimensionless ratio; zero remainder gives NA.}
\item{repeatability_error_cv}{\if{latex}{\out{\sloppy}} SD divided by mean of within-stage window-mean VM, a fraction. It is not trial-to-trial repeatability.}
\item{full_scale_utilisation_axis}{\if{latex}{\out{\sloppy}} Maximum absolute scalar axis observation divided by F, a fraction. The denominator is the full peak-to-peak span, not the positive axis limit F/2.}
\item{full_scale_utilisation_vm}{\if{latex}{\out{\sloppy}} Maximum VM divided by sqrt(3) F, a fraction. It uses the implemented normalising span, not the maximum nonnegative VM supported by a symmetric three-axis sensor.}
\item{dead_band, activation_threshold}{\if{latex}{\out{\sloppy}} Unestimated NA placeholders.}
\item{alignment_lag_s}{\if{latex}{\out{\sloppy}} Optional stage cross-correlation lag in seconds; not applied to sample timestamps or errors.}
}
The one-row \code{overall} table returns \code{composite_error} (100 times pooled maximum absolute fitted residual divided by sqrt(3) F/2), \code{response_slope}, \code{response_intercept} and \code{scale_factor_error}. Pooled fitting concatenates matched stages, with distinct reference length matching as described above. Diagnostic plots/metadata do not alter fits.
}
