# Changelog: MediaStack Project

All notable changes to this project will be documented in this file.

## [26.3.0] - 2026-03-26

### Stability
- Pinned Authentik to version 26.2.1
- Pinned Postgresql to version 18.1-bookworm

### Added
- Added LazyLibrarian support.
- Added Application Security support to the CrowdSec WAF.
- Added `FOLDER_FOR_RUNTIME=/mediastack/runtime` to allow MediaStack compose files and runtime scripts.
- Added GitHub issue and pull request templates.
- Added contribution guidance and security reporting documentation to support mature repository workflow.

### Changed
- Reworked significant parts of the project structure to support a more mature release and maintenance model.
- Separated `restart.sh` and `update.sh` into dedicated operational scripts.
- Expanded restart and update workflows with more robust logic, validation, and clearer user messaging.
- Continued development of the master template and generated compose model approach to improve maintainability and release control.
- Pinned Authentik and PostgreSQL versions for improved deployment stability and more controlled upgrades.
- Improved project documentation and governance for contributors and operators.

### Removed
- Removed Huntarr due to security vulnerabilities.
- Removed Readarr because it is no longer maintained.

### Fixed
- Corrected Authentik worker configuration to load SMTP server settings from the environment file.
- Improved reliability and clarity of routine stack administration tasks.
- Reduced ambiguity and overlap in restart and update operations.

### Security
- Added Application Security support to the CrowdSec WAF.
- Strengthened repository contribution controls and security reporting guidance.
- Reduced upgrade risk by pinning Authentik and PostgreSQL versions instead of relying on uncontrolled upstream image changes.
- Removed Huntarr from the stack due to security vulnerabilities.

### Breaking
- Huntarr and Readarr are no longer included in MediaStack.
- Operators using these services must review and remove any legacy configuration, overrides, and related data paths as part of upgrade planning.
- Deployments using legacy assumptions around fixed config paths should review and validate script and compose behaviour when adopting `FOLDER_FOR_RUNTIME`.

## [26.0.0] - 2026-03-01

### Added
- Established the GitHub repository baseline as the first formal MediaStack version.
- Introduced formal project versioning to support tracked releases and future changelog management.