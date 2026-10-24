# Artwork

The current icon and brand mark are original Core Graphics paths in `Tools/GenerateIcon.swift`. The app uses the generated resources in `HeartPro/Resources/Assets.xcassets`.

Generate the light and dark 1024 × 1024 sRGB icons without transparency:

```sh
rtk proxy swift Tools/GenerateIcon.swift HeartPro/Resources/Assets.xcassets/AppIcon.appiconset/AppIcon.png
```

Generate the vector brand marks:

```sh
rtk proxy swift Tools/GenerateIcon.swift --brand-mark HeartPro/Resources/Assets.xcassets/BrandMark.imageset
```

The system applies the app-icon corner mask. Brand marks have transparent backgrounds. Original artwork is covered by the repository's GPL-3.0-or-later license; trademark rights and third-party system UI remain separate as explained in [licensing](../LICENSING.md).
