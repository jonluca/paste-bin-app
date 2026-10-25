#!/bin/bash
# Explicit archive step. Ordinary builds never upload symbols.
set -euo pipefail
[[ "$#" == 1 ]] || { echo "Usage: $0 /path/to/App.xcarchive" >&2; exit 64; }
archive="$1"
[[ -d "$archive/dSYMs" ]] || { echo "Archive has no dSYMs" >&2; exit 1; }
python3 - "$archive" <<'VERIFY'
from pathlib import Path
import plistlib, subprocess, sys
archive = Path(sys.argv[1])
apps = list((archive / 'Products/Applications').glob('*.app'))
assert len(apps) == 1, 'Expected one archived app'
info = plistlib.loads((apps[0] / 'Info.plist').read_bytes())
assert info['CFBundleIdentifier'] == 'PasteBinApp', 'Unexpected app bundle'
assert info.get('GlitchTipDSN', '').endswith('/17'), 'Unexpected collector project'
executable = apps[0] / info['CFBundleExecutable']
uuids = {line.split()[1] for line in subprocess.check_output(['xcrun','dwarfdump','--uuid',str(executable)], text=True).splitlines()}
symbols = set()
for dsym in (archive / 'dSYMs').glob('*.dSYM'):
    symbols.update(line.split()[1] for line in subprocess.check_output(['xcrun','dwarfdump','--uuid',str(dsym)], text=True).splitlines())
assert uuids and uuids.issubset(symbols), 'The archive is missing matching app symbols'
print('Verified archived app identity and matching dSYM UUIDs')
VERIFY
export SENTRY_URL='https://http--watchtrader-errors--7rqh4vysrzq7.y8cdxt7gqw.code.run'
export SENTRY_ORG='jonluca-apps'
export SENTRY_PROJECT='pastebin-mobile'
if [[ -z "${SENTRY_AUTH_TOKEN:-}" ]]; then
  SENTRY_AUTH_TOKEN="$(security find-generic-password -s 'GlitchTip Native Apps Upload' -a 'jonluca-apps' -w 2>/dev/null || true)"
  export SENTRY_AUTH_TOKEN
fi
[[ -n "$SENTRY_AUTH_TOKEN" ]] || { echo "Set SENTRY_AUTH_TOKEN or save the upload token in macOS Keychain" >&2; exit 1; }
cli_dir="${TMPDIR:-/tmp}/glitchtip-sentry-cli-3.8.2"
cli="$cli_dir/sentry-cli"
mkdir -p "$cli_dir"
if [[ ! -f "$cli" ]]; then
  download="$(mktemp "$cli_dir/download.XXXXXX")"
  trap 'rm -f "$download"' EXIT
  curl --fail --silent --show-error --location 'https://github.com/getsentry/sentry-cli/releases/download/3.8.2/sentry-cli-Darwin-universal' -o "$download"
  echo '2d1b118fa46960ba5e8e0cca9a6e197366905776a0ddc5a89c7d05a3908b77db  '"$download" | shasum -a 256 -c - >/dev/null
  chmod 700 "$download"
  mv "$download" "$cli"
fi
echo '2d1b118fa46960ba5e8e0cca9a6e197366905776a0ddc5a89c7d05a3908b77db  '"$cli" | shasum -a 256 -c - >/dev/null
# GlitchTip 6.2.6 queues assembly successfully but does not support CLI --wait polling.
"$cli" debug-files upload "$archive/dSYMs"
