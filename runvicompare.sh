#!/bin/bash
# Reads changed .vi files from /workspace/changed-files.txt and generates
# HTML comparison reports using LabVIEWCLI CreateComparisonReport.

CHANGED_FILES_FILE='/workspace/changed-files.txt'
REPORT_DIR='/workspace/vi-compare-reports'
LABVIEW_PATH='/usr/local/natinst/LabVIEW-2025-64/labviewprofull'

mkdir -p "$REPORT_DIR"
mkdir -p "/tmp/natinst"
echo "1" > /tmp/natinst/LVContainer.txt

if [ ! -f "$CHANGED_FILES_FILE" ]; then
  echo "No changed-files.txt found. Exiting."
  exit 0
fi

FAILED=0

while IFS= read -r file; do
  file="$(echo "$file" | tr -d '\r')"
  [[ -z "$file" ]] && continue
  [[ "$file" != *.vi ]] && continue

  VI_BASE="/workspace/vi-base/$file"
  VI_HEAD="/workspace/$file"
  BASE_NAME="$(basename "$file" .vi)"
  REPORT_PATH="$REPORT_DIR/$BASE_NAME-diff-report.html"

  if [ ! -f "$VI_HEAD" ]; then
    echo "Warning: Head version not found: $VI_HEAD, skipping."
    continue
  fi

  if [ ! -f "$VI_BASE" ]; then
    echo "Warning: Base version not found: $VI_BASE, skipping."
    continue
  fi

  echo "Running LabVIEWCLI CreateComparisonReport for: $file"

  # -o overwrites an existing report file; -c continues if LabVIEW is already open.
  # Run directly (not captured) so all LabVIEWCLI output is visible in the Actions log.
  LabVIEWCLI \
    -LabVIEWPath $LABVIEW_PATH \
    -LogToConsole TRUE \
    -Headless \
    -OperationName CreateComparisonReport \
    -vi1 "$VI_BASE" \
    -vi2 "$VI_HEAD" \
    -reportType "HTMLSingleFile" \
    -reportPath "$REPORT_PATH" \
    -o -c

  EXIT_CODE=$?
  if [ $EXIT_CODE -ne 0 ]; then
    echo "✖ CreateComparisonReport failed for $file (exit code $EXIT_CODE)"
    FAILED=$((FAILED + 1))
  elif [ ! -f "$REPORT_PATH" ]; then
    echo "✖ CreateComparisonReport exited 0 but report was not created: $REPORT_PATH"
    FAILED=$((FAILED + 1))
  else
    echo "✔ CreateComparisonReport succeeded for $file"
  fi
done < "$CHANGED_FILES_FILE"

if [ $FAILED -gt 0 ]; then
  echo "✖ $FAILED file(s) failed comparison. Exiting with error."
  exit 1
else
  echo "✔ All comparison reports generated successfully."
  exit 0
fi
