# 0.4.0 rhythm research validation — 2026-09-18

This release adds premature-beat candidates, an explicit rhythm reference score and conditional U-wave candidates. These are research features. In particular, the public-data audit below shows substantial missed premature beats; this is not a reliable screening system or a validated PAC/PVC classifier. [Rules and implementation boundaries](../../rhythm-analysis.md).

## Automated checks

- 35 core tests pass on the final algorithm source. Independent constructed traces cover early narrow/wide beats at 250, 500 and 1000 Hz, repeated short–long patterns, regular/gradual timing, sharp artifacts, gaps, noise, short recordings and score abstention. Tests check unique flagged-beat counting, source-classification restrictions and old-data decoding. U tests cover repeated small separated deflections, inversion/DC offset, no U, isolated deflections and fused/large T components.
- Seven app tests pass: four PDF tests and three repository tests. Reports include actual candidate times, the score basis/rules, conditional U measurements, full waveform/long notes and all six languages. Existing note-preserving migration and retry checks pass.
- The full relevant simulator suite passes five UI tests: existing segment/beat navigation, daily/trends/settings, the six-language workflow, and two new candidate/rules/U/original-waveform workflows. The latter include German at accessibility text size. Final algorithm/presentation refinements were followed by another seven app tests and both rhythm UI tests, all passing.
- Localization validation passes for 512 keys in Simplified Chinese, English, Japanese, Korean, German and Spanish, including placeholder parity.

Environment: Xcode 27, Swift 6.4, iPhone 17 / iOS 27 Simulator. The first candidate UI test exposed a parent accessibility identifier obscuring the child buttons; explicit per-candidate identifiers/labels corrected it before the successful runs. Visual review also caught a German U-wave end label crowding the voltage unit; the unit now sits beside the vertical axis.

Evidence: [core log](core-tests.log), [full app/UI log](app-and-ui-tests.log), [final targeted app/UI log](app-and-ui-verified.log), [chart layout UI log](layout-ui-tests.log). Result bundles are `/tmp/heartpro-rhythm-final.xcresult`, `/tmp/heartpro-rhythm-verified.xcresult` and `/tmp/heartpro-rhythm-layout.xcresult`. Logs and exported attachments are preserved here; `/tmp` bundles are temporary.

## Public-data development audit

Data: [MIT-BIH Arrhythmia Database 1.0.0](https://physionet.org/content/mitdb/1.0.0/), PhysioNet, Open Data Commons Attribution License. Use the dataset citation: Moody GB, Mark RG. *The impact of the MIT-BIH Arrhythmia Database.* IEEE Engineering in Medicine and Biology Magazine 20(3):45–50 (2001). [PhysioNet citation](https://doi.org/10.1161/01.CIR.101.23.e215): Goldberger et al., *PhysioBank, PhysioToolkit, and PhysioNet*, Circulation 101(23):e215–e220 (2000).

Eight complete records, first channel MLII, 360 Hz, 480 non-overlapping 30-second windows. The 0.5-second margin at either end is omitted equally from candidate/reference matching; matching is one-to-one within 150 ms. Target labels are a/V/J/A/S. Other beat labels, including fusion beats, count as false positives if marked. Missing R peaks and rejected beats still count as false negatives. The script uses the production Swift analysis pipeline; it does not supply annotated R peaks to the detector.

| Record | Reference premature beats | TP | FP | FN | True premature beats not assessed |
| --- | ---: | ---: | ---: | ---: | ---: |
| 100 | 32 | 31 | 0 | 1 | 1 |
| 101 | 3 | 2 | 0 | 1 | 1 |
| 103 | 2 | 1 | 0 | 1 | 0 |
| 106 | 502 | 163 | 2 | 339 | 207 |
| 119 | 433 | 200 | 0 | 233 | 175 |
| 108 | 20 | 12 | 2 | 8 | 7 |
| 109 | 36 | 15 | 0 | 21 | 8 |
| 208 | 957 | 445 | 3 | 512 | 254 |
| Total | 1,985 | 869 | 7 | 1,116 | 653 |

Overall sensitivity is **43.78%** (869/1,985); candidate precision is **99.20%** (869/876). High candidate precision does not offset the low sensitivity. Of the 1,116 misses, 653 were not assessed and 463 were assessed without being classified as premature. Frequency, complex morphology, unstable references and R-peak/shape rejection need further work. A zero-candidate recording cannot rule out premature beats.

Records 100/101/103/106/119 were used during development; 108/109/208 were added as an extension. Results were inspected during development, including changes to paired-cadence template selection. This is not an independent held-out validation. MLII Holter recordings differ from Watch recordings in lead, hardware and filtering. No Watch accuracy, clinical scoring validity or clinical U-wave recognition was established. U-wave validation here is synthetic only; the rhythm score is a descriptive rule output, not a health measure.

[Machine-readable results](mitbih-summary.json), [audit log](mitbih-audit.log), [reproduction commands](../../rhythm-analysis.md). Raw public recordings remain outside the repository.

## UI and report evidence

- [Chinese candidates](premature-candidates.png), [original trace navigation](premature-original-waveform.png), [score rules](rhythm-score-rules.png), [U candidate](u-candidate-waveform.png).
- [German large-text candidates](de-large-premature-candidates.png), [rules](de-large-rhythm-rules.png), [U candidate](de-large-u-candidate.png).
- [English rhythm](en-rhythm.png), [Japanese](ja-rhythm.png), [Korean](ko-rhythm.png), [Spanish](es-rhythm.png). Six-language report files and existing workflow captures are also included.
- [Candidate/U report](rhythm-candidates-and-u.pdf), [rendered score page](rhythm-report-page-4.png), [rendered U page](rhythm-report-page-9.png).

Chinese candidate/score/U pages, German large-text pages and the score/U report pages were visually inspected. Simulator automation and generated PDFs do not establish real HealthKit synchronization, device performance, iOS 18 material fallback, full accessibility compliance or native-speaker medical terminology review.
