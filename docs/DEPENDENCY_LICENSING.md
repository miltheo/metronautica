# Software and dependency licences

[Workflow](../README.md#processing-workflow) · [HTML guide](index.html) · [HTML reference](reference.html) · [PDF reference](metronautica-reference.pdf)

Metronautica's original software is GPL version 3 only (`GPL-3` in DESCRIPTION).
Dependencies remain separately licensed; they are not included or relicensed by
this repository's licence. Preserve their copyright and licence notices if
redistributing their source or binaries.

The `signal` 1.8-1 package declares GPL-2 in its metadata. The inspected
`butter`, `filtfilt`, `filter`, `sftrans`, `bilinear` and `poly` source files
explicitly permit version 2 **or any later version**, providing a GPL-3 option
for the filtering path used here. This finding does not relicense unrelated
files in that dependency.

Activity counts are implemented directly in `R/m_agcounts.R`; neither the R
agcounts package nor the Python reference is a runtime/optional dependency.
The published numerical coefficients are acknowledged from ActiGraph/agcounts
(GPL-3.0), pinned commit 3137c9b9a26539ae2d9645d396586fe15faece59.
The original R implementation is distributed under this package's GPL-3 licence.
External comparison software remains separately licensed.

See the official [signal source](https://cran.r-project.org/src/contrib/signal_1.8-1.tar.gz),
[GNU compatibility guidance](https://www.gnu.org/licenses/gpl-faq.en.html#v2v3Compatibility)
and each dependency's licence. Native-recording distribution terms are separate.
