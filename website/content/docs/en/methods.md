---
title: "Methods and limitations"
description: "What HeartPro calculates, what is unvalidated, and how to interpret source data."
---

## Source data and original waveform
HealthKit supplies the original single-lead ECG voltage series, sample timing and Apple's recorded classification [A1, A2]. HeartPro displays that source classification; it does not perform Apple's atrial-fibrillation classification. Waveform views rescale the supplied data for display and support manual two-point measurements.

## Informational measurements
HeartPro is an informational measurement and record-review tool, not intended for use as a medical device. Its estimates may be wrong and are not for diagnosis, treatment or assessing personal health.

### Automatic estimates
HeartPro runs deterministic Swift signal processing locally. It checks signal quality, estimates R peaks and RR intervals, compares timing and local waveform shape, and estimates eligible P, PR, QRS, ST/J, T, QT, QTc and other intervals. Boundary ambiguity, insufficient duration, noise and overlapping waves can suppress an estimate. Missing values are not replaced with zero. U-wave candidates appear only when enough repeatable, separated candidates exist.

Candidate premature beats combine timing and waveform rules. Wide/narrow categories do not establish ventricular/atrial origin. For the general clinical concept of premature contractions, see the American Heart Association [R1]. The rhythm reference score is HeartPro's own proportion of beats not flagged by these rules; it is not a published medical scale, health score, risk estimate or assurance that a rhythm is safe. Both false positives and missed events can occur.


HeartPro displays measurements and the distribution within the selected record, without adult normal ranges, normal/abnormal comparisons or personal clinical interpretations. P/PR and waveform definitions are explained in [E1, E2]; ST/T/U/QT concepts and correction methods in [E3]. These sources explain concepts and methods, not diagnostic thresholds applied to your record. A usage notice appears before first use and remains available in Settings. It does not replace algorithm validation or applicable regulatory requirements.

Detection thresholds, quality filters, candidate labels and the rhythm reference score are HeartPro's own implementation rules. They are disclosed in the app and PDF method sections, not attributed to medical guidelines. Published descriptions of ECG components do not validate these rules.

## Two different HRV sources
Apple Health HRV uses the SDNN samples supplied by HealthKit [A3]. HRV estimated from a single short ECG is separate: it uses eligible intervals and does not bridge rejected gaps for adjacent-interval statistics. The filtering rules cannot confirm normal beats. SDNN, RMSSD and Poincaré SD1/SD2 concepts are described in [H1]. Short recordings can yield interval statistics, but reliability depends on the metric, recording length and acquisition conditions. Munoz et al. (2015) and Burma et al. (2021) report different results under different protocols [H2, H3]. Neither study validates HeartPro or its Watch implementation. A roughly 30-second estimate is not equivalent to standardized five-minute HRV or its measurement context.

## Evidence status
These automatic calculations have not been validated against independently annotated real Apple Watch recordings. A prior development comparison with eight public MIT-BIH recordings reported 43.78% overall premature-beat sensitivity and substantial missed events in complex rhythms. Those Holter recordings differ from Watch single-lead ECGs; this is a limited development benchmark, not a clinical accuracy claim or representative Watch validation.

No regulatory clearance for HeartPro is claimed. Numerical agreement on synthetic signals, UI tests and PDFs does not establish medical performance.

## Making decisions
HeartPro cannot reliably identify or exclude a heart attack, ischemia or other heart disease. A high score, no marked candidates, missing measurement or Apple's sinus classification does not mean you are safe. Consult a doctor before medical decisions. For persistent chest pain, severe breathlessness or fainting, seek emergency help immediately. Apple's ECG guidance explains single-lead limitations, that its ECG app cannot detect a heart attack, and when to seek care [A1]. This does not validate HeartPro's analysis.

## References
The same identifiers appear in the app and PDF. Open **Settings → Health information and sources** for the complete catalog; relevant explanation panels also link directly to their sources. Bibliographic titles retain the original publication language.

- [A1 — Apple Support: Take an ECG with the ECG app on Apple Watch](https://support.apple.com/en-us/120278).
- [A2 — Apple Developer: HKElectrocardiogram](https://developer.apple.com/documentation/healthkit/hkelectrocardiogram).
- [A3 — Apple Developer: heartRateVariabilitySDNN](https://developer.apple.com/documentation/healthkit/hkquantitytypeidentifier/heartratevariabilitysdnn).
- [E1 — Cascino & Shea: Electrocardiography. MSD Manual Professional Edition, 2026](https://www.msdmanuals.com/professional/cardiovascular-disorders/cardiovascular-tests-and-procedures/electrocardiography).
- [E2 — Douedi & Douedi: P wave. StatPearls, updated 2023](https://www.ncbi.nlm.nih.gov/books/NBK551635/).
- [E3 — Rautaharju et al.: AHA/ACCF/HRS ECG standardization, part IV. Circulation, 2009. doi:10.1161/CIRCULATIONAHA.108.191096](https://pubmed.ncbi.nlm.nih.gov/19228821/).
- [H1 — Shaffer & Ginsberg: An Overview of Heart Rate Variability Metrics and Norms, 2017. doi:10.3389/fpubh.2017.00258](https://pubmed.ncbi.nlm.nih.gov/29034226/).
- [H2 — Munoz et al.: Validity of (Ultra-)Short Recordings for Heart Rate Variability Measurements, 2015. doi:10.1371/journal.pone.0138921](https://pubmed.ncbi.nlm.nih.gov/26414314/).
- [H3 — Burma et al.: The validity and reliability of ultra-short-term heart rate variability parameters and the influence of physiological covariates, 2021. doi:10.1152/japplphysiol.00955.2020](https://pubmed.ncbi.nlm.nih.gov/33856258/).
- [R1 — American Heart Association: Premature Contractions — PACs and PVCs, 2024](https://www.heart.org/en/health-topics/arrhythmia/about-arrhythmia/premature-contractions-pacs-and-pvcs).
- [R2 — American Heart Association: All About Heart Rate (Pulse), 2024](https://www.heart.org/en/health-topics/high-blood-pressure/the-facts-about-high-blood-pressure/all-about-heart-rate-pulse).
- [Development benchmark only — PhysioNet: MIT-BIH Arrhythmia Database](https://physionet.org/content/mitdb/1.0.0/).

These references explain source data and concepts. They do not validate HeartPro's implementation.
