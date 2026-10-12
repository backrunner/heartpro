# Contributing to HeartPro

Read [HeartPro Guard](.agents/skills/heartpro-guard/SKILL.md) before changing the app or website. Install the local hooks with `rtk proxy python3 Tools/install_hooks.py`. Use Conventional Commits and keep changes focused.

Start with the [README build and check commands](README.md#build). For website work, follow [website/README.md](website/README.md). Run checks that exercise the changed behavior; documentation-only changes do not require a full iOS regression run. State what passed and what still needs device or visual verification.

Use synthetic data in issues, tests, screenshots and reports. Never submit real health records, patient details, credentials, signing files, personal device identifiers or App Store account captures. Report security issues through the private channel in [SECURITY.md](SECURITY.md).

Preserve the original waveform, missing-value reasons, HealthKit permission boundaries and deterministic analysis. Algorithm changes need measured evidence and regression cases; synthetic tests alone do not establish clinical accuracy. Keep six-language user-facing text consistent through the localization tooling.

Contributions are provided under [GPL-3.0-or-later](LICENSE), unless explicitly agreed otherwise before inclusion. Only submit material you have the right to license, and identify any third-party source and its terms. See [LICENSING.md](LICENSING.md) for the separate store-distribution considerations.
