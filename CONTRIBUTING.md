# Contributing to MediaStack

Thanks for taking the time to contribute.

MediaStack is an opinionated project. Changes should improve reliability, clarity, maintainability, or security without creating unnecessary complexity or weakening defaults.

## Before you contribute

Before opening an issue or pull request:

- search existing issues and pull requests first
- use the correct issue type
- test your change properly
- do not mix unrelated changes in one pull request
- do not include secrets, tokens, passwords, private URLs, or personal information anywhere in issues, discussions, or pull requests

## Types of contributions

Contributions are welcome in areas such as:

- bug fixes
- documentation improvements
- deployment reliability
- compose generation and template logic
- security hardening
- operational quality improvements
- carefully considered new features

The following are less likely to be accepted unless there is a strong justification:

- changes that increase support burden
- changes that weaken secure defaults
- changes that add complexity for minimal benefit
- broad refactors with no operational value
- personal preference changes presented as universal improvements

## Support requests vs bugs

Not every problem is a bug.

Use the appropriate path:

- **Bug report**: reproducible defect in MediaStack itself
- **Support question**: help with setup, configuration, troubleshooting, or local environment issues
- **Feature request**: proposed improvement or capability
- **Documentation issue**: missing, unclear, or outdated documentation

If a report does not contain enough detail to investigate, it may be closed.

## Discuss first for major changes

For significant work, open an issue or discussion first before spending time on a large pull request.

Examples:

- changing default architecture or deployment flow
- changing network model behaviour
- changing authentication, reverse proxy, or security design
- large documentation restructures
- introducing new core services or major dependencies

This avoids wasted effort.

## Branches

Create your change in a dedicated branch. Do not work directly in the default branch.

Suggested branch naming:

- `fix/<short-description>`
- `feat/<short-description>`
- `docs/<short-description>`
- `refactor/<short-description>`

Examples:

- `fix/traefik-forwardauth-header-handling`
- `docs/install-guide-cleanup`
- `feat/add-compose-validation-check`

## Commit messages

Write clear commit messages that explain what changed.

Good:

- `fix: correct gluetun dependency in mini vpn model`
- `docs: clarify authentik bootstrap steps`
- `chore: clean up outdated compose comments`

Bad:

- `update stuff`
- `fix`
- `changes`

Keep history readable. A maintainer may squash commits on merge.

## Pull request expectations

Pull requests should be focused and easy to review.

A good PR should:

- explain what changed
- explain why it changed
- describe any risks or side effects
- identify breaking or migration impacts
- include documentation updates where needed
- include validation or test evidence

If your PR affects any of the following, say so clearly:

- compose generation
- network models
- `.env.example` or environment variables
- reverse proxy / Traefik
- Authentik / authentication
- CrowdSec / security controls
- scripts / automation
- container image versions
- permissions / ownership
- migration or upgrade behaviour

## Testing expectations

At minimum, contributors should validate their work properly before opening a pull request.

The level of testing depends on the change, but where relevant you should check:

- configuration renders cleanly
- compose output is valid
- affected services still start correctly
- docs match actual behaviour
- existing behaviour is not unintentionally broken
- upgrades are considered, not just fresh installs

If you did not test something, say so plainly.

## Documentation requirements

If behaviour changes, documentation should usually change too.

Update docs when your change affects:

- installation
- configuration
- environment variables
- service exposure
- authentication
- security posture
- upgrade or migration steps
- expected outputs or file structure

Code-only changes with stale docs are not finished work.

## Security-related contributions

Security-sensitive changes must be handled carefully.

Be especially cautious when changing:

- authentication and access control
- default exposed ports
- reverse proxy rules
- secrets handling
- TLS configuration
- container privileges
- filesystem permissions
- ownership models
- network routing or VPN behaviour

Do not open public issues for security vulnerabilities. Follow the process in `SECURITY.md`.

## Style and quality

General expectations:

- prefer clarity over cleverness
- keep solutions maintainable
- preserve the project’s existing structure and conventions where possible
- do not add dependencies without a good reason
- avoid speculative changes
- avoid broad cleanup mixed into functional changes

Small, disciplined improvements are easier to review and safer to merge.

## What maintainers may reject

A pull request may be declined if it:

- does not solve a real problem
- lacks sufficient explanation
- is not tested
- creates unnecessary complexity
- weakens security defaults
- breaks expected deployment paths
- drifts from project direction
- bundles too many unrelated changes together

That is normal maintenance, not hostility.

## Contributor conduct

Be direct, but remain constructive.

Disagreement is acceptable. Sloppy, rude, or entitled behaviour is not.

## Licensing

By contributing, you agree that your contribution is provided under the repository’s existing license.