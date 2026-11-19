import Foundation

public struct RuntimeSymbolReference: Codable, Equatable, Sendable {
    public let framework: String
    public let symbol: String
    public let role: String
    public let verification: Verification

    public enum Verification: String, Codable, Sendable {
        case presentInRuntimeHeaderIndex
        case callABIUnverified
    }

    public init(framework: String, symbol: String, role: String,
                verification: Verification = .presentInRuntimeHeaderIndex) {
        self.framework = framework
        self.symbol = symbol
        self.role = role
        self.verification = verification
    }
}

/// Research leads only. These private symbols are not imported or invoked by
/// this package; their exact ABI and safe lifecycle must be verified per build.
public enum IOS27RuntimeResearchCatalog {
    public static let candidateBoundaries: [RuntimeSymbolReference] = [
        .init(framework: "SystemApertureUI",
              symbol: "SAUISystemApertureManager",
              role: "System-aperture lifecycle/manager candidate"),
        .init(framework: "SystemApertureUI",
              symbol: "SAUILayoutContext",
              role: "Aperture layout context candidate"),
        .init(framework: "SystemApertureUI",
              symbol: "SAUILayoutMetrics",
              role: "Aperture layout metrics candidate"),
        .init(framework: "SystemApertureUI",
              symbol: "SAUITransitionTracking",
              role: "Aperture transition tracking protocol candidate"),
        .init(framework: "SystemApertureUI",
              symbol: "SAUILayoutSpecifyingOverrider",
              role: "Layout specification override candidate"),
        .init(framework: "SystemStatusUI",
              symbol: "STUIStatusBarVisualProvider_PillRegionCoordinator",
              role: "Status-bar pill-region coordination candidate"),
        .init(framework: "SystemStatusUI",
              symbol: "STUIStatusBarDynamicSplitAvoidanceData",
              role: "Dynamic split/avoidance data candidate")
    ]
}
