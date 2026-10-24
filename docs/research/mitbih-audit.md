# MIT-BIH development benchmark

This is a historical development benchmark from 2026-09-18, not independent validation of the current app or of Apple Watch measurements. The detector missed substantial numbers of premature beats. A zero-candidate recording cannot rule them out.

Data: [MIT-BIH Arrhythmia Database 1.0.0](https://physionet.org/content/mitdb/1.0.0/), PhysioNet, Open Data Commons Attribution License. Eight complete records, first channel MLII, 360 Hz, 480 non-overlapping 30-second windows. Matching excludes the same 0.5-second margin from both ends of every reference/candidate window and uses one-to-one matching within 150 ms. Target annotations are a/V/J/A/S. Other labels, including fusion beats, count as false positives when marked. Missing or rejected true beats still count as false negatives. Annotated R peaks are not supplied to the detector.

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

Overall sensitivity was **43.78%** (869/1,985), with candidate precision **99.20%** (869/876). High precision does not offset low sensitivity. Of the 1,116 misses, 653 were not assessed and 463 were assessed without being classified as premature. [Machine-readable results](mitbih-summary.json) retain the per-record values.

Records 100/101/103/106/119 were used during development; 108/109/208 were added as an extension. Results were inspected while refining the implementation. This is not a held-out study. MLII Holter recordings differ from Watch recordings in lead, hardware and filtering. No Watch accuracy, clinical scoring validity or clinical U-wave recognition was established. The rhythm score describes custom rules, not health.

## Reproduce on the current source

Use a data directory outside this repository. The following runs the current pipeline and does not claim to recreate historical results across algorithm changes:

```sh
rtk proxy swift build --package-path Packages/HeartProCore --product ECGAudit -c release
rtk proxy swift build --package-path Packages/HeartProCore -c release --show-bin-path
```

Use the second command's output directory to locate `ECGAudit`:

```sh
rtk proxy python3 Tools/audit_ectopy.py \
  --directory /tmp/heartpro-mitbih-audit \
  --executable /path/from/show-bin-path/ECGAudit \
  --records 100 101 103 106 119 108 109 208
```

The script downloads source records and writes its new `summary.json` to the selected data directory. It uses Python's standard library and the Swift executable.

## Attribution

Cite Moody GB and Mark RG, *The impact of the MIT-BIH Arrhythmia Database*, IEEE Engineering in Medicine and Biology Magazine 20(3):45–50 (2001), and dataset DOI [10.13026/C2F305](https://doi.org/10.13026/C2F305). PhysioNet citation: Goldberger et al., *PhysioBank, PhysioToolkit, and PhysioNet*, Circulation 101(23):e215–e220 (2000), [doi:10.1161/01.CIR.101.23.e215](https://doi.org/10.1161/01.CIR.101.23.e215). See [third-party notices](../../THIRD_PARTY_NOTICES.md).
