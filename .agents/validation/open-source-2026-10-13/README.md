# Open-source preparation — 2026-10-13

**Publication: explicitly authorized on 2026-10-13; GitHub server-side cleanup remains pending.** The user's latest instruction requests committing and pushing all remaining changes, then making the existing repository public. This supersedes the earlier publication hold pending server-side cleanup. All eight original commits were cleaned and force-pushed. Branch history is clean, but authenticated requests for old commit SHA objects still retrieve personal account captures on GitHub; public visibility may expose these retained files.

## Scope and findings

The audit started from `d1f13870d7f6d4b0d17f548a9745775e8f13023c` on `main`. The checkout was clean. GitHub had one branch, no tags, releases, release assets, pull requests, issues or Actions artifacts. All seven reachable commits use the same contributor identity. This checks repository attribution, not a legal determination of ownership.

| Area | Result | Evidence / limits |
| --- | --- | --- |
| Secret scanning | Passed | Gitleaks scanned all seven commits reachable from local refs, about 10.51 MB of text; no findings. This does not cover inaccessible GitHub caches or establish that every possible secret format is absent. |
| Personal account data | Passed for published branch history; pending server purge | Three screenshots and three account-page text captures contained personal names. They were removed from all eight rewritten commits and excluded by exact ignore rules. Old SHA retrieval still succeeds on GitHub. |
| Media review | Passed for targeted text checks | OCR/PDF extraction covered 664 remaining current media files and 126 historical-only variants. No further personal-name/phone candidates were found; email matches were the public support address and example placeholders. Textless artwork and OCR limitations remain; this is not a claim of exhaustive forensic or clinical review. |
| Health data | Passed for inspected material | Product screenshots are tied to synthetic fixtures and capture manifests. `watch-records.csv` contains a header only. No raw MIT-BIH `.dat`, `.hea` or `.atr` records are tracked. Health-record upload or live HealthKit tests were not run. |
| External documents | Passed for published branch history | Twenty complete Apple documentation captures were replaced with official source pointers in every rewritten commit. Original copies remain outside the rewritten branch history, in private archives/local recovery objects and retained old server objects. |
| License | Passed for preparation | Added the standard GNU GPLv3 text, explicitly selected GPL-3.0-or-later for original code/docs/artwork, and added contribution, security and third-party notices. No custom store exception or copyright assignment was added. |
| Dependencies | Passed for inspected environment | Native Swift package has no external dependencies. Installed website graph has 290 package-name entries: MIT, ISC, BSD, Apache-2.0, CC0, MPL-2.0 and LGPL-3.0-or-later. Platform binaries and future lockfile changes need their own notice/source review. |
| README presentation | Passed | English root and website READMEs; formal light/dark app icons; three native build-4 screenshots. GitHub Markdown rendering, local links, loaded images and light/dark browser previews checked. |
| GitHub retained records | Pending server purge | Five pre-rewrite workflow records were privately backed up where available and removed; two older logs were unavailable. No Actions artifacts or caches exist. Direct old-SHA retrieval of personal text and image files still returns success. |

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

## Authorized history rewrite

The user explicitly chose cleanup and force push of this repository; no repository rename or replacement was performed. The private backup includes the original reachable history, raw account captures, available CI logs and the `git-filter-repo` commit map.

`git-filter-repo --sensitive-data-removal` rewrote all eight commits. It removed the six personal capture paths and replaced all versions of twenty third-party page snapshots with the reviewed source pointers. One old nonconforming commit title was normalized so the full rewritten history passes the repository commit-message guard. The rewritten tip was `0acf6d0097eec7639277a39b8c16f1c9fb4bba1a`.

Before the force push, the rewritten tip's file tree was byte-for-byte identical to the previously reviewed preparation tree. Checks covered every commit's excluded paths, reference-pointer contents and known personal-name patterns. Gitleaks scanned all eight rewritten commits (about 9.95 MB) with no findings. The full history commit guard and tracked-file guard passed; [GitHub CI for the rewritten tip](https://github.com/backrunner/heartpro/actions/runs/38412571346) also passed. The application source and assets were not changed.

The push used `--force-with-lease` tied to the previously observed remote `main`. Local and remote `main` were then verified equal; `main` is the only advertised branch and there are no tags. This follow-up adds exact ignore rules for the removed files and records the results.

## Remaining server-side cleanup

Authenticated GitHub API checks after force push and removal of old workflow records confirm:

- The removed personal text path at `main` returns 404.
- The old commit object is still retrievable by SHA.
- A personal text capture and a personal screenshot at that old SHA are still retrievable.
- There are no Actions caches, artifacts, releases or pull requests to remove.

Do not interpret a force push or a clean clone as proof that GitHub has purged old objects. [GitHub's sensitive-data removal documentation](https://docs.github.com/en/authentication/keeping-your-account-and-data-secure/removing-sensitive-data-from-a-repository) directs users to Support for cached views and server-side cleanup; there is no repository-admin Git command that proves that purge.

The GitHub Support request is prepared in the ignored private evidence directory. It has not been sent. The latest publication instruction does not establish that GitHub has removed the retained objects. Source licensing, commercial distribution and clinical validation remain separate questions.

## Publication follow-up — 2026-10-13

- Before this documentation change, the checkout had no uncommitted files and `main` matched remote commit `fb5a1488398c9759fe45039011ed267ea9fb916b`. An explicit push returned `Everything up-to-date`.
- The staged-file and tracked-file guards passed, no tracked files matched ignore rules, and [CI for that commit](https://github.com/backrunner/heartpro/actions/runs/38413045774) passed.
- Fresh authenticated probes still retrieved the old commit, personal text capture and personal screenshot. The removed text path at `main` returned 404. These probes did not print the captured contents.
- The owner explicitly requested public visibility following commit and push. Verification of publication uses GitHub repository metadata and anonymous access; publication must not be reported as a server purge.
