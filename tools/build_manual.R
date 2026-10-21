# The canonical documentation is man/*.Rd; this builds the standard R manual.
# Usage: Rscript tools/build_manual.R [OUTPUT.pdf]
args <- commandArgs(trailingOnly = TRUE)
script <- sub("^--file=", "", grep("^--file=", commandArgs(), value = TRUE)[1L])
root <- dirname(dirname(normalizePath(script, winslash = "/", mustWork = TRUE)))
output <- if (length(args)) args[[1L]] else file.path(root, "docs/metronautica-reference.pdf")
output <- file.path(normalizePath(dirname(output), winslash = "/", mustWork = TRUE), basename(output))
r <- file.path(R.home("bin"), if (.Platform$OS.type == "windows") "R.exe" else "R")
status <- system2(r, c("CMD", "Rd2pdf", "--no-preview", "--force",
    paste0("--output=", shQuote(output)), shQuote(root)))
if (status != 0L || !file.exists(output)) stop("Reference manual build failed")
cat("Built ", output, "\n", sep = "")
