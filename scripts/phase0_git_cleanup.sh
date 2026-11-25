#!/usr/bin/env bash
# Phase 0 clean-up. Run once from the project root:
#   bash scripts/phase0_git_cleanup.sh
#
# 1. Stops tracking build output and IDE files (they stay on disk, git just
#    forgets them; the new .gitignore keeps them out from now on).
# 2. Removes the stray IntelliJ template files.
# 3. Stages everything else, including splash_screen.dart, which was never
#    committed (the reason a fresh clone didn't compile).
set -euo pipefail

cd "$(git rev-parse --show-toplevel)"

echo "→ Untracking build output and IDE files…"
git rm -r --cached --quiet --ignore-unmatch \
  build .dart_tool .idea .flutter-plugins .flutter-plugins-dependencies \
  FuturemugInterviewer.iml futuremug_interviewer.iml \
  android/futuremug_interviewer_android.iml

echo "→ Removing stray template files…"
git rm -r --quiet --ignore-unmatch src/Main.kt
rm -rf src
rm -f FuturemugInterviewer.iml

echo "→ Moving the CI workflow into place…"
if [ -f "Claude outputs/flutter_ci.yml" ]; then
  mkdir -p .github/workflows
  mv "Claude outputs/flutter_ci.yml" .github/workflows/flutter_ci.yml
  rmdir "Claude outputs" 2>/dev/null || true
fi

echo "→ Fetching packages…"
flutter pub get

echo "→ Formatting…"
dart format lib test

echo "→ Staging…"
git add -A

echo
git status --short | head -50
echo
echo "Next: run 'flutter analyze' and 'flutter test', then commit:"
echo "  git commit -m 'Phase 0 + 1A: repo clean-up and app foundation'"
