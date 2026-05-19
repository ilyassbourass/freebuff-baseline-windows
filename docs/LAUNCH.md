# Launch Checklist

This repo solves one specific problem: the official Freebuff Windows binary can fail on older CPUs that do not support AVX2.

## Positioning

Use this wording:

> Run Freebuff on older Windows CPUs without AVX2.

Avoid this wording:

> Freebuff fork
> Better Freebuff
> Unlocked Freebuff

This project is a compatibility installer. It does not bypass Freebuff server-side limits, country restrictions, quotas, or model access.

## Before Sharing

- Confirm `install.ps1` is readable and not minified.
- Confirm `README.md` shows the AVX2 failure and working output screenshots.
- Confirm the raw install URL returns HTTP 200.
- Confirm the repo has topics: `freebuff`, `codebuff`, `bun`, `windows`, `avx2`, `baseline`, `old-cpu`, `cli`, `powershell`, `compatibility`.
- Upload `assets/social-preview.png` in GitHub repo settings as the social preview image.

## Where To Share

Use one concise post per place. Do not spam.

- Codebuff/Freebuff GitHub issue or discussion, if relevant.
- Reddit: `r/commandline`, `r/Windows`, `r/github`, or AI coding tool communities.
- Hacker News Show HN only after the installer has been tested by more than one user.
- X/Twitter or LinkedIn with the crash screenshot and the working output screenshot.

## Post Template

```text
I hit Freebuff's Windows AVX2 crash on an older Intel i5 650 machine.

I made an unofficial compatibility installer that builds Freebuff from the official Codebuff source using Bun's Windows x64 baseline target.

It does not bypass Freebuff limits or account restrictions. It only fixes the local CPU binary compatibility problem.

Repo: https://github.com/ilyassbourass/freebuff-baseline-windows
```

## Trust Notes

People are cautious with PowerShell installers. Keep the trust model simple:

- build from official source
- no bundled executable
- plain PowerShell
- clear uninstall path
- screenshots of before and after
- no bypass claims

## Later Improvements

- Add a signed release only if users ask for binaries.
- Add GitHub Actions CI after the GitHub token has `workflow` scope.
- Add OpenSSF Best Practices Badge after the project has stable docs and issue handling.
- Add a small website only if search traffic grows.
