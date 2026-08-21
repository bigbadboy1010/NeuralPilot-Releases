#!/usr/bin/env bash
set -Eeuo pipefail

usage() {
  cat <<'EOF'
Usage:
  scripts/archive-local-dmg.sh <production|e2e> <version> <build> <dmg> [options]

Options:
  --manifest <path>       Copy an update manifest into the archive entry.
  --notary <path>         Copy Apple notary-result JSON into the archive entry.
  --source-commit <value> Source commit SHA or a file containing the SHA.
  --push                  Push the resulting commit to origin.

The script runs only on macOS because every DMG is re-checked with codesign,
stapler and Gatekeeper before it is copied into the Git LFS archive.
EOF
}

fail() {
  printf 'FEHLER: %s\n' "$1" >&2
  exit 1
}

[[ $# -ge 4 ]] || { usage; exit 64; }

KIND="$1"
VERSION="$2"
BUILD="$3"
DMG="$4"
shift 4

MANIFEST=""
NOTARY=""
SOURCE_COMMIT=""
PUSH=0

while [[ $# -gt 0 ]]; do
  case "$1" in
    --manifest)
      [[ $# -ge 2 ]] || fail '--manifest benötigt einen Pfad.'
      MANIFEST="$2"
      shift 2
      ;;
    --notary)
      [[ $# -ge 2 ]] || fail '--notary benötigt einen Pfad.'
      NOTARY="$2"
      shift 2
      ;;
    --source-commit)
      [[ $# -ge 2 ]] || fail '--source-commit benötigt einen SHA oder Dateipfad.'
      SOURCE_COMMIT="$2"
      shift 2
      ;;
    --push)
      PUSH=1
      shift
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      fail "Unbekannte Option: $1"
      ;;
  esac
done

[[ "$KIND" == "production" || "$KIND" == "e2e" ]] \
  || fail 'kind muss production oder e2e sein.'
[[ "$VERSION" =~ ^[0-9]+\.[0-9]+\.[0-9]+([.-][0-9A-Za-z.-]+)?$ ]] \
  || fail "Ungültige Version: $VERSION"
[[ "$BUILD" =~ ^[0-9]+$ ]] || fail "Ungültige Buildnummer: $BUILD"
[[ "$(uname -s)" == "Darwin" ]] || fail 'DMG-Archivierung muss auf macOS laufen.'
[[ -f "$DMG" ]] || fail "DMG fehlt: $DMG"
[[ -z "$MANIFEST" || -f "$MANIFEST" ]] || fail "Manifest fehlt: $MANIFEST"
[[ -z "$NOTARY" || -f "$NOTARY" ]] || fail "Notary-Result fehlt: $NOTARY"

command -v git >/dev/null 2>&1 || fail 'git fehlt.'
command -v shasum >/dev/null 2>&1 || fail 'shasum fehlt.'
command -v codesign >/dev/null 2>&1 || fail 'codesign fehlt.'
command -v xcrun >/dev/null 2>&1 || fail 'xcrun fehlt.'
command -v spctl >/dev/null 2>&1 || fail 'spctl fehlt.'
git lfs version >/dev/null 2>&1 || fail 'Git LFS fehlt oder ist nicht initialisiert.'

ROOT="$(git rev-parse --show-toplevel 2>/dev/null)" \
  || fail 'Skript muss innerhalb eines NeuralPilot-Releases-Clones laufen.'
cd "$ROOT"

[[ -f .gitattributes ]] || fail '.gitattributes fehlt.'
grep -Eq '^\*\.dmg[[:space:]].*filter=lfs' .gitattributes \
  || fail '*.dmg ist nicht für Git LFS konfiguriert.'

if [[ "$KIND" == "production" ]]; then
  [[ -n "$NOTARY" ]] || fail 'Production-Archive benötigt --notary.'
  [[ -n "$SOURCE_COMMIT" ]] || fail 'Production-Archive benötigt --source-commit.'
fi

printf '\n=== DMG-Sicherheitsprüfung ===\n'
codesign --verify --strict --verbose=4 "$DMG"
xcrun stapler validate "$DMG"
spctl --assess \
  --type open \
  --context context:primary-signature \
  --verbose=4 \
  "$DMG"

SHA256="$(shasum -a 256 "$DMG" | awk '{print $1}')"
DEST="$ROOT/archive/$KIND/$VERSION/build-$BUILD"
DMG_NAME="NeuralPilot-$VERSION-build$BUILD.dmg"
DEST_DMG="$DEST/$DMG_NAME"

if [[ -d "$DEST" ]]; then
  if [[ -f "$DEST_DMG" ]]; then
    EXISTING_SHA="$(shasum -a 256 "$DEST_DMG" | awk '{print $1}')"
    [[ "$EXISTING_SHA" == "$SHA256" ]] \
      || fail "Archiveintrag existiert bereits mit anderem DMG-Hash: $DEST"
  else
    fail "Archiveintrag existiert bereits unvollständig: $DEST"
  fi
fi

mkdir -p "$DEST"
cp -p "$DMG" "$DEST_DMG"
printf '%s  %s\n' "$SHA256" "$DMG_NAME" > "$DEST/$DMG_NAME.sha256"

if [[ -n "$MANIFEST" ]]; then
  cp -p "$MANIFEST" "$DEST/update-manifest.json"
fi
if [[ -n "$NOTARY" ]]; then
  cp -p "$NOTARY" "$DEST/notary-result.json"
fi
if [[ -n "$SOURCE_COMMIT" ]]; then
  if [[ -f "$SOURCE_COMMIT" ]]; then
    SOURCE_VALUE="$(tr -d '[:space:]' < "$SOURCE_COMMIT")"
  else
    SOURCE_VALUE="$(printf '%s' "$SOURCE_COMMIT" | tr -d '[:space:]')"
  fi
  [[ "$SOURCE_VALUE" =~ ^[0-9a-fA-F]{7,40}$ ]] \
    || fail 'Source-Commit ist kein plausibler Git-SHA.'
  printf '%s\n' "$SOURCE_VALUE" > "$DEST/source-commit.txt"
fi

ARCHIVED_AT="$(date -u '+%Y-%m-%dT%H:%M:%SZ')"
python3 - "$DEST/archive-metadata.json" "$KIND" "$VERSION" "$BUILD" "$DMG_NAME" "$SHA256" "$ARCHIVED_AT" <<'PY'
import json
import pathlib
import sys

path, kind, version, build, dmg_name, sha256, archived_at = sys.argv[1:]
data = {
    "schemaVersion": 1,
    "kind": kind,
    "version": version,
    "build": int(build),
    "dmg": dmg_name,
    "sha256": sha256,
    "archivedAt": archived_at,
}
pathlib.Path(path).write_text(json.dumps(data, indent=2, sort_keys=True) + "\n")
PY

ATTR="$(git check-attr filter -- "$DEST_DMG" | awk -F': ' '{print $3}')"
[[ "$ATTR" == "lfs" ]] || fail "DMG wird nicht über Git LFS verwaltet: $DEST_DMG"

git add -- "$DEST"

if git diff --cached --quiet -- "$DEST"; then
  printf 'Archiveintrag bereits identisch vorhanden: %s\n' "$DEST"
  exit 0
fi

if [[ "$KIND" == "production" ]]; then
  MESSAGE="archive: NeuralPilot $VERSION build $BUILD production"
else
  MESSAGE="archive: NeuralPilot $VERSION build $BUILD E2E"
fi

git commit -m "$MESSAGE" -- "$DEST"

printf '\nArchiviert: %s\n' "$DEST"
printf 'SHA-256:   %s\n' "$SHA256"

if [[ "$PUSH" -eq 1 ]]; then
  BRANCH="$(git branch --show-current)"
  [[ -n "$BRANCH" ]] || fail 'Kein aktiver Branch für --push.'
  git push origin "$BRANCH"
  printf 'GitHub-Push: origin/%s\n' "$BRANCH"
else
  printf 'Hinweis: Noch nicht gepusht. Für automatischen Push erneut mit --push ausführen.\n'
fi
