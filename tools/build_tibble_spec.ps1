param([string]$PythonExecutable = 'python')

# Requires python-docx and Microsoft Word; runs locally without network access.
$ErrorActionPreference = 'Stop'
$repoRoot = Split-Path -Parent $PSScriptRoot
$docxPath = Join-Path $repoRoot 'data-contract/0.1.0/Metronautica_Tibble_0.1.0.docx'
$pdfPath = [System.IO.Path]::ChangeExtension($docxPath, '.pdf')
& $PythonExecutable (Join-Path $PSScriptRoot 'build_tibble_spec.py')
if ($LASTEXITCODE -ne 0) { throw 'Tibble specification generation failed.' }

$word = New-Object -ComObject Word.Application
$word.Visible = $false
$word.DisplayAlerts = 0
try {
    $document = $word.Documents.Open($docxPath, $false, $true)
    try {
        # Create PDF bookmarks from the document's heading hierarchy.
        $document.ExportAsFixedFormat($pdfPath, 17, $false, 0, 0, 1, 1, 0,
            $true, $true, 1, $true, $true, $false)
    } finally { $document.Close(0) }
} finally { $word.Quit() }
Write-Output "Built $pdfPath"
