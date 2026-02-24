# Reads a list of changed .vi files from changed-files.txt (written by the workflow),
# then uses LabVIEWCLI CreateComparisonReport to compare the base-branch version
# (vi-base\) against the head version and generates an HTML report for each file.

$CHANGED_FILES_FILE = "C:\workspace\changed-files.txt"
$REPORT_DIR = "C:\workspace\vi-compare-reports"

New-Item -ItemType Directory -Force -Path $REPORT_DIR | Out-Null

if (-not (Test-Path $CHANGED_FILES_FILE)) {
    Write-Host "No changed-files.txt found. Exiting."
    exit 0
}

$files = Get-Content $CHANGED_FILES_FILE |
    ForEach-Object { $_.Trim() } |
    Where-Object { $_ -ne "" -and $_.EndsWith(".vi") }

if ($files.Count -eq 0) {
    Write-Host "No changed .vi files to compare. Exiting."
    exit 0
}

$FAILED = 0

foreach ($file in $files) {
    # Use Join-Path to combine base and relative paths, handling any mix of
    # forward/backward slashes produced by git on Windows.
    $VI1 = Join-Path "C:\workspace\vi-base" $file
    $VI2 = Join-Path "C:\workspace" $file
    $baseName = [System.IO.Path]::GetFileNameWithoutExtension($file)
    $REPORT_PATH = Join-Path $REPORT_DIR "$baseName-diff-report.html"

    if (-not (Test-Path $VI2)) {
        Write-Host "Warning: Head version not found: $VI2, skipping."
        continue
    }

    if (-not (Test-Path $VI1)) {
        Write-Host "Warning: Base version not found: $VI1, skipping."
        continue
    }

    Write-Host "Running LabVIEWCLI CreateComparisonReport for: $file"

    # -o overwrites an existing report file; -c creates the report directory if necessary.
    # -nobdcosm & -nofppos omit non-functional changes from diagram and panel respectively
    & LabVIEWCLI `
        -OperationName CreateComparisonReport `
        -vi1 "$VI1" `
        -vi2 "$VI2" `
        -reportType "HTMLSingleFile" `
        -reportPath "$REPORT_PATH" `
        -o -c -nobdcosm -nofppos

    if ($LASTEXITCODE -ne 0) {
        Write-Host "X CreateComparisonReport failed for $file (exit code $LASTEXITCODE)"
        $FAILED++
    } else {
        Write-Host "✔ CreateComparisonReport succeeded for $file"
    }
}

if ($FAILED -gt 0) {
    Write-Host "X $FAILED file(s) failed comparison. Exiting with error."
    exit 1
} else {
    Write-Host "✔ All comparison reports generated successfully."
    exit 0
}
