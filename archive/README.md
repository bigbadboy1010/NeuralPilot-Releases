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

Only final release artifacts that have passed Developer ID signing, Apple notarization, stapling and Gatekeeper verification belong here.

Expected metadata:

- `NeuralPilot-<version>-build<build>.dmg` (Git LFS)
- matching `.sha256`
- `notary-result.json`
- `source-commit.txt`
- `update-manifest.json` when available
- `archive-metadata.json` for entries created by the archive helper

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
scripts/archive-local-dmg.sh \
  production \
  1.0.0 \
  36 \
  /path/to/NeuralPilot-1.0.0.dmg \
  --notary /path/to/notary-result.json \
  --source-commit 49ddced8bf9b6d3268ccebf3b68edb5369ab82d3 \
  --manifest /path/to/update-manifest.json \
  --push
```

The helper re-checks codesign, stapling and Gatekeeper before archiving the DMG and refuses conflicting archive entries.
