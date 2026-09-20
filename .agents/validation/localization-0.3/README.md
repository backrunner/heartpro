# Six-language validation — 2026-09-18

Validated on iPhone 17 / iOS 27 Simulator with synthetic ECG data. Languages: Simplified Chinese, English, Japanese, Korean, German and Spanish.

## Results

- All 469 message keys have six language resources and matching interpolation placeholders. `rtk proxy python3 Tools/localization.py --check` passes.
- Core: 28 tests pass, including regional language fallback, decimal formatting, reordered interpolation, preservation of user text, saved-error translation and unchanged persisted analysis.
- App: all six report/repository tests pass. Reports in every language contain segment titles, translated measurement status and unchanged multilingual notes. Permission-description resources are bundled for every language.
- Six-language UI flow passes: timeline, settings, ECG detail, P-wave analysis, metric selection, unmeasurable first beat, HRV explanation and SDNN trends. Korean also exercises dark appearance.
- Five existing UI flows pass, including notes, waveform/segment navigation, settings and accessibility text sizes. The initial settings test needed to scroll after the language section was added; its corrected targeted rerun passes.
- German accessibility-size QRS navigation passes. Visual inspection found overlapping start/end labels; positioning the labels outside their respective boundaries resolves it. The final targeted run and screenshot confirm the correction.

## Evidence

- [Six-language segment comparison](segments-languages.jpg)
- [Measurement status comparison](unavailable-languages.jpg)
- [Settings comparison](settings-languages.jpg)
- [German accessibility-size beat, after correction](de-large-beat.png)
- [English report](report-en.pdf), [Japanese report](report-ja.pdf), [Korean report](report-ko.pdf), [German report](report-de.pdf), [Spanish report](report-es.pdf), [Chinese report](report-zh-Hans.pdf)
- [English report pages](report-en-pages.jpg), [German report pages](report-de-pages.jpg), [Japanese report pages](report-ja-pages.jpg), [Korean report pages](report-ko-pages.jpg)

Logs: `core-tests.log`, `languages-and-pdf.log`, `regression-initial.log`, `settings-recheck.log`, `german-layout-recheck.log`. The initial regression log retains the settings-test failure; the corrected result is in `settings-recheck.log`. Final PDFs come from the later app regression; language UI screenshots come from the six-language run, and German large-text screenshots come from the final layout rerun.

Text checks cover all six PDFs. Rendered English, German, Japanese and Korean pages were visually inspected for wrapping, margins and footers. This validation does not include physical-device testing, real HealthKit authorization or native-speaker medical terminology review.
