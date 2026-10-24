# Render canonical recording examples.
# Rscript tools/render_examples.R SAMPLE_DIR [OUTPUT_DIR]
args <- commandArgs(trailingOnly = TRUE)
traces_only <- "--traces-only" %in% args
args <- args[args != "--traces-only"]
script <- sub("^--file=", "", grep("^--file=", commandArgs(), value = TRUE)[1L])
root <- dirname(dirname(normalizePath(script, winslash = "/", mustWork = TRUE)))
if (!length(args)) stop("Supply WAM's samples directory containing the catalogue and compressed recordings.")
sample_dir <- normalizePath(args[[1L]], winslash = "/", mustWork = TRUE)
output <- if (length(args) > 1L) args[[2L]] else file.path(root, "docs/assets/examples")
dir.create(output, recursive = TRUE, showWarnings = FALSE)
output <- normalizePath(output, winslash = "/", mustWork = TRUE)
options(metronautica.sample_dir = sample_dir)
e <- new.env(parent = globalenv())

# Render native signal traces ----
for (package in c("plotly", "htmlwidgets")) {
    if (!requireNamespace(package, quietly = TRUE))
        stop("Trace rendering requires ", package, ".")
}
chrome <- Sys.getenv("CHROMOTE_CHROME")
if (!nzchar(chrome)) {
    candidates <- c(Sys.which(c("google-chrome", "chromium", "chrome")),
        "C:/Program Files/Google/Chrome/Application/chrome.exe",
        "C:/Program Files (x86)/Microsoft/Edge/Application/msedge.exe")
    chrome <- candidates[nzchar(candidates) & file.exists(candidates)][1L]
}
if (is.na(chrome) || !file.exists(chrome))
    stop("Set CHROMOTE_CHROME to a Chrome/Chromium executable for trace previews.")
work <- tempfile("metronautica-traces-")
dir.create(work)
work <- normalizePath(work, winslash = "/", mustWork = TRUE)
lines <- readLines(file.path(root, "examples/recording_traces.R"), warn = FALSE)
starts <- grep("^# (Static trace|Dynamic trace|Signal diagnostics|Feature extraction|Processed feature trace)$", lines)
trace_block <- function(i) {
    end <- if (i < length(starts)) starts[i + 1L] - 1L else length(lines)
    parse(text = lines[(starts[i] + 1L):end])
}
capture_trace <- function(plot, name) {
    html <- file.path(work, paste0(name, ".html"))
    png <- file.path(output, paste0(name, ".png"))
    plot$width <- 1800
    plot$height <- 600
    plot <- plotly::layout(plot, autosize = FALSE, showlegend = TRUE)
    htmlwidgets::saveWidget(plot, html, selfcontained = FALSE,
        libdir = file.path(work, "lib"))
    browser_args <- c("--headless=new", "--disable-gpu", "--no-first-run",
        "--no-default-browser-check", "--allow-file-access-from-files",
        "--hide-scrollbars", "--run-all-compositor-stages-before-draw",
        "--virtual-time-budget=10000", "--window-size=1800,650",
        paste0("--user-data-dir=", file.path(work, paste0(name, "-profile"))),
        paste0("--screenshot=", png), utils::URLencode(paste0("file:///", html)))
    status <- system2(chrome, shQuote(browser_args), stdout = file.path(work, paste0(name, ".log")),
        stderr = file.path(work, paste0(name, ".log")))
    if (status != 0L || !file.exists(png)) {
        log <- file.path(work, paste0(name, ".log"))
        details <- if (file.exists(log)) paste(tail(readLines(log, warn = FALSE), 8L), collapse = "\n") else ""
        stop("Trace preview failed: ", name, " (browser exit ", status, ").\n", details)
    }
}
local({
    previous <- setwd(tempdir())
    on.exit(setwd(previous), add = TRUE)
    eval(quote(library(metronautica)), e)
    static_trace <- eval(trace_block(1L), e)
    capture_trace(static_trace, "static-trace")
    dynamic_trace <- eval(trace_block(2L), e)
    capture_trace(dynamic_trace, "dynamic-trace")
    eval(trace_block(3L), e)
    eval(trace_block(4L), e)
    processed_trace <- eval(trace_block(5L), e)
    capture_trace(processed_trace, "processed-trace")
})

