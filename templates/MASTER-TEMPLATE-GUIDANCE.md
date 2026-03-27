# Master Template Guidance

## Purpose

MediaStack uses a single trusted master compose source so maintainers can generate consistent deployment packages without manually maintaining multiple drifting Docker Compose files.

This guidance explains the purpose of the master template, the environment template, and the principles that should guide future changes.

This document replaces the older combined guidance that discussed both master-template management and broad image version-control strategy. For now, MediaStack is intentionally keeping image governance simple and only manually pinning packages where stability or security requires it.

## Core Principle

MediaStack should be easy for new users to deploy, simple for maintainers to understand, and deliberate in how it applies security architecture across supported deployment models.

The project should prefer:

- one trusted master compose source over multiple hand-maintained full stack files
- generated deployment outputs over manual duplication
- simple, readable maintainer conventions over clever automation
- secure default architecture over convenience shortcuts
- gradual improvement over unnecessary complexity

## Canonical Source Files

The MediaStack project currently maintains two primary maintainer-controlled source files under `templates/docker/`:

- `mediastack-master-compose.yaml`
- `mediastack-environment-template.env`

These files are the authoritative source inputs for MediaStack generation, validation, packaging, and release preparation.

Generated outputs must be produced from these files and must not be treated as the primary editing surface.

## 1. `mediastack-master-compose.yaml`

### Purpose

`templates/docker/mediastack-master-compose.yaml` is the single canonical compose master for MediaStack.

It exists to define:

- supported services
- networks and service relationships
- environment variable references
- security model behavior
- supported routing patterns
- structural markers used by generation scripts
- the source layout for generated runtime artefacts

### Role

This file is the primary structural source for MediaStack generation.

It is not intended to be the normal runtime compose file used directly by end users.

### Maintainer intent

The master compose should allow maintainers to:

- maintain one trusted source of truth for stack structure
- avoid uncontrolled duplication across multiple full Compose variants
- build and test multiple deployment models from one source
- generate consistent runtime outputs for users
- preserve a security-first architecture while still supporting simpler deployment models

### End-user expectation

End users should normally deploy generated outputs, not the internal master compose source.

### Rule

`mediastack-master-compose.yaml` is the single canonical compose master for MediaStack.

It must not coexist with competing master compose files intended to serve the same role.

## 2. `mediastack-environment-template.env`

### Purpose

`templates/docker/mediastack-environment-template.env` is the canonical starter environment template.

It exists to define:

- sample user-provided variables
- placeholder values
- repeatable input expectations
- the user-editable configuration surface for deployment

### Role

This file is not a live runtime secrets file.

It is the maintained source template used to produce `.env.example` for release packages.

End users should copy or rename `.env.example` to `.env` and then update the values for their own environment.

### Rule

The environment template should remain simple, readable, and stable across supported deployment models unless there is a clear reason to change it.

Architecture differences should be handled primarily through generated compose outputs, not by creating multiple drifting environment templates.

## 3. Relationship Between the Two Files

The two files serve different but related purposes.

### `mediastack-master-compose.yaml`
Defines what MediaStack is and how it is structured.

### `mediastack-environment-template.env`
Defines what user-supplied configuration inputs are expected and how they are presented.

Together, they allow MediaStack to generate deployment artefacts that are:

- structurally consistent
- easier for new users to understand
- repeatable across releases
- aligned to MediaStack security architecture principles

## 4. Simplicity and Ease of Use

MediaStack should remain approachable for new users.

That means maintainers should prefer:

- clear release package names
- predictable folder layout
- generated `.env.example` starter files
- readable scripts with practical comments
- explicit markers where generation logic depends on structure
- avoiding unnecessary layers of abstraction

The project should not force new users to understand internal generation logic just to deploy the stack.

Official releases should provide pre-generated, validated deployment packages.

## 5. Security Architecture Principles

MediaStack should keep a strong commitment to security architecture even when offering multiple deployment models.

That means:

- secure remote access components should be grouped and treated deliberately
- networking behavior should be explicit, not accidental
- services that change routing model must do so in a controlled and testable way
- public exposure, reverse proxying, authentication, and VPN routing should remain part of a coherent design
- more permissive deployment models may exist, but they should not weaken the design of the source architecture

MediaStack may support:

- full-vpn style models
- reduced-vpn style models
- no-vpn style models

But these are generated variations of one maintained architecture, not separate products.

## 6. Generated Runtime Artefacts

End-user runtime artefacts should be generated from the trusted source files.

The supported outcomes are:

