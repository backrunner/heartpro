# Supported-feature presentation — 2026-09-18

U-wave automatic measurements and all score surfaces are hidden. The same supported-segment list drives UI and PDF, including records with legacy U-wave placeholders. Supported measurements that fail for a particular recording retain their reason and missing value. Analysis data and version are unchanged.

Validation on iPhone 17 / iOS 27 Simulator:

- 28 core tests pass.
- Six report/repository tests pass. PDF checks in all six languages assert that supported segment titles remain present and U-wave titles / unsupported status are absent. User notes remain intact.
- Segment/beat navigation and daily/trend/settings UI tests pass.
- The six-language analysis/HRV UI test passes. It checks U-wave entry absence, both heart-rate and Health SDNN trend controls, and score-control absence in every language.
- Localization check passes for 475 keys in six languages.

[Updated Chinese interface](supported-ui.jpg), [English timeline](en-timeline.png), [Chinese report](report-zh-Hans.pdf), [English report](report-en.pdf). All six language screenshots and PDFs are in this folder. Chinese timeline, HRV and trends screenshots were visually inspected.

Logs: `core-tests.log`, `app-and-ui-tests.log`. Result bundle: `/tmp/heartpro-supported-features.xcresult`.

This is presentation and export validation using synthetic data. It does not add an automatic U-wave detector, a clinical score, beat-type classification or clinical validation of existing measurements.
