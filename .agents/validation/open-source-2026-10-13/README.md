# Open-source preparation — 2026-10-13

**Publication: pending. The GitHub repository remains private.** The current tree has been prepared for GPL-3.0-or-later distribution, but making the existing repository public would expose old account captures. A clean current tree is not a clean repository history.

## Scope and findings

The audit started from `d1f13870d7f6d4b0d17f548a9745775e8f13023c` on `main`. The checkout was clean. GitHub had one branch, no tags, releases, release assets, pull requests, issues or Actions artifacts. All seven reachable commits use the same contributor identity. This checks repository attribution, not a legal determination of ownership.

| Area | Result | Evidence / limits |
| --- | --- | --- |
| Secret scanning | Passed | Gitleaks scanned all seven commits reachable from local refs, about 10.51 MB of text; no findings. This does not cover inaccessible GitHub caches or establish that every possible secret format is absent. |
| Personal account data | Pending for history | Three App Store screenshots and three account-page text captures in `AppStore/evidence/build-4-2026-10-13` contained personal names. Originals were archived privately and removed from the current tree. Their old Git blobs remain reachable. |
| Media review | Passed for targeted text checks | OCR/PDF extraction covered 664 remaining current media files and 126 historical-only variants. No further personal-name/phone candidates were found; email matches were the public support address and example placeholders. Textless artwork and OCR limitations remain; this is not a claim of exhaustive forensic or clinical review. |
| Health data | Passed for inspected material | Product screenshots are tied to synthetic fixtures and capture manifests. `watch-records.csv` contains a header only. No raw MIT-BIH `.dat`, `.hea` or `.atr` records are tracked. Health-record upload or live HealthKit tests were not run. |
| External documents | Passed for current tree; pending for history | Twenty complete Apple documentation captures were archived privately and replaced with official source links. Historical copies remain in Git. |
| License | Passed for preparation | Added the standard GNU GPLv3 text, explicitly selected GPL-3.0-or-later for original code/docs/artwork, and added contribution, security and third-party notices. No custom store exception or copyright assignment was added. |
| Dependencies | Passed for inspected environment | Native Swift package has no external dependencies. Installed website graph has 290 package-name entries: MIT, ISC, BSD, Apache-2.0, CC0, MPL-2.0 and LGPL-3.0-or-later. Platform binaries and future lockfile changes need their own notice/source review. |
| README presentation | Passed | English root and website READMEs; formal light/dark app icons; three native build-4 screenshots. GitHub Markdown rendering, local links, loaded images and light/dark browser previews checked. |
| GitHub retained records | Pending | Four pre-existing workflow runs were listed. Some refer to commits outside current fetched refs. One older success log was readable without personal-name matches; two older failure logs were unavailable. No claim that unreachable server objects or expired logs were purged. |

## Checks run

- `swift test --package-path Packages/HeartProCore`: 55 tests passed.
- `python3 -m unittest discover -s Tools/tests`: 27 tests passed.
- `python3 Tools/localization.py --check`: 677 keys across six languages; placeholders match.
- `python3 Tools/check_entitlements.py`: passed, source-only audit.
- `python3 Tools/check_appstore.py`: local materials passed; no distribution approval inferred.
- `pnpm test:support` in `website`: 8 mock-service tests passed, no production tickets.
- Six public documents: all local links and image paths resolve.
- Native App/UI tests and website deployment: not applicable to this documentation/license cleanup; not rerun or redeployed.

Final staged hygiene and remote CI are recorded with the preparation commit and its GitHub workflow result.

## Before changing visibility

The private originals and a bundle of the seven reachable commits are retained under the ignored `.release-private/open-source-2026-10-13/`. Do not publish that directory or bundle.

Do not merely delete the files at HEAD and change visibility. Either preserve this repository as a private archive and publish a reviewed clean snapshot in a new repository, or obtain explicit authorization to rewrite the pushed history and address GitHub's retained references/caches before making the existing repository public. The former keeps the original audit trail and avoids exposing old Git objects through the new public repository.

The [commit rules](../../skills/heartpro-guard/references/commits.md) require explicit authorization before rewriting pushed history. This preparation does not perform a force push, rename a repository, delete workflow history or change visibility.

Open-source readiness is separate from App Store distribution, trademark clearance and clinical validation. See [licensing notes](../../../LICENSING.md) and the existing app-release evidence for those boundaries.
