# Sourced by build.sh and scripts/package_app.sh.
# Sets MW_SIGN_IDENTITY_RESOLVED (codesign identity or "-") and MW_DEVELOPMENT_TEAM (may be empty).
#
# Resolution order:
#   1. MW_SIGN_IDENTITY / MW_DEVELOPMENT_TEAM from the environment ("-" forces ad-hoc).
#   2. ~/.metricswidget-signing/config (machine-local; keeps the team ID out of the shared project).
#   3. The first valid "Apple Development" identity in the keychain.
#   4. Ad-hoc.
# An Apple-issued identity with a Team ID keeps Keychain "Always Allow" grants valid across rebuilds.
mw_signing_config="${MW_SIGNING_CONFIG:-$HOME/.metricswidget-signing/config}"
if [ -f "$mw_signing_config" ]; then
  . "$mw_signing_config"
fi
if [ -n "${MW_SIGN_IDENTITY:-}" ]; then
  MW_SIGN_IDENTITY_RESOLVED="$MW_SIGN_IDENTITY"
else
  MW_SIGN_IDENTITY_RESOLVED="$(security find-identity -v -p codesigning 2>/dev/null \
    | awk -F'"' '/"Apple Development: / { print $2; exit }')"
  [ -n "$MW_SIGN_IDENTITY_RESOLVED" ] || MW_SIGN_IDENTITY_RESOLVED="-"
fi
MW_DEVELOPMENT_TEAM="${MW_DEVELOPMENT_TEAM:-}"
if [ "$MW_SIGN_IDENTITY_RESOLVED" = "-" ]; then
  echo "Signing: ad-hoc (Keychain will re-prompt after each rebuild)"
else
  echo "Signing: $MW_SIGN_IDENTITY_RESOLVED${MW_DEVELOPMENT_TEAM:+ (team $MW_DEVELOPMENT_TEAM)}"
fi
