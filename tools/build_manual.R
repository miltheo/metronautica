# Build standard manual from man/.
# Usage: Rscript tools/build_manual.R [OUTPUT.pdf]
args <- commandArgs(trailingOnly = TRUE)
script <- sub("^--file=", "", grep("^--file=", commandArgs(), value = TRUE)[1L])
root <- dirname(dirname(normalizePath(script, winslash = "/", mustWork = TRUE)))
output <- if (length(args)) args[[1L]] else file.path(root, "docs/metronautica-reference.pdf")
output <- file.path(normalizePath(dirname(output), winslash = "/", mustWork = TRUE), basename(output))
build_manual <- function() {
# Extend bookmarks without changing pages.
    work <- tempfile("metronautica-manual-")
    dir.create(work)
    tex <- file.path(work, "reference.tex")
    previous <- Sys.getenv("R_PAPERSIZE", unset = NA_character_)
    on.exit(if (is.na(previous)) Sys.unsetenv("R_PAPERSIZE") else Sys.setenv(R_PAPERSIZE = previous))
    if (is.na(previous) || !nzchar(previous)) Sys.setenv(R_PAPERSIZE = getOption("papersize", "a4"))
# Use R's standard manual generator.
    tools:::.Rd2pdf(pkgdir = root, outfile = tex, title = "",
        files_or_dir = root, OSdir = .Platform$OS.type)
    lines <- readLines(tex, warn = FALSE, encoding = "UTF-8")
    navigation <- c("\\makeatletter", "\\newcounter{metronauticaSection}",
        "\\let\\metronauticaRdsection\\Rdsection",
        "\\renewcommand{\\Rdsection}[1]{%",
        "  \\if\\relax\\detokenize{#1}\\relax%",
        "    \\metronauticaRdsection{#1}%",
        "  \\else%",
        "    \\stepcounter{metronauticaSection}%",
        "    \\metronauticaRdsection{#1\\pdfbookmark[2]{#1}{metronautica-section-\\arabic{metronauticaSection}}}%",
        "  \\fi}", "\\makeatother")
    begin <- match("\\begin{document}", lines)
    if (is.na(begin)) stop("Manual document start not found")
    lines <- append(lines, navigation, after = begin - 1L)
    writeLines(enc2utf8(lines), tex, useBytes = TRUE)
    previous_directory <- getwd()
    on.exit(setwd(previous_directory), add = TRUE)
    setwd(work)
    tools::texi2pdf(tex, clean = TRUE, quiet = FALSE, texi2dvi = "emulation")
    built <- sub("\\.tex$", ".pdf", tex)
    if (!file.exists(built) || !file.copy(built, output, overwrite = TRUE))
        stop("Reference manual build failed")
}
build_manual()
cat("Built ", output, "\n", sep = "")
