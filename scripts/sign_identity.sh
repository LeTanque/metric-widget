# Sourced by build.sh and scripts/package_app.sh. Sets MW_SIGN_IDENTITY_RESOLVED.
# MW_SIGN_IDENTITY overrides: a codesigning identity name/SHA-1, or "-" for ad-hoc.
# Default: "MetricsWidget Local Signing" when that identity is in the keychain, else ad-hoc.
# A stable identity keeps the Keychain "Always Allow" grant valid across rebuilds.
mw_default_identity="MetricsWidget Local Signing"
if [ -n "${MW_SIGN_IDENTITY:-}" ]; then
  MW_SIGN_IDENTITY_RESOLVED="$MW_SIGN_IDENTITY"
elif security find-identity -p codesigning 2>/dev/null | grep -q "\"$mw_default_identity\""; then
  MW_SIGN_IDENTITY_RESOLVED="$mw_default_identity"
else
  MW_SIGN_IDENTITY_RESOLVED="-"
fi
if [ "$MW_SIGN_IDENTITY_RESOLVED" = "-" ]; then
  echo "Signing: ad-hoc (Keychain may re-prompt after each rebuild)"
else
  echo "Signing: $MW_SIGN_IDENTITY_RESOLVED"
fi