- generated single-file Docker Compose deployments
- generated parent-and-include Compose package sets
- generated `.env.example` starter files
- packaged release bundles for supported deployment models

Generated outputs are the normal deployment input for users.

The source compose master and source environment template are maintainer-controlled inputs.

## 7. Release Package Model

MediaStack should produce official generated outputs for six supported package models:

### Standalone outputs

- full vpn
- mini vpn
- no vpn

### Include-based outputs

- full vpn
- mini vpn
- no vpn

Each release package should contain the artefacts needed for the end user to deploy and manage MediaStack, including:

- generated compose files
- generated include files where relevant
- `.env.example`
- runtime support scripts
- supporting configuration files
- setup/bootstrap materials where applicable

## 8. Source of Truth in the Repository

The repository should preserve a clear separation between authoritative source and generated output.

### Maintainer-controlled source of truth

The authoritative source currently lives in:

- `templates/docker/mediastack-master-compose.yaml`
- `templates/docker/mediastack-environment-template.env`
- `release-content/` for maintained release-supporting files that are intentionally shipped to end users
- `scripts/build/` for maintainer generation and packaging tools

### Generated artefacts

Generated outputs should be created into controlled output locations during build, validation, test, or release workflows.

Examples include:

- generated compose model outputs
- generated include-package outputs
- generated `.env.example` release files
- release staging folders
- zipped release packages

Maintainers should edit source files, not generated outputs.

## 9. Maintainer Tooling Philosophy

MediaStack should keep a conservative split between maintainer tooling and end-user tooling.

### Bash

Preferred for:

- runtime management scripts
- restart/update/backup/restore tasks
- simple operator tasks
- setup helpers where practical

### Python

Appropriate for:

- generation pipelines
- model transformations
- packaging logic
- validation routines
- release preparation support

### Rule

End users should not need Python or internal generation tooling to deploy MediaStack through the supported path.

Official releases should include pre-generated, validated compose packages and a `.env.example` starter file.

## 10. Image Version Approach for Now

MediaStack is intentionally not enforcing a broad automated image version-control system in the current stage of development.

For now:

- packages with a known history of breakage or higher security importance may be manually pinned
- other upstream images may remain on their normal tags until a broader versioning workflow is justified
- maintainers should prefer stability where it matters, without blocking release progress by overcomplicating image governance too early

This is a deliberate temporary simplification, not an oversight.

## 11. Support Boundaries

### Supported path

The supported MediaStack path is:

1. obtain the trusted generated release package
2. choose the supported deployment model required
3. copy or rename `.env.example` to `.env`
4. update `.env` with site-specific values
5. deploy the generated runtime output
6. operate the stack using documented MediaStack procedures

### Out of scope

The following are outside the normal supported path:

- editing the internal master compose without understanding the design
- heavily customised deployments
- unsupported platform behavior
- unsafe self-hosting practices
- local changes that diverge from documented deployment patterns

MediaStack can remain flexible without pretending every variation is equally supported.

## 12. Repository Safety

The repository should allow template and example files, but should block live runtime environment files and generated release artefacts where appropriate.

### Allowed in the Local Git Repo and Online GitHub

Examples include:

- `mediastack-environment-template.env`
- `.env.example`
- scripts intended for users or maintainers
- release-content source files
- documented example configurations

### Keep in the Local Git Repo but ignore from Online GitHub commits

Examples include:

- generated release zips
- local release staging outputs
- other throwaway generated artefacts

### Not allowed in the Local Git Repo as live source

Examples include:

- real `.env` files
- machine-specific secret files
- copied local operator secrets
- other live runtime-only sensitive files

## 13. Strategic Development Principle

MediaStack should prefer:

- one trusted compose master over uncontrolled duplicate full-stack files
- ease of use for new users over internal complexity
- simple and explicit generation logic over fragile cleverness
- security-first architecture over accidental sprawl
- maintainable source inputs over hand-edited generated outputs
- repeatable release packaging over ad hoc local assembly

This principle should guide future repository structure, packaging decisions, and maintainer workflow.

## 14. Maintainer Summary

Use `templates/docker/mediastack-master-compose.yaml` to define MediaStack structure.

Use `templates/docker/mediastack-environment-template.env` to define the canonical starter environment template.

Use `release-content/` to maintain the source files that should ship to users inside release packages.

Use `scripts/build/` to generate and package the supported outputs.

Generate user-facing compose packages and `.env.example` files from those maintained sources.

Support the generated output, not uncontrolled drift.
