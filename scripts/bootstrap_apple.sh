#!/usr/bin/env bash
set -euo pipefail

if ! command -v xcodegen >/dev/null 2>&1; then
  echo "XcodeGen is required. Install it with: brew install xcodegen"
  exit 1
fi

xcodegen generate --spec project.yml

echo ""
echo "OncoSense Xcode project generated."
echo "Open OncoSense.xcodeproj in Xcode, select your iPhone/Apple Watch, then Run."
echo "HealthKit permissions are requested by the Watch app at first launch."
