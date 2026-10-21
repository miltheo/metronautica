library(metronautica)
e <- asNamespace("metronautica")
checks <- list()
check <- function(name, ok) {
    checks[[length(checks) + 1L]] <<- data.frame(check = name, passed = isTRUE(ok))
    if (!isTRUE(ok)) stop("FAILED: ", name)
}
fails <- function(expr) inherits(try(force(expr), silent = TRUE), "try-error")
# A synthetic signature tests the compatibility contract without decoding a file.
decoder <- function(filename, max_samples, scale_factor, sample_rate, start_time,
                    batch_begin = 0L, batch_end = 0L, verbose = FALSE,
                    debug = FALSE, impute_zeroes = FALSE) NULL
check("validated bounded signature is returned unchanged",
      identical(e$check_gt3x_bounded_interface("1.2.0", decoder), decoder))
check("unvalidated bounded decoder version is rejected",
      fails(e$check_gt3x_bounded_interface("1.2.1", decoder)))
check("missing bounded decoder is rejected",
      fails(e$check_gt3x_bounded_interface("1.2.0", NULL)))
changed <- decoder
formals(changed)$impute_zeroes <- TRUE
check("changed imputation default is rejected",
      fails(e$check_gt3x_bounded_interface("1.2.0", changed)))
formals(changed) <- formals(changed)[-1L]
check("changed bounded decoder arguments are rejected",
      fails(e$check_gt3x_bounded_interface("1.2.0", changed)))
if (requireNamespace("read.gt3x", quietly = TRUE) &&
    utils::packageVersion("read.gt3x") == "1.2.0") {
    actual <- get("parseGT3X", asNamespace("read.gt3x"))
    check("installed validated decoder passes the guard",
          identical(e$check_gt3x_bounded_interface("1.2.0", actual), actual))
}
d <- data.frame(elapsed_h = (0:120) / 3600,
                vm_mean = 1 + (0:120) / 3600 * .001 + sin(0:120) * 1e-5)
fit <- stats::lm(vm_mean ~ elapsed_h, d)
before <- d
warnings <- character()
p <- withCallingHandlers(e$plot_static_drift_vm(d, fit), warning = function(w) {
    warnings <<- c(warnings, conditionMessage(w)); invokeRestart("muffleWarning")
})
check("static drift plot has no ignored-label-argument warning", !length(warnings))
check("static drift plot preserves supplied data", identical(d, before) && identical(p$data, before))
# The label argument was already ignored by annotate() on ggplot2 >= 4.0.0.
check("static drift label text is unchanged",
      identical(p$layers[[3]]$aes_params$label,
                sprintf("drift = %s g/h", formatC(unname(stats::coef(fit)[2]), format = "e", digits = 2))))
cat(length(checks), "compatibility checks passed\n")
