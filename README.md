# NeuralPilot Releases

Public distribution channel for signed and notarized NeuralPilot for Mac releases.

## Contents

Each GitHub Release may contain only:

- `NeuralPilot-<version>.dmg` — Developer ID signed, notarized and stapled;
- `update-manifest.json` — Ed25519-signed update metadata;
- `NeuralPilot-<version>.dmg.sha256` — SHA-256 checksum;
- public release notes.

## Trust model

The public repository is only the transport channel. NeuralPilot verifies every update through HTTPS, the Ed25519 manifest signature, SHA-256, Apple Developer ID team `355NB9T8RJ`, notarization and Gatekeeper.

The application source code remains private in `bigbadboy1010/NeuralPilot-for-Mac`. Private signing keys, certificates, tokens, databases and diagnostic reports must never be uploaded here.