# Show actual parsed example values ----
preview <- head(e$motion, 3L)
rows <- vapply(seq_len(nrow(preview)), function(i) {
    paste0("| ", format(preview$time[i], "%Y-%m-%d %H:%M:%OS3", tz = "UTC"), " | ",
        paste(sprintf("%.6f", unlist(preview[i, c("ax_g", "ay_g", "az_g")], use.names = FALSE)), collapse = " | "), " |")
}, character(1))
values <- c("First three parsed observations (display rounded to six decimals):", "",
    "| `time` (UTC) | `ax_g` | `ay_g` | `az_g` |", "|---|---:|---:|---:|", rows, "",
    "Selected diagnostics for this recording:", "", "| Field | Value |", "|---|---:|",
    paste0("| `n_samples` | ", format(e$qc$n_samples, big.mark = ",", scientific = FALSE), " |"),
    paste0("| `median_dt_ms` | ", sprintf("%.4f", e$qc$median_dt_ms), " |"),
    paste0("| `near_limit_pct` | ", sprintf("%.4f", e$qc$near_limit_pct), " |"))
guide <- file.path(root, "docs/GETTING_STARTED.md")
text <- paste(readLines(guide, warn = FALSE, encoding = "UTF-8"), collapse = "\n")
begin <- "<!-- OUTPUT:trace:start -->"
end <- "<!-- OUTPUT:trace:end -->"
a <- regexpr(begin, text, fixed = TRUE)[1L]
b <- regexpr(end, text, fixed = TRUE)[1L]
if (a < 0L || b < a) stop("Missing trace output markers.")
text <- paste0(substr(text, 1L, a + nchar(begin) - 1L), "\n",
    paste(values, collapse = "\n"), "\n", substring(text, b))
writeLines(enc2utf8(text), guide, useBytes = TRUE)
cat("Rendered raw/processed traces and their parsed-data/diagnostic preview.\n")
if (traces_only) quit(status = 0L)

# Write sample outputs under tempdir().
local({
    before <- setwd(tempdir())
    on.exit(setwd(before), add = TRUE)
    sys.source(file.path(root, "examples/quick_start.R"), envir = e)
})
save_pair <- function(left, right, path) {
    grDevices::png(path, width = 1800, height = 700, res = 160)
    on.exit(grDevices::dev.off(), add = TRUE)
    grid::grid.newpage()
    grid::pushViewport(grid::viewport(layout = grid::grid.layout(1L, 2L)))
    print(left, vp = grid::viewport(layout.pos.row = 1L, layout.pos.col = 1L))
    print(right, vp = grid::viewport(layout.pos.row = 1L, layout.pos.col = 2L))
}
save_pair(e$static_result$drift_plot +
    ggplot2::labs(title = "LEAP: VM drift"), e$static_result$allan_plot +
        ggplot2::labs(title = "LEAP: Allan deviation"), file.path(output, "static-characterisation.png"))
save_pair(e$dynamic_result$plots$vm_mean_vs_rpm, e$dynamic_result$plots$linearity_vs_rpm, file.path(output,
    "dynamic-characterisation.png"))
cat("Rendered full 24-hour static and ten-stage dynamic examples for LEAP.\n")

# Render the maintained comparison recipe.
local({
    before <- setwd(tempdir())
    on.exit(setwd(before), add = TRUE)
    sys.source(file.path(root, "examples", "feature_comparison.R"), envir = e)
})
ggplot2::ggsave(file.path(output, "feature-comparison.png"), e$comparison_plot, width = 12, height = 7,
    dpi = 180, bg = "white")
cat("Rendered combined feature comparison over the same ten-stage trial.\n")
