# Simulator screenshots

Screenshots use the app's labelled synthetic examples. The capture utility runs the six-language UI journeys and exports original XCTest PNG attachments without resizing or compositing app screens. It reads languages from the app resources and does not need private release materials.

After generating the Xcode project, choose a dedicated simulator from `rtk proxy xcrun simctl list devices available`. Use its UDID and matching screen group:

```sh
rtk proxy python3 Tools/capture_screenshots.py \
  --device SIMULATOR-UDID --group iphone-6.3
```

Supported groups are `iphone-6.3`, `iphone-6.9` and `ipad-13`. Native image dimensions must match the selected group. The utility uses the named simulator, overrides its status bar for capture and leaves it running. Results and exported images default to the ignored `TestResults/` directory. `--output` selects another capture directory. A manifest records dimensions, hashes, source fingerprint and the need for visual review.

To create the six English/Chinese website previews, install Pillow in your Python environment and pass a complete native capture directory explicitly:

```sh
rtk proxy python3 Tools/prepare_website_screenshots.py \
  --source /path/to/native-capture-directory
```

This preserves the originals and generates WebP previews and their provenance in `website/static/screenshots/`. Review the app screens, text, crop, language and source version before committing selected product previews. Development captures, raw logs and reports belong outside the public source tree; only intentionally selected product images belong in `docs/images/` or the website's static assets.
