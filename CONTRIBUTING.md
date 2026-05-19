# Contributing

Contributions are welcome when they improve compatibility, documentation, or installer reliability.

## Good Contributions

- clearer troubleshooting for real install failures
- support for more Windows environments
- safer installer checks
- better screenshots or documentation
- GitHub Actions improvements

## Before Opening A Pull Request

Run:

```powershell
.\test-install.ps1
```

If your change touches `install.ps1`, test it on a clean Windows machine or VM when possible.

## Rules

- Do not add code that bypasses Freebuff server-side account, country, quota, or model restrictions.
- Do not commit downloaded Freebuff binaries.
- Keep the installer readable and auditable.
- Prefer building from official source over distributing binaries.
