# Documentation

The root [README](../README.md) is the entry point. The HTML guide renders that
README and the Markdown guides; the HTML and PDF references both use `man/*.Rd`.
Edit those sources, then rebuild rather than editing generated HTML.

## Repository roles

`R/` and `man/` define the installed interface. `inst/extdata/` supplies installed
offline data and the sample catalogue; R installs its contents at `extdata/`.
`tests/` contains numerical/interface checks. `tools/` contains developer utilities;
ordinary users load the package with `library(metronautica)`.

The R help examples are the maintained example-code source. The HTML builder
extracts them into Getting Started and `examples/quick_start.R`. Do not edit those
generated code blocks independently. The recording guide covers processing choices;
the measurement-definitions page is an index into canonical R help.

## Build

From the repository root, with R available:

```sh
Rscript tools/build_html.R
Rscript tools/build_manual.R
```

To regenerate the real-recording plot previews after installing the package:

```sh
Rscript tools/render_examples.R "path/to/wam/samples"
```

This explicitly processes the 24-hour static sample and full ten-stage dynamic
trial, writing two PNG previews under `docs/assets/examples/`. The catalogue and
compressed attachments must be available locally. Then rebuild the HTML.
Run `Rscript tools/validate.R` from the repository root for the package checks.

HTML generation requires R >= 4.5 with `tools::pkg2HTML()`, plus `commonmark` and
`V8` for Markdown and R's equation conversion. These are documentation-build
tools, not package runtime dependencies. Install missing tools explicitly with
`install.packages(c("commonmark", "V8"))`.

Open `docs/index.html` in a browser. Diagram regions provide keyboard-accessible
links and hover descriptions. The reference has a filterable contents list.
Equations use KaTeX from a CDN; plain equation source remains visible if it is
unavailable. All explanatory content and navigation are local.

## GitHub display and hosting

The GitHub README shows the diagram image and linked stage navigation. Hover
titles on links supplement the visible format and data-contract sections; they
are not required to understand or use the package.

GitHub's repository viewer shows HTML source. To serve the generated HTML later,
configure GitHub Pages to publish the `docs/` directory from the chosen branch.
Then link the README to the resulting Pages URL. No hosting is enabled by the
build script. Local HTML use requires no hosting.

The workflow asset is `assets/workflow-dark.svg`. Its interactive regions are
defined in `tools/build_html.R`; update their coordinates if the diagram changes.
The tibble, static rectangle and connecting arrow share x = 840 in its view box.

## Files

| Source | Browser output |
|---|---|
| `README.md` at repository root | `index.html` |
| `man/*.Rd` | `reference.html` |
| `GETTING_STARTED.md` | `getting-started.html` |
| `REAL_DATA_EXAMPLES.md` | `recording-examples.html` |
| `MEASUREMENT_DEFINITIONS.md` | `measurement-definitions.html` |
| `ACTIGRAPH_COUNTS.md` | `activity-counts.html` |
| `DEPENDENCY_LICENSING.md` | `dependency-licensing.html` |

`validation/` retains activity-count benchmark tables. Function calculations and
R help are unchanged by generating this documentation.
