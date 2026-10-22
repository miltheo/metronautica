\name{dynamic_metrology_report}
\alias{dynamic_metrology_report}
\title{Characterise response relative to a reference}
\description{\if{latex}{\out{\sloppy}} Compute paired-stage response and full-range error metrics from explicitly supplied device and reference signals.}
\usage{
dynamic_metrology_report(test_clips, ref_clips, test_axis_fsr_g =
    NULL, ref_axis_fsr_g = NULL, window_s = 5, epoch_time = c("end",
    "center", "start"), compute_entropy = TRUE, entropy_m = 2,
    entropy_r = NULL, entropy_tau = 1, verbose = FALSE, progress =
    TRUE, add_plot = TRUE, inspect_alignment = TRUE, align_hz = 10,
    align_max_lag_s = 7200, align_by = c("vm", "ax", "ay", "az"),
    align_plot_stages_n = 3, compute_stage_xcorr = FALSE,
    comp_plot_max_n = 20000L, comp_plot_ylim = NULL)
}
\arguments{
\item{test_clips}{\if{latex}{\out{\sloppy}} Test-device stage bundle returned by \code{clip_dynamic_stages}.}
\item{ref_clips}{\if{latex}{\out{\sloppy}} Reference-device stage bundle with matching stage names.}
\item{test_axis_fsr_g}{\if{latex}{\out{\sloppy}} A supplied span must be a finite positive scalar; invalid supplied values error rather than falling back to metadata. A valid test span is required for range-normalised outcomes. Axis peak-to-peak spans in \eqn{g}; NULL uses acquisition metadata. Supply 16 for +/-8 \eqn{g}.}
\item{ref_axis_fsr_g}{\if{latex}{\out{\sloppy}} A supplied span must be a finite positive scalar. Missing reference range is retained as unavailable when no valid metadata exists; it is not needed to normalise test-device errors. Axis peak-to-peak spans in \eqn{g}; NULL uses acquisition metadata. Supply 16 for +/-8 \eqn{g}.}
\item{window_s}{\if{latex}{\out{\sloppy}} Duration in seconds of within-stage VM averaging bins used for the repeatability_error_cv diagnostic. It is separate from the pooled sample-level response fit and the trial-to-trial repeatability calculation.}
\item{epoch_time}{\if{latex}{\out{\sloppy}} Retained metadata setting end/center/start. In this report it does not change the epoch bins used for within-stage repeatability.}
\item{compute_entropy}{\if{latex}{\out{\sloppy}} Logical; calculate sample and approximate entropy using optional TSEntropies. Disabled or unavailable implementations return NA; this is a diagnostic, not an equivalence decision.}
\item{entropy_m}{\if{latex}{\out{\sloppy}} Embedding dimension for entropy calculations, passed as dim to SampEn/ApEn. Default two on the standardised VM series.}
\item{entropy_r}{\if{latex}{\out{\sloppy}} Entropy matching tolerance in units of the standardised VM series. NULL uses 0.2 times its sample SD. This is not an acceleration equivalence margin.}
\item{entropy_tau}{\if{latex}{\out{\sloppy}} Sample lag between embedded entropy coordinates, passed as lag to TSEntropies. Default one sample; its time duration depends on sampling rate.}
\item{verbose}{\if{latex}{\out{\sloppy}} Logical; print processing messages. Does not change calculations.}
\item{progress}{\if{latex}{\out{\sloppy}} Logical; display a text progress bar. Does not change calculations.}
\item{add_plot}{\if{latex}{\out{\sloppy}} Generate diagnostic ggplot objects.}
\item{inspect_alignment}{\if{latex}{\out{\sloppy}} Enable alignment diagnostics. These estimate lags without correcting timestamps or response metrics.}
\item{align_hz}{\if{latex}{\out{\sloppy}} Frequency in Hz of the uniformly resampled diagnostic signal used for lag estimation. It does not resample the data used in response/error calculations.}
\item{align_max_lag_s}{\if{latex}{\out{\sloppy}} Maximum lag magnitude in seconds searched by diagnostic cross-correlation; default 7200. Repetitive excitation can yield ambiguous peaks. The estimated lag is not applied as a timestamp correction.}
\item{align_by}{\if{latex}{\out{\sloppy}} Diagnostic channel: vm recombines all axes as vector magnitude; ax, ay or az selects one axis. This choice affects lag inspection only.}
\item{align_plot_stages_n}{\if{latex}{\out{\sloppy}} Retained compatibility argument; currently does not limit plotting or change calculations. It is not an active stage-selection control.}
\item{compute_stage_xcorr}{\if{latex}{\out{\sloppy}} Logical; also estimate a lag separately for each matched stage when inspect_alignment is TRUE. Whole-trial lag diagnostics are separate; no lag is applied automatically.}
\item{comp_plot_max_n}{\if{latex}{\out{\sloppy}} Maximum number of samples displayed in composite-response diagnostic plots, selected at evenly spaced indices. Fits and errors continue to use the full data.}
\item{comp_plot_ylim}{\if{latex}{\out{\sloppy}} NULL uses the observed composite-trace plotting range; otherwise a numeric lower/upper \eqn{g} pair controls the displayed vertical interval. It does not exclude samples from fitting.}
}
\value{\if{latex}{\out{\sloppy}} A list: \code{stages} (one row per paired stage), \code{overall} (pooled response/composite error), \code{plots} (ggplot objects, possibly empty), and \code{meta} (ranges, windows, stage names and alignment diagnostics). Slope and scale-factor error are dimensionless; intercept/bias/SD are in \eqn{g}. VM integral non-linearity (retained field \code{linearity_error_vs_reference}) and composite error are percentages. Within-stage epoch-mean VM CV (retained field \code{repeatability_error_cv}) and other CV/utilisation fields are fractions. Trial-to-trial repeatability requires repeated assessments and separate aggregation.}
\details{\if{latex}{\out{\sloppy}} Test vector magnitude is regressed on reference vector magnitude by ordinary least squares. Unequal lengths are matched by nearest positions on an evenly spaced sample-index grid, not by timestamp alignment or continuous interpolation. Stage matching is separate from pooled matching: pooled reference concatenation is length-matched once after concatenation. The caller must select synchronous, suitable stages and assess timing sensitivity. The pairing policy and measurement-range sources are reported in meta. The stage VM integral non-linearity denominator is \eqn{\sqrt{3}F}; the composite denominator is \eqn{\sqrt{3}F/2}, where F is test-axis peak-to-peak span. This implemented VM normalising span is not the nonnegative VM output range. Signed VM bias is the stage mean test-minus-reference difference; take its absolute value for absolute VM bias and convert slope minus one to percent for scale-factor error. Whole-stage VM FFT diagnostics are distinct from five-second pooled-triaxial spectral feature estimators. \code{dead_band} and \code{activation_threshold} are unestimated NA placeholders. Dynamic frequency diagnostics remain available; frequency-domain feature extraction and inter-device equivalence analyses are provided by WAM (\url{https://github.com/miltheo/wam}).}
\seealso{\code{\link{metronautica-package}}}

\section{Implementation}{\if{latex}{\out{\sloppy}} Implemented by \code{dynamic_metrology_report} in \code{R/m_dynamic.R}. See \code{\link{implementation-guide}} for the framework and function map.}

\section{Returned stage fields}{
\if{latex}{\out{\sloppy}}
Let F denote the configured test-axis peak-to-peak span, v the test VM in \eqn{g}, and r the length-matched reference VM. Fields use the existing stage-level calculations.
\describe{
\item{stage, rpm}{Matched stage name and its parsed numerical RPM label.}
\item{fs_hz_test, fs_hz_ref, n}{Timestamp-derived sampling frequencies in Hz and the number of test samples.}
\item{vm_mean, vm_standard_deviation, vm_mean_amplitude_deviation}{Mean, sample SD and mean absolute deviation from the stage mean of v, all in \eqn{g}.}
\item{vm_coefficient_of_variation}{Sample SD divided by mean VM, a fraction; undefined for zero mean.}
\item{signal_power_vm}{Mean of squared sample VM, in \eqn{g} squared, including its mean component. This is a signal mean square, not physical mechanical power.}
\item{dominant_frequency}{Frequency label in Hz of the maximum retained Fourier magnitude of demeaned stage VM. The retained frequency grid spans zero to half the derived rate across floor(N/2) entries, where N is the finite demeaned series length. This whole-stage diagnostic is separate from five-second pooled-triaxial feature frequency estimates.}
\item{dominant_frequency_magnitude}{Maximum unnormalised absolute discrete Fourier coefficient of demeaned stage VM over the retained half spectrum. It scales with record length; no division by sample count, single-sided amplitude scaling or spectral-density normalisation is applied. It is not a calibrated sinusoidal amplitude or a power spectral density.}
\item{sample_entropy, approximate_entropy}{Dimensionless SampEn/ApEn of standardised VM with the supplied parameters; NA when disabled, unavailable or unsuccessful.}
\item{vm_bias_vs_reference}{Mean signed v minus r, in \eqn{g}; not mean absolute paired error.}
\item{response_slope, response_intercept, scale_factor_error}{OLS test-on-reference slope (dimensionless), intercept (\eqn{g}) and slope minus one (fraction).}
\item{linearity_error_vs_reference}{100 times the maximum absolute fitted residual divided by sqrt(3) F, a percentage.}
\item{snr_time_domain}{Mean VM divided by sample SD of VM. A linear dimensionless ratio, not decibels or a separately measured signal/noise decomposition.}
\item{snr_frequency_domain}{Squared dominant Fourier magnitude divided by the sum of squared remaining retained magnitudes. A linear dimensionless ratio; zero remainder gives NA.}
\item{repeatability_error_cv}{SD divided by mean of within-stage window-mean VM, a fraction. It is not trial-to-trial repeatability.}
\item{full_scale_utilisation_axis}{Maximum absolute scalar axis observation divided by F, a fraction. The denominator is the full peak-to-peak span, not the positive axis limit F/2.}
\item{full_scale_utilisation_vm}{Maximum VM divided by sqrt(3) F, a fraction. It uses the implemented normalising span, not the maximum nonnegative VM supported by a symmetric three-axis sensor.}
\item{dead_band, activation_threshold}{Unestimated NA placeholders.}
\item{alignment_lag_s}{Optional stage cross-correlation lag in seconds; not applied to sample timestamps or errors.}
}
The one-row \code{overall} table contains \code{composite_error} (100 times the pooled maximum absolute fitted residual divided by sqrt(3) F/2), \code{response_slope}, \code{response_intercept} and \code{scale_factor_error}. Pooled fitting uses concatenated matched stages. See Details for its distinct reference length matching. The diagnostic plots and metadata accompany these tables; they do not alter the response fits.
}
