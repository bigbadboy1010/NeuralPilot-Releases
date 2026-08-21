# NeuralPilot DMG Archive

This directory is the long-term artifact archive for signed NeuralPilot DMGs.
GitHub Releases remain the primary distribution/update channel. The archive is an additional traceability layer.

## Layout

```text
archive/
├── production/<version>/build-<build>/
└── e2e/<version>/build-<build>/
```

### `production`

Developer-ID-signed and Apple-notarized production-line artifacts belong here. A build that is later superseded by additional hardening remains archived for traceability but must contain a local README that clearly marks it as superseded and not current production.

Expected metadata:

- `NeuralPilot-<version>-build<build>.dmg` (Git LFS)
- matching `.sha256`
- `notary-result.json`
- `source-commit.txt`
- `update-manifest.json` when available
- `archive-metadata.json` for entries created by the archive helper
- status README when the build is superseded

### `e2e`

Signed/notarized artifacts used only for updater, rollback or release acceptance testing. These are never production releases and must remain clearly separated from `production`.

## Integrity

All `*.dmg` files are stored through Git LFS. SHA files use the portable form:

```text
<sha256>  NeuralPilot-<version>-build<build>.dmg
```

Do not store local filesystem paths, private signing keys, Apple credentials, GitHub tokens, databases or diagnostic reports in this repository.

## Archive helper

From a local clone on macOS:

```bash
bash scripts/archive-local-dmg.sh \
  production \
  1.0.0 \
  38 \
  /path/to/NeuralPilot-1.0.0.dmg \
  --notary /path/to/notary-result.json \
  --source-commit CURRENT_RELEASE_SHA \
  --manifest /path/to/update-manifest.json \
  --push
```

The helper re-checks codesign, stapling and Gatekeeper before archiving the DMG and refuses conflicting archive entries.
