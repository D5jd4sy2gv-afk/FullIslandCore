# FullIslandCore — v0.2 architecture prototype

This is a portable, testable core for a future independent Dynamic Island system plugin. It is **not an installable tweak, IPA, SpringBoard injection payload, or jailbreak**.

## What changed in v0.2

- One easing curve now lives in `IslandTransitionCoordinator`. `IslandLayoutCoordinator` consumes the same eased progress directly, avoiding the double-smoothstep timing mismatch in v0.1.
- Geometry is clamped to runtime screen bounds and snapped to the measured display scale.
- Large capsule profiles cannot create negative/off-screen exclusion geometry.
- `CoordinatedSpringBoardBridge` separates the System Aperture host from the status-bar region host and rolls both sides back if publishing either side fails.
- `IOS27RuntimeResearchCatalog` records candidate iOS 27 private-framework symbols without importing or invoking them.
- Plugin preferences remain in their own JSON store; no MobileGestalt, SpringBoard preference, status-bar archive, or display plist writer is included.

## iOS 27 research boundary

The iOS 27.0 runtime-header index lists `SystemApertureUI` symbols including `SAUISystemApertureManager`, `SAUILayoutContext`, `SAUILayoutMetrics`, `SAUITransitionTracking`, and `SAUILayoutSpecifyingOverrider`. The `SystemStatusUI` index lists `STUIStatusBarVisualProvider_PillRegionCoordinator` and `STUIStatusBarDynamicSplitAvoidanceData`.

These are reverse-engineered private runtime symbols. Their presence in a header index is evidence of symbol names, **not** evidence that an arbitrary third-party process may call them, that their ABI is stable, or that they expose a supported system-wide layout override. No private method signatures are fabricated in this prototype.

The separate `StatusBarOverrides.archive` research concerns status-bar data such as cellular entries. It is not documented as a capsule-position, status-bar geometry, or safe-area API.

## Adapter split

- `SystemApertureHostAdapter`: measure device geometry and publish/restore the capsule surface.
- `SystemStatusRegionHostAdapter`: publish/restore the system status-bar exclusion region.
- `CoordinatedSpringBoardBridge`: treats the two updates as one logical transaction and requests rollback after partial failure.

A real adapter still requires a verified SpringBoard-hosted execution mechanism and an ABI-verified implementation for the exact iOS build. The supplied `UnavailableSpringBoardBridge` deliberately fails rather than pretending to inject.

## Build and test

```sh
swift test
```

The package uses Foundation only. Tests validate the portable geometry, state machine, configuration storage, and adapter transaction contract. They do not validate iPhone hardware, private framework calls, SpringBoard injection, or an installed system plugin.

## Original configuration preservation

`FullIslandConfigurationStore` writes only a plugin-owned file. The original GestaltEdit IPA and its MobileGestalt settings remain untouched. Disabling the plugin is designed to call both host adapters' restore methods; those methods are not implemented for a real device in this package.
