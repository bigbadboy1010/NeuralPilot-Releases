# NeuralPilot Releases

Public distribution channel for signed and notarized NeuralPilot for Mac releases.

## Contents

Each GitHub Release may contain only:

- `NeuralPilot-<version>.dmg` — Developer ID signed, notarized and stapled;
- `update-manifest.json` — Ed25519-signed update metadata;
- `NeuralPilot-<version>.dmg.sha256` — SHA-256 checksum;
- public release notes.

## Long-term DMG archive

In addition to GitHub Release assets, signed DMGs are retained under `archive/` for traceability:

- `archive/production/<version>/build-<build>/` — signed/notarized production-line artifacts; superseded candidates are explicitly marked in their local README;
- `archive/e2e/<version>/build-<build>/` — explicitly non-production updater/rollback acceptance builds.

All `*.dmg` archive files are stored through Git LFS. Portable SHA-256 files, source-commit metadata and notarization evidence are kept alongside production artifacts when available. See `archive/README.md`.

Future local archives can be created with `bash scripts/archive-local-dmg.sh`, which re-checks codesign, stapling and Gatekeeper before committing an artifact.

## Trust model

The public repository is only the transport channel. NeuralPilot verifies every update through HTTPS, the Ed25519 manifest signature, SHA-256, Apple Developer ID team `355NB9T8RJ`, notarization and Gatekeeper.

The application source code remains private in `bigbadboy1010/NeuralPilot-for-Mac`. Private signing keys, certificates, tokens, databases and diagnostic reports must never be uploaded here.
