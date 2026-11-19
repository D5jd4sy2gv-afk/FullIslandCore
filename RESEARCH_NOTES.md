# Research notes — 2026-11-19 (v0.2)

## Supplied IPA

`GestaltEdit-v2.3.1-unsigned.ipa` is a MobileGestalt editor, not a SpringBoard plugin. The package inspection in v0.1 found an ARM64 UIKit/SwiftUI app, no injected SpringBoard dylib/framework/extension, and the strings `supportsDynamicIsland` and `_dynamicIslandSubtype`. Those keys concern device capability eligibility/subtype; they do not establish a system UI host or display canvas geometry control.

The original IPA is not edited by this prototype.

## Runtime framework evidence

The iOS 27.0 runtime-header index lists:

### `SystemApertureUI`

- `SAUISystemApertureManager`
- `SAUILayoutContext`
- `SAUILayoutMetrics`
- `SAUITransitionTracking`
- `SAUILayoutSpecifyingOverrider`
- `SAUILayoutHosting` / `SAUILayoutHostingPrivate`

These symbol names suggest candidate boundaries for aperture lifecycle, layout context/metrics, transition tracking, and layout override. The index does not by itself prove how to instantiate these symbols or safely mutate system UI.

### `SystemStatusUI`

- `STUIStatusBarVisualProvider_PillRegionCoordinator`
- `STUIStatusBarDynamicSplitAvoidanceData`
- `STUIStatusBarPillRegionVisualProvider-Protocol`
- `STUIStatusBarVisualProvider_DynamicSplit`

These names support a distinct status-bar pill-region/avoidance path. The exact ABI and runtime contract remain unverified for build `24A437`.

### `StatusBarOverrides.archive`

Community reverse-engineering describes the iOS 27 archive as an `NSKeyedArchiver` record consumed by SpringBoard/SystemStatusUI, with `STStatusBarData` cellular entries and carrier/network status data. This is not evidence of a geometry override for the Dynamic Island capsule. Delivery is a separate constraint on non-jailbroken devices.

## Erosion / worse_query boundary

The public Erosion repository lists iOS/iPadOS 27.0–27.2 support for its `worse_query`-based customization workflow. Its own README explains that MobileGestalt write capability and supported customization features are bounded by the exploit. This is not equivalent to a general jailbreak or permission to inject a dynamic library into SpringBoard.

## Architecture decision

The integration is divided into two adapters:

1. System Aperture surface adapter — capsule geometry/lifecycle.
2. System Status region adapter — status-bar pill-region exclusion and avoidance.

One shared transition progress drives both. Environment measurements must be read from the actual target device at runtime, including screen bounds, scale, native safe area, and sensor/notch anchor. No iPhone 12 dimensions are hardcoded.

## Current limitations

- No verified public API for global SpringBoard layout mutation was found.
- Private runtime symbols are listed as research leads only; method signatures are not invented.
- No SpringBoard injection method is implemented or claimed.
- No system file, MobileGestalt cache, original configuration, or supplied IPA has been changed.

## Exact target build cross-check

- The iPhone 12 identifier `iPhone13,2` is listed with iOS 27.0 release build `24A437` (released 2026-09-14).
- The current public Erosion README lists iOS/iPadOS 27.0–27.2 as supported by its customization workflow. This is a version-level project claim; it is not a device-specific test of this plugin or proof of SpringBoard injection on `iPhone13,2 / 24A437`.
- The public `rooootdev/mond` README lists only iOS 27.0 developer betas 1–4 and public betas 1–2 for its older workflow. It should not be treated as evidence of compatibility with the final 24A437 release.
- Apple's iOS 27 release notes document that deprecated `UIApplication` status-bar accessors (including `statusBarFrame`) may return NaN/null when apps are built with the iOS 27 SDK. The core therefore does not use those accessors; the eventual host adapter must measure from scene/view geometry appropriate to its host process.

## Source links used

- Apple iOS 27 release notes: https://developer.apple.com/documentation/ios-ipados-release-notes/ios-ipados-27-release-notes
- iOS 27.0 SystemApertureUI runtime-header index: https://developer.limneos.net/?framework=SystemApertureUI.framework&ios=27.0
- iOS 27.0 SystemStatusUI runtime-header index: https://developer.limneos.net/?framework=SystemStatusUI.framework&ios=27.0
- iOS 27 StatusBarOverrides archive reverse-engineering report: https://github.com/leminlimez/Nugget/issues/1156
- Erosion project support statement: https://github.com/jailbreakdotparty/Erosion
- Mond project version statement: https://github.com/rooootdev/mond
- iPhone 12 / iOS 27.0 build listing: https://ipsw.me/iPhone13%2C2/
