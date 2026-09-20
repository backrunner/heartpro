---
title: "Methods and limitations"
description: "What HeartPro calculates, what is unvalidated, and how to interpret source data."
---

## Source data and original waveform
HealthKit supplies the original single-lead ECG voltage series, sample timing and Apple's recorded classification. HeartPro displays that source classification; it does not perform Apple's atrial-fibrillation classification. Waveform views rescale the supplied data for display and support manual two-point measurements.

## Automatic estimates
HeartPro runs deterministic Swift signal processing locally. It checks signal quality, estimates R peaks and RR intervals, compares timing and local waveform shape, and estimates eligible P, PR, QRS, ST/J, T, QT, QTc and other intervals. Boundary ambiguity, insufficient duration, noise and overlapping waves can suppress an estimate. Missing values are not replaced with zero. U-wave candidates appear only when enough repeatable, separated candidates exist.

Candidate premature beats combine timing and waveform rules. Wide/narrow categories do not establish ventricular/atrial origin. The rhythm reference score is the proportion of beats not flagged by these rules; it is not a health score, risk estimate or assurance that a rhythm is safe. Both false positives and missed events can occur.

## Two different HRV sources
Apple Health HRV uses the SDNN samples supplied by HealthKit. HRV estimated from a single short ECG is separate: it uses eligible intervals and does not bridge rejected gaps for adjacent-interval statistics. The filtering rules cannot confirm normal beats. A roughly 30-second estimate is not equivalent to standardized five-minute HRV or its reference values.

## Evidence status
These automatic calculations have not been validated against independently annotated real Apple Watch recordings. A prior development comparison with eight public MIT-BIH recordings reported 43.78% overall premature-beat sensitivity and substantial missed events in complex rhythms. Those Holter recordings differ from Watch single-lead ECGs; this is a limited development benchmark, not a clinical accuracy claim or representative Watch validation.

No regulatory clearance for HeartPro is claimed. Retaining these features does not establish readiness for App Store review. Watch accuracy evidence is a release prerequisite. Numerical agreement on synthetic signals, UI tests and PDFs do not establish medical performance.

## Making decisions
HeartPro cannot reliably identify or exclude a heart attack, ischemia or other heart disease. A high score, no marked candidates, missing measurement or Apple's sinus classification does not mean you are safe. Consult a doctor before medical decisions. For persistent chest pain, severe breathlessness or fainting, seek emergency help immediately.

## References
- [Apple: ECG on Apple Watch](https://support.apple.com/en-us/120278)
- [Apple: HealthKit ECG data](https://developer.apple.com/documentation/healthkit/hkelectrocardiogram)
- [Shaffer & Ginsberg: An Overview of HRV Metrics and Norms](https://pmc.ncbi.nlm.nih.gov/articles/PMC5624990/)
- [MSD: Electrocardiography](https://www.msdmanuals.com/professional/cardiovascular-disorders/cardiovascular-tests-and-procedures/electrocardiography)
- [PhysioNet: MIT-BIH Arrhythmia Database](https://physionet.org/content/mitdb/1.0.0/)

These references explain source data and concepts. They do not validate HeartPro's implementation.
