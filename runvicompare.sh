#!/bin/bash
# Accepts a newline-separated list of changed files via the CHANGED_FILES env var
# and runs LabVIEWCLI VICompare on each changed .vi file.

LABVIEW_PATH='/usr/local/natinst/LabVIEW-2025-64/labviewprofull'
REPORT_DIR='/usr/local/natinst/ContainerExamples'

mkdir -p "$REPORT_DIR"
mkdir -p "/tmp/natinst"
echo "1" > /tmp/natinst/LVContainer.txt

if [ -z "$CHANGED_FILES" ]; then
  echo "No changed files provided. Exiting."
  exit 0
fi

FAILED=0

while IFS= read -r file; do
  # Only process .vi files
  if [[ "$file" != *.vi ]]; then
    continue
  fi

  VI_PATH="/workspace/$file"

  if [ ! -f "$VI_PATH" ]; then
    echo "Warning: File not found: $VI_PATH, skipping."
    continue
  fi

  REPORT_PATH="$REPORT_DIR/compare_$(basename "$file" .vi).txt"

  echo "Running LabVIEWCLI VICompare for: $VI_PATH"
  OUTPUT=$(LabVIEWCLI -LogToConsole TRUE \
    -OperationName VICompare \
    -LabVIEWPath "$LABVIEW_PATH" \
    -VIPath "$VI_PATH" \
    -ReportPath "$REPORT_PATH")

  EXIT_CODE=$?
  echo "$OUTPUT"

  if [ $EXIT_CODE -ne 0 ]; then
    echo "✖ VICompare failed for $file (exit code $EXIT_CODE)"
    FAILED=$((FAILED + 1))
  else
    echo "✔ VICompare passed for $file"
  fi
done <<< "$CHANGED_FILES"

if [ $FAILED -gt 0 ]; then
  echo "✖ $FAILED file(s) failed VICompare. Exiting with error."
  exit 1
else
  echo "✔ All VICompare checks passed."
  exit 0
fi
