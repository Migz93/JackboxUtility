#!/usr/bin/env bash
set -euo pipefail

project_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
app_dir="$project_root/jackbox_patcher"
manifest="$app_dir/pubspec.yaml"
backup_manifest="$app_dir/pubspec.yaml.container-backup"

if [[ ! -f "$manifest" ]]; then
  echo "Could not find $manifest" >&2
  exit 1
fi

cleanup() {
  if [[ -f "$backup_manifest" ]]; then
    mv "$backup_manifest" "$manifest"
  fi
}
trap cleanup EXIT

# This matches the upstream Linux CI workaround. The package is Windows-only
# in this project, but is still declared in pubspec.yaml.
mv "$manifest" "$backup_manifest"
grep -v 'media_kit_libs' "$backup_manifest" > "$manifest"

pushd "$app_dir" >/dev/null
flutter pub get
# Upstream currently has a large existing lint backlog. Keep it visible, but
# reserve a failed build for analyzer errors and actual compilation failures.
flutter analyze --no-fatal-infos --no-fatal-warnings
flutter build linux --release -t lib/main_release.dart
popd >/dev/null

echo
echo "Linux x86_64 bundle ready at:"
echo "  $app_dir/build/linux/x64/release/bundle"
