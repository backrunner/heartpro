# Review remediation and TestFlight decision

Date: 2026-10-24. This document describes the revised source and deployed website, not an Apple-approved build.

## Distribution decision

The owner authorized committing and pushing the changes and chose to retain the existing TestFlight distribution. No new app binary was uploaded, no App Store metadata was written, no review reply was sent and no resubmission or appeal was made. The existing uploaded version is 0.6.0 (4); it does **not** contain this source revision. The version and build number were not changed.

App Store Connect was inspected read-only: the rejection cited 1.4.1 for missing health-information citations and 5.1.1(ix) for individual enrollment. The screenshot showed the final getting-started page's short-recording HRV claim. A future organization enrollment remains a separate decision. Organization membership and the Apple Developer Enterprise Program are different programs.

## Implemented scope

- Getting started explains navigation, record controls, notes, exports and access to help and sources. It no longer introduces a claim that a 30-second record provides a health measurement.
- Existing analysis, waveform tools, candidate flags and scoring calculations remain. Adult normal-range cards, their backing presentation model and obsolete range tests were removed at the owner's request. Measurement distributions describe only the selected record. Algorithm thresholds were not changed.
- Eleven numbered sources are linked beside relevant explanations, in Settings and in exported PDFs. A shared catalog covers Apple data types, waveform definitions, short-recording HRV limitations, heart-rate concepts and premature beats. Sources do not establish validation of HeartPro's algorithms; custom rules and fallibility are disclosed explicitly.
- Six languages use record-oriented navigation and general copy. Exact HealthKit permission/data-type descriptions and original bibliographic titles retain necessary technical terminology. Rewording does not conceal the underlying health-data functionality.
- The app, local store materials and PDFs describe an informational measurement tool, not intended for medical-device use, whose estimates may be wrong. This is an intended-use statement, not independent legal or regulatory clearance.
- Privacy text distinguishes local app processing from user-selected PDF sharing, optional writes to Health, Apple's Health synchronization, TestFlight services and necessary website-delivery processing.
- The website's support form, intake client, customer/ticket integration, CAPTCHA and routing bindings were removed. Static help accepts no messages, personal information or files. The retired endpoint rejects requests without reading, logging, storing or forwarding the request body. No historical-ticket deletion or remote credential revocation is claimed.
- Six-language App Store/TestFlight materials and an [unsent review draft](../review-response-draft.en-US.txt) are prepared locally. [Comparable-app research](review-experience-2026-10-24.md) separates public developer accounts from verified precedents. No verified exemption from the same organization-account rejection was found.

## Validation

| Check | Result | Evidence / scope |
| --- | --- | --- |
| Core package | Passed | 53 tests, including signal quality, missing intervals, HRV, synthetic data and candidate detection |
| Localization | Passed | 686 keys in six languages; placeholders match |
| iPhone simulator | Passed | 12 selected tests: reports, six-language analysis explanations, guide/source catalog, first-use notice and large text |
| iPad Air 11-inch (M3) simulator | Passed | 10 selected tests: reports, six-language guide/source catalog and notice |
| Final resource rebuild | Passed | Five report tests and English/Chinese screenshot journeys after unused range strings were pruned |
| Source catalog contrast | Passed | Three guide tests rerun after making bibliographic metadata explicitly use semantic secondary text |
| PDFs | Passed | All six exports contain 11 source markers and tappable links within page bounds, privacy text and no former adult reference bands; waveform-only exports also include sources |
| PDF visual review | Passed | Rendered all six ten-page synthetic reports; checked pagination and sampled full-size waveform and bibliography pages |
| Website types/docs | Passed | Svelte check: zero errors/warnings; strict docs check: 16 pages / 86 records |
| Retired support endpoint | Passed | 14 unit tests, including guards that throw if request bodies or headers are accessed |
| Website browser tests | Passed | Seven tests; English/Chinese help, mobile/desktop widths, no forms/mail submission/ticket/CAPTCHA requests, JavaScript-disabled help |
| Website build/deploy | Passed | Production build and dry run; deployed version `f6dbf985-f316-4308-a232-8f7a466a8b68`, ASSETS binding only |
| Production HTTP verification | Passed | Four help/privacy pages return 200; retired endpoint and child path return 410 for GET and synthetic POST |

The first Japanese analysis-UI run found that the scrolling helper tapped a control that was only partially visible. The helper now waits for the control to fit within the usable screen; the complete selected iPhone suite passed after the correction. This was a test-navigation fix, not a change to analysis results.

Native result bundles are local under `/tmp/HeartPro-Review-*20261024.xcresult`; raw test logs and account screenshots are not published. All committed report/UI examples are synthetic. Selected screenshots, PDFs and the production HTTP record are in [the evidence directory](../evidence/review-remediation-2026-10-24/manifest.json).

## Remaining boundaries

Real-device HealthKit flows, independent accuracy on Apple Watch recordings, clinical/regulatory classification and final App Review acceptance remain unverified. Static help alone does not establish that all future App Store contact requirements are met. The release gates remain incomplete.

Existing store screenshots and website app previews describe the previously uploaded build. New screenshots in this evidence directory document selected revised flows only; they are not a complete store screenshot set. Before a future upload, bump the build, validate the signed archive, refresh the full store screenshot set and reconsider all release gates. No gate was relaxed to allow this commit.
