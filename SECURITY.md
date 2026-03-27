# Security Policy

## Supported versions

Security fixes are generally only considered for currently supported releases.

As a rule, support should be assumed for:

- the current stable release
- recent releases that are still realistically in active use, at maintainer discretion

Older, heavily modified, or unsupported deployments may be declined.

## Reporting a vulnerability

Do **not** report security vulnerabilities in public GitHub issues, pull requests, or discussions.

Use GitHub private vulnerability reporting or repository security advisories where available.

If that is not available, contact the maintainer through the project’s designated private security reporting path.

## What to include in a report

A useful security report should include:

- affected MediaStack version
- affected component or service
- deployment model in use
- whether the issue is default behaviour or requires non-default changes
- clear description of the vulnerability
- reproduction steps or proof of concept
- attack prerequisites
- likely impact
- any known mitigations or workarounds

Also include whether the issue affects:

- internet-exposed deployments
- authentication or authorisation
- reverse proxy behaviour
- secret handling
- VPN or routing design
- container privileges
- file permissions or ownership
- default configuration

## Do not include

Do not include real secrets, passwords, API keys, tokens, private certificates, or sensitive personal data in your report.

Sanitise logs and configuration excerpts before submitting them.

## Response approach

Reports will be reviewed and triaged as time permits.

The maintainer may:

- confirm the issue
- request more detail
- assess severity and exposure
- prepare a fix or mitigation
- coordinate responsible disclosure timing where appropriate

Not every report will result in a public advisory, but valid issues should be handled privately first.

## Scope guidance

The following are generally in scope if they arise from MediaStack’s code, templates, defaults, or documented setup:

- authentication bypass
- authorisation flaws
- insecure default exposure
- secret leakage caused by project logic or defaults
- unsafe permission or ownership defaults
- insecure reverse proxy or routing behaviour
- privilege escalation within the supported deployment model
- serious configuration generation flaws that materially reduce security

The following are generally out of scope unless MediaStack directly causes them:

- vulnerabilities in third-party applications themselves
- issues requiring the user to ignore documented security guidance
- problems caused solely by unsupported local modifications
- self-hosting risks that are inherent and already obvious
- missing hardening for niche or custom environments not covered by the project

## Disclosure

Please allow reasonable time for investigation and remediation before public disclosure.

Public disclosure before review or remediation is irresponsible and may place users at unnecessary risk.

## Security hardening note

MediaStack aims to provide sensible, security-conscious defaults, but no self-hosted stack is secure by accident.

Operators remain responsible for:

- keeping systems updated
- managing secrets properly
- validating internet exposure
- restricting access appropriately
- reviewing logs and alerts
- understanding the consequences of custom changes