# HeartPro localization

Supported app languages: Simplified Chinese (`zh-Hans`), English (`en`), Japanese (`ja`), Korean (`ko`), German (`de`) and Spanish (`es`). The app follows iOS's per-app language preference; Settings → Language opens the system app settings. Regional variants use their base translation, and unsupported languages fall back to English. Chinese variants use Simplified Chinese.

`catalog.json` records source keys and source locations. `translations/*.tsv` contains `id|English|Japanese|Korean|German|Spanish`; use literal `\n` for a line break. Translate complete sentences and retain every `{0}`, `{1}`, etc. placeholder exactly once wherever it occurs in the source. Arguments may be reordered. Prefer count-neutral labels when a noun would otherwise require plural rules.

`zh-Hans.json` holds edited Chinese display copy by catalog ID; entries without an override use the source key. This keeps lookup keys and saved reasons stable when revising wording. Prefer short labels, a single-sentence explanation and concrete missing-measurement reasons. Keep formulas and thresholds in expandable details. Use “疑似” for unconfirmed findings and retain the distinction between the rhythm score and heart health.

Generate native `.strings` resources after editing:

```sh
rtk proxy python3 Tools/localization.py
rtk proxy python3 Tools/localization.py --check
rtk proxy xcodegen generate
```

The checker validates all six translations, placeholder parity, new `L10n.text` source keys, and generated resources. HealthKit permission descriptions live in `InfoPlist.json` and generate app-bundle `InfoPlist.strings`. Keeping these app localizations also exposes supported languages to iOS.

SwiftUI, domain presentation and PDFs share `HeartProCore.L10n` and the package's native resource bundle. `L10n.text` captures interpolated arguments separately from the key; translated templates substitute them in one pass, without interpreting braces inside notes or other user text. `L10n.withLanguage` scopes synchronous report rendering and tests without changing system or app preferences. Dates, charts, lists and decimal numbers use the selected app locale.

Do not localize persisted enum raw values, signal-analysis reason identifiers, HealthKit source names or user notes. Localize their display properties. App-defined failures implement `LocalizedFailure`; save their `messageKey` and resolve it when displayed. Operating-system error descriptions are supplied by the OS and are not rewritten.

Measurement status uses specific copy:

- `等待分析`: no analysis available yet.
- `暂时无法测量`: insufficient information for this value; show the associated reason.
- Unsupported measurements are hidden from the UI and PDF instead of displaying `暂不支持`. Since 0.4, `SegmentAnalysis.visibleSegments` includes the supported base segments and adds U-wave candidates only when at least three repeated candidates have measurements. Persisted enum cases remain decodable.
- Numeric blanks are never replaced with zero, and no medical interpretation is implied.

Validation:

```sh
rtk proxy swift test --package-path Packages/HeartProCore
rtk proxy xcodebuild -project HeartPro.xcodeproj -scheme HeartPro \
  -destination 'platform=iOS Simulator,name=iPhone 17' -derivedDataPath DerivedData \
  -parallel-testing-enabled NO -collect-test-diagnostics never CODE_SIGNING_ALLOWED=NO test
```

`LocalizationUITests` launches the real app using `-AppleLanguages` and `-AppleLocale` for each language, tests segment navigation, an unmeasurable beat and the HRV explanation, and attaches screenshots. Report tests export each language and verify text, user-note preservation, placeholders and localized permission resources. These checks do not constitute native-speaker medical terminology review or real HealthKit authorization testing.
