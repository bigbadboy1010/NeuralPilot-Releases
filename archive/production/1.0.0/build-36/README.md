# NeuralPilot 1.0.0 Build 36

**Status: superseded release candidate — not the final NeuralPilot 1.0 production build.**

Build 36 was Developer-ID signed, Apple notarized, stapled and Gatekeeper accepted during release acceptance. A later static security review found cleanup-root and terminal-scope hardening that must be included before merge, so the production build number advanced rather than reusing Build 36.

Historical identity:

- version: 1.0.0
- build: 36
- source: `49ddced8bf9b6d3268ccebf3b68edb5369ab82d3`
- DMG SHA-256: `10b2221cb67b419d38297bcdf79c652d2df71e3960ff90a6aafe8729fd2fbbd4`
- notary submission: `bec6d4c4-13b4-49fa-878b-62ca40b4e685`

The final production target after hardening is Build 38. This artifact is retained only for traceability and rollback/release-history evidence.
