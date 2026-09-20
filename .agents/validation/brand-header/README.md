# 左上角品牌标识

2026-09-18：用正式「心电刻印」Logo + HeartPro 字标替换首页左上角的系统心形。Logo 与 AppIcon 共享 `Tools/GenerateIcon.swift` 的路径和配色，单独导出透明 PDF 矢量资源及深色变体。iOS 26+ 通过 `sharedBackgroundVisibility(.hidden)` 移除该工具栏项的玻璃背景。

验证：Xcode 27 / iOS 27 模拟器 HeartPro-Analysis 构建通过；543 个本地化键检查通过。检查实际模拟器截图，Logo、心电镂空和字标可见，品牌项无胶囊背景，设置按钮仍正常显示。大字号检查限于本次修改的页头；未重新验证授权流程或 iOS 18 回退运行。

- [浅色](light.png)
- [深色](dark.png)
- [无障碍字号](large-text.png)

```sh
rtk proxy swift Tools/GenerateIcon.swift --brand-mark HeartPro/Resources/Assets.xcassets/BrandMark.imageset
rtk proxy xcodebuild -quiet -project HeartPro.xcodeproj -scheme HeartPro -destination 'platform=iOS Simulator,id=296BE700-A282-4A86-97B3-1FDA17426238' -derivedDataPath DerivedData CODE_SIGNING_ALLOWED=NO build
rtk proxy python3 Tools/localization.py --check
```
