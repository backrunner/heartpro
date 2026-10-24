# Third-party notices

HeartPro’s GPL license applies to original project material. It does not replace the licenses of dependencies, Apple SDKs or research datasets. No third-party Swift packages are linked into the native app.

## Website dependencies

Resolved direct dependencies reviewed on 2026-10-13 from the installed lockfile environment:

| Package | Version | License |
| --- | --- | --- |
| `@playwright/test` | 1.63.0 | Apache-2.0 |
| `@sveltejs/adapter-static` | 3.0.10 | MIT |
| `@sveltejs/kit` | 2.70.3 | MIT |
| `@sveltejs/vite-plugin-svelte` | 7.3.0 | MIT |
| `@tailwindcss/vite` | 4.3.3 | MIT |
| `@types/node` | 25.9.8 | MIT |
| `svedocs` | 0.2.1 | MIT |
| `svedocs-cli` | 0.2.1 | MIT |
| `svelte` | 5.57.1 | MIT |
| `svelte-check` | 4.7.6 | MIT |
| `tailwindcss` | 4.3.3 | MIT |
| `typescript` | 6.0.3 | Apache-2.0 |
| `vite` | 8.3.0 | MIT |
| `wrangler` | 4.149.0 | MIT OR Apache-2.0 |

The full installed production and development graph contains MIT, ISC, BSD-2-Clause, BSD-3-Clause, Apache-2.0, CC0-1.0, MPL-2.0 and LGPL-3.0-or-later licenses. Review changes whenever the lockfile changes:

```sh
rtk proxy pnpm --dir website licenses list --json
```

MPL components include `@resvg/resvg-js`, `lightningcss`, `satori` and their platform packages. The image build toolchain also uses `sharp` (Apache-2.0) and prebuilt libvips (`@img/sharp-libvips-*`, LGPL-3.0-or-later), which has its own bundled notices. These website tools are not embedded in the native iOS app. Preserve upstream notices and fulfill source obligations when redistributing those components or generated bundles. Platform-specific packages must be checked on the platform being distributed.

Upstream guidance: [Apache / GPLv3 compatibility](https://www.apache.org/licenses/GPL-compatibility), [Mozilla MPL / GPL combination rules](https://www.mozilla.org/en-US/MPL/2.0/combining-mpl-and-gpl/), [libvips licensing](https://www.libvips.org/).

## Research data

`Tools/audit_ectopy.py` downloads selected records from the [MIT-BIH Arrhythmia Database 1.0.0](https://physionet.org/content/mitdb/1.0.0/) under the Open Data Commons Attribution License. Raw records are not included in this repository and must stay outside it. The repository retains derived evaluation summaries with attribution in the [research audit](docs/research/mitbih-audit.md).

Cite Moody and Mark, *The impact of the MIT-BIH Arrhythmia Database*, IEEE Engineering in Medicine and Biology Magazine 20(3):45–50 (2001), and the dataset DOI [10.13026/C2F305](https://doi.org/10.13026/C2F305). Follow the dataset page’s current citation requirements when conducting a new audit. Public Holter data does not establish Apple Watch accuracy.

## Artwork and external references

The HeartPro icon and brand mark are original Core Graphics paths in `Tools/GenerateIcon.swift`; no stock image or third-party logo is used. Product screenshots use labelled synthetic fixtures and include Apple system UI. Apple names, system UI and SDK materials retain their respective rights; they are not original HeartPro artwork.

Captured Apple documentation pages have been replaced by links to their official sources. Third-party text, trademarks and service terms are not relicensed under HeartPro’s GPL grant.
