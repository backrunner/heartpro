# Screenshot delivery

Current **0.6.0 (1)** app screenshots are captured from the real simulator UI with labelled synthetic examples:

| Directory | Native dimensions | Languages / count |
| --- | --- | --- |
| `iphone-6.9/` | 1320 × 2868 | English and Simplified Chinese, 6 each |
| `ipad-13/` | 2064 × 2752 | English and Simplified Chinese, 6 each |

Contact sheets are beside these directories; do not upload the contact sheets. The manifests identify the build, simulator, XCTest result and PNG hashes. Automated journeys passed; visual review is recorded separately in each manifest. Initial environment failures are retained in evidence logs and were followed by successful retries. These screenshots demonstrate the app UI, not medical accuracy or real HealthKit access.

`reference-only/` contains ten older 0.3 development screenshots plus a contact sheet. These files are real historical UI with synthetic data, but are **not final App Store assets**. Their original source paths and hashes are in the manifest. The website now uses optimized copies of the current 0.6.0 iPhone images, with provenance in `website/static/screenshots/provenance.json`. Do not crop away demo labels, stretch screenshots to another device size, or imply they show another build.

Run on working dedicated simulators:

```sh
rtk proxy python3 Tools/capture_appstore.py --device IPHONE_SIMULATOR_UDID --group iphone-6.9
rtk proxy python3 Tools/capture_appstore.py --device IPAD_SIMULATOR_UDID --group ipad-13
```

Use iPhone 17 Pro Max (1320×2868) and iPad Pro 13-inch (2064×2752), or another device whose native resolution Apple accepts for that group. The exporter rejects incorrect dimensions and incomplete screenshot sets. It keeps six scenes per language: history, daily overview, trends, waveform, note, and privacy settings. Recommended upload order: waveform, history, daily, trends, note; use privacy settings only if useful. Six is within the 1–10 limit.

Capture uses the production UI, in-memory testing storage and the same labelled synthetic demo available to users. No personal Health data is accessed. After export, visually review every PNG for loaded content, labels, clipping, controls, locale and orientation. Check files against the actual release UI after any subsequent change. `visual_review_complete` starts false intentionally. The iPad system status-bar date follows the simulator system language; app content follows the selected language. To update website screenshots, run `Tools/prepare_website_screenshots.py` and update the visible version label if needed. Web previews may be resized; the upload PNGs must remain original.

App previews/videos are optional and are not included. The supplied 1024×1024 icon is under `../icons/` and is not a screenshot.
