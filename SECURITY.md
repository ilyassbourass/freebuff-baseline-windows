# Security Policy

## Reporting Security Issues

Please open a private security advisory on GitHub if available. If not, open a minimal issue that says a security report is needed without publishing exploit details.

## Scope

This repository contains installer scripts and documentation.

Out of scope:

- Freebuff account limits
- Freebuff country restrictions
- Codebuff server behavior
- bugs in the upstream Codebuff or Freebuff service

## Installer Safety

The installer is plain PowerShell so users can inspect it before running. It builds Freebuff from official source and does not download prebuilt executables from this repository.
