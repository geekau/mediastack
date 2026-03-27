# REPO-STRUCTURE.md

## Purpose

This document defines the current MediaStack repository structure and explains the purpose of each major folder.

Its role is to keep the project understandable, maintainable, and predictable as MediaStack grows. The structure is designed to support:

- one trusted source for the master compose and environment template
- repeatable generation of supported deployment models
- separation between source content, generated output, and release packaging
- a clear distinction between maintainer tooling and end-user runtime content
- a security-first architecture that remains understandable to new users

This document replaces the older repository structure guidance and reflects the current working layout of the project.

---

## Core Structure Principles

MediaStack should keep a clear separation between:

- **source folders** that maintainers edit
- **generated output folders** created during build or release preparation
- **release content folders** that hold maintained files intended to ship to end users
- **documentation folders** that explain how the project is used and maintained
- **platform and host-bootstrap folders** that support supported deployment environments

Generated artefacts should not become the normal editing surface.

Maintainers should edit the authoritative source folders and use scripts to generate outputs from them.

---

## Top-Level Repository Structure

```text
/
├─ .github/
├─ build/
├─ deploy/
├─ docs/
├─ mediastack-os/
├─ platform/
├─ release-content/
├─ releases/
├─ scripts/
├─ templates/
├─ tests/
├─ README.md
├─ CHANGELOG.md
├─ CONTRIBUTING.md
├─ SECURITY.md
├─ LICENSE
├─ REPO-STRUCTURE.md
└─ .gitignore
```

---

## Folder Guidance

### `.github/`

This folder holds GitHub-specific repository controls and automation support.

Typical uses include:

- issue templates
- pull request templates
- CODEOWNERS
- validation workflows
- future release or packaging workflows

This folder supports the Local Git Repo and Online GitHub workflow, but it is not the source location for MediaStack deployment logic.

---

### `build/`

This folder is reserved for build-oriented project structure and future maintainer automation support.

It exists as a clean location for build-related growth, even if it is initially light.

Typical future uses may include:

- build metadata
- packaging support
- validation helpers
- staging logic used during generation

This is maintainer territory, not end-user runtime content.

---

### `deploy/`

This folder is reserved for deployment-oriented output or support structure.

Its role is to provide a home for deployment artefacts and related material if the project later chooses to keep generated outputs in-repo.

At the current stage, MediaStack primarily generates release outputs into controlled packaging workflows rather than treating `deploy/` as the main source of truth.

This folder should not replace the source templates.

---

### `docs/`

This folder holds the maintained documentation source for MediaStack.

It is the long-term home for:

- getting started guidance
- deployment documentation
- application documentation
- troubleshooting
- release notes and release guidance
- maintainer reference material
- future merged web documentation from the separate guide project

This is the correct place for the Online GitHub documentation source and future web documentation publishing.

#### Internal role of `docs/`

- `docs/docs/` holds the main documentation content
- `docs/assets/` holds supporting assets such as images and diagrams
- `docs/mkdocs.yml` defines the documentation site structure

This folder should remain the canonical documentation source.

---

### `mediastack-os/`

This folder holds operating-system bootstrap and autodeployment material.

Its purpose is to support a known, repeatable host baseline for MediaStack, especially for Ubuntu-based automated deployment paths.

This folder is about building and preparing the host operating system, not about the compose application layer itself.

#### Expected functional areas

- `autoinstall/`  
  unattended operating system installation support

- `cloud-init/`  
  first-boot provisioning inputs and seed files

- `host-bootstrap/`  
  MediaStack-specific host preparation logic after the OS is installed

- `docs/`  
  documentation related to host build and supported baseline setup

#### Functional flow

The intended lifecycle is:

1. **autoinstall** builds the host OS
2. **cloud-init** shapes the system on first boot
3. **host-bootstrap** prepares the host for MediaStack deployment

This folder should stay separate from Docker Compose generation.

---

### `platform/`

This folder holds platform-specific support structure.

It exists to prevent platform-specific differences from being mixed directly into the generic MediaStack source and build logic.

Typical uses include:

- Synology-specific notes or scripts
- Linux platform differences
- QNAP, Unraid, or TrueNAS support notes
- shared platform caveats
- host path or permission differences
- documentation relevant to specific deployment environments

This folder is for platform variation, not for the core MediaStack source.

---

### `release-content/`

This folder holds maintained source content that is intended to ship to end users inside release packages.

This is one of the most important distinctions in the current repo structure.

`release-content/` is **not** generated packaging output.  
It is **source content for release packaging**.

That means the files here should:

- stay in the Local Git Repo
- be committed and pushed to Online GitHub
- be reviewed and improved through normal maintainer changes and pull requests
- be copied into release packages during packaging

#### Internal role of `release-content/`

- `config/`  
  maintained runtime configuration files intended to ship with release packages

- `scripts/runtime/`  
  end-user runtime and management scripts intended to ship with release packages

- `setup/`  
  setup/bootstrap content intended to help users get running quickly

- `extras/`  
  optional or convenience files that may still be useful in release packages

#### Functional flow

Content here moves **into release packages**.

It should not be treated as throwaway staging output.

This folder is maintained source that is deliberately bundled for users.

---

### `releases/`

This folder supports release packaging and release record keeping.

It is distinct from `release-content/`.

#### Difference from `release-content/`

- `release-content/` = maintained source content that goes into packages
- `releases/` = release workflow support area

Typical uses include:

- `bundles/` for generated package outputs such as zip files
- `manifests/` for release packaging records
- `notes/` for release notes or release tracking support

#### Important rule

Generated bundles may exist locally under `releases/bundles/`, but they should generally be ignored from repository commits and uploaded manually to Online GitHub Releases.

This folder is for release workflow output, not for source content.

---

### `scripts/`

This folder holds project scripts.

Its main purpose is to separate maintainer build logic from any shared script support.

#### Current functional areas

- `build/`  
  maintainer generation and packaging scripts

- `release/`  
  reserved for release-oriented script support

- `test/`  
  reserved for test or validation script support

- `lib/`  
  shared helper logic if needed later

#### Important distinction

Maintainer generation scripts belong here.

User-facing runtime scripts that are shipped to end users belong in:

- `release-content/scripts/runtime/`

That is an intentional distinction.

#### Functional flow

- `scripts/build/` works on the canonical sources
- it generates deployment models and package-ready outputs
- those outputs are then assembled with `release-content/` into release packages

---

### `templates/`

This folder holds the canonical source templates for MediaStack generation.

This is the primary source area for the application-layer architecture.

#### Current internal role

- `templates/docker/` holds the canonical master compose and canonical environment template
- `templates/` also holds high-level guidance documents relevant to template governance

#### What belongs here

- the master compose source
- the source environment template
- future source templates used in generation workflows
- maintainer guidance related to those source templates

#### Important rule

This folder should contain source-of-truth material, not generated deployment outputs.

Maintainers edit here.  
Users normally do not deploy directly from here.

---

### `tests/`

This folder holds testing and validation structure.

It exists to support maintainers in validating generated outputs and future test routines.

Typical uses include:

- compose validation
- script testing
- integration testing
- fixtures
- test support content

It is a support area for quality control and release confidence.

---

## Functional Flow Between Folders

The repository is designed around a simple source-to-output flow.

### 1. Canonical source inputs

The primary source inputs are maintained in:

- `templates/docker/`
- `release-content/`
- `scripts/build/`

These are the areas maintainers edit directly.

### 2. Generation and transformation

Maintainer scripts in `scripts/build/` operate on the source inputs and generate:

- network model outputs
- include-based compose outputs
- packaged deployment structures
- `.env.example` and release-ready compose layouts where applicable

### 3. Release packaging

Generated outputs are assembled with `release-content/` into release packages.

Generated zip bundles and package staging outputs belong under release workflow areas such as:

- `releases/bundles/`

These are output artefacts, not source.

### 4. Documentation and support

`docs/`, `platform/`, and `mediastack-os/` explain and support how MediaStack is built, deployed, and operated.

These folders support maintainers and users, but they do not replace the canonical source locations.

---

## Source vs Generated Output

This distinction must remain clear.

### Source folders
Folders that maintainers edit directly:

- `templates/`
- `release-content/`
- `scripts/build/`
- `docs/`
- `mediastack-os/`
- `platform/`

### Generated output folders
Folders or areas that may contain generated artefacts:

- `releases/bundles/`
- local staging folders
- generated model outputs
- generated package layouts

Generated output should not become the long-term editing surface.

---

## Maintainer Workflow Summary

The repository structure supports the following maintainer workflow:

1. edit the canonical source in `templates/docker/`
2. update or improve bundled runtime content in `release-content/`
3. run generation scripts from `scripts/build/`
4. validate generated outputs
5. assemble release packages
6. place package outputs in release workflow areas such as `releases/bundles/`
7. upload release artefacts manually to Online GitHub releases where appropriate

This keeps source, generation, and packaging clearly separated.

---

## End-User Perspective

End users should not need to understand the internal repository structure to deploy MediaStack.

The structure exists for maintainers.

Users should normally receive:

- generated compose packages
- `.env.example`
- runtime support scripts
- setup/bootstrap content
- supporting configuration files

Those artefacts originate from the maintained source structure, but users interact with the generated release package, not the internal source tree.

---

## Structural Rules

The following rules should guide future changes:

1. Keep one canonical master compose source.
2. Keep one canonical source environment template.
3. Keep release package source content in `release-content/`.
4. Keep maintainer generation logic in `scripts/build/`.
5. Keep generated release artefacts out of normal source folders.
6. Keep platform-specific support separate from the core source.
7. Keep host-OS automation separate from container deployment logic.
8. Prefer simple, readable folder purposes over clever but confusing structure.

---

## Practical Outcome

If this structure is followed consistently, MediaStack gains:

- a clear source-of-truth model
- easier maintenance
- safer release preparation
- clearer separation between source and output
- better support for future docs, OS automation, and platform expansion
- a structure that contributors can understand without guessing

That is the current intended repository structure for MediaStack.
