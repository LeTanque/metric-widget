#!/bin/zsh
set -euo pipefail

project_dir="${0:A:h}"
build_dir="$project_dir/build"
app_name="MetricsWidget"
derived="$build_dir/DerivedData"

cd "$project_dir"
source "$project_dir/scripts/sign_identity.sh"
team_args=()
[ -n "$MW_DEVELOPMENT_TEAM" ] && team_args=(DEVELOPMENT_TEAM="$MW_DEVELOPMENT_TEAM")
xcodebuild \
  -scheme "$app_name" \
  -configuration Release \
  -destination 'platform=macOS' \
  -derivedDataPath "$derived" \
  "${team_args[@]}" \
  build

built_app="$derived/Build/Products/Release/${app_name}.app"

rm -rf "$build_dir/${app_name}.app"
ditto "$built_app" "$build_dir/${app_name}.app"
xattr -cr "$build_dir/${app_name}.app"
codesign --force --deep --sign "$MW_SIGN_IDENTITY_RESOLVED" "$build_dir/${app_name}.app"
codesign --verify --deep --strict "$build_dir/${app_name}.app"

echo "Built $build_dir/${app_name}.app"
echo "Install: ditto \"$build_dir/${app_name}.app\" /Applications/${app_name}.app"
echo "Then: open /Applications/${app_name}.app"
