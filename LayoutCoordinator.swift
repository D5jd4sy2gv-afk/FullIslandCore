import Foundation

public enum IslandDisplayMode: String, Codable, Sendable {
    case original
    case fullIsland
}

public struct IslandStyle: Codable, Equatable, Sendable {
    public var compactSize: IslandSize
    public var expandedSize: IslandSize
    public var compactCornerRadius: Double
    public var expandedCornerRadius: Double
    public var statusBarVerticalClearance: Double

    public init(
        compactSize: IslandSize,
        expandedSize: IslandSize,
        compactCornerRadius: Double,
        expandedCornerRadius: Double,
        statusBarVerticalClearance: Double = 3
    ) {
        self.compactSize = compactSize
        self.expandedSize = expandedSize
        self.compactCornerRadius = compactCornerRadius
        self.expandedCornerRadius = expandedCornerRadius
        self.statusBarVerticalClearance = max(0, statusBarVerticalClearance)
    }
}

public struct IslandLayoutSnapshot: Codable, Equatable, Sendable {
    public var capsuleFrame: IslandRect?
    public var statusBarExclusionFrame: IslandRect?
    public var contentSafeArea: IslandInsets
    public var cornerRadius: Double
    public var opacity: Double
    public var normalizedProgress: Double
}

public struct IslandLayoutCoordinator: Sendable {
    public init() {}

    /// Progress is already eased by IslandTransitionCoordinator. Geometry must
    /// consume it directly so the capsule and status-bar avoidance never apply
    /// two different easing curves to the same transition.
    public func calculate(
        progress rawProgress: Double,
        mode: IslandDisplayMode,
        environment: IslandLayoutEnvironment,
        style: IslandStyle
    ) -> IslandLayoutSnapshot {
        guard mode == .fullIsland else {
            return IslandLayoutSnapshot(
                capsuleFrame: nil,
                statusBarExclusionFrame: nil,
                contentSafeArea: environment.nativeSafeArea,
                cornerRadius: 0,
                opacity: 0,
                normalizedProgress: 0
            )
        }

        let p = rawProgress.isFinite ? min(1, max(0, rawProgress)) : 0
        let screenWidth = max(1, environment.screen.width)
        let screenHeight = max(1, environment.screen.height)
        let scale = max(0.1, environment.displayScale)
        let margin = min(8, screenWidth / 20)
        let availableWidth = max(1, screenWidth - margin * 2)

        let requestedWidth = lerp(
            max(1, style.compactSize.width),
            max(1, style.expandedSize.width),
            p
        )
        let requestedHeight = lerp(
            max(1, style.compactSize.height),
            max(1, style.expandedSize.height),
            p
        )
        let width = min(availableWidth, requestedWidth)
        let height = min(screenHeight, requestedHeight)

        // Center on the runtime-measured sensor/notch anchor, then clamp to the
        // physical screen. No model-specific dimensions are embedded here.
        let centerX = min(screenWidth - margin - width / 2,
                          max(margin + width / 2, environment.sensorAnchor.midX))
        let y = min(screenHeight - height, max(0, environment.sensorAnchor.minY))
        let capsule = pixelAligned(
            IslandRect(x: centerX - width / 2, y: y, width: width, height: height),
            scale: scale
        )

        let side = max(0, environment.statusBarSideClearance)
        let vertical = max(0, style.statusBarVerticalClearance)
        let exclusion = boundedRect(
            IslandRect(
                x: capsule.minX - side,
                y: capsule.minY - vertical,
                width: capsule.size.width + side * 2,
                height: capsule.size.height + vertical * 2
            ),
            screenWidth: screenWidth,
            screenHeight: screenHeight,
            scale: scale
        )

        var safeArea = environment.nativeSafeArea
        safeArea.top = min(
            screenHeight,
            max(safeArea.top, capsule.maxY + max(0, environment.contentSpacing))
        )
        safeArea.top = pixelAligned(safeArea.top, scale: scale)

        let radius = lerp(
            max(0, style.compactCornerRadius),
            max(0, style.expandedCornerRadius),
            p
        )
        let clampedRadius = min(radius, min(capsule.size.width, capsule.size.height) / 2)

        return IslandLayoutSnapshot(
            capsuleFrame: capsule,
            statusBarExclusionFrame: exclusion,
            contentSafeArea: safeArea,
            cornerRadius: pixelAligned(clampedRadius, scale: scale),
            opacity: 1,
            normalizedProgress: p
        )
    }

    private func lerp(_ a: Double, _ b: Double, _ t: Double) -> Double {
        a + (b - a) * t
    }

    private func pixelAligned(_ value: Double, scale: Double) -> Double {
        (value * scale).rounded() / scale
    }

    private func pixelAligned(_ rect: IslandRect, scale: Double) -> IslandRect {
        IslandRect(
            x: pixelAligned(rect.minX, scale: scale),
            y: pixelAligned(rect.minY, scale: scale),
            width: pixelAligned(rect.size.width, scale: scale),
            height: pixelAligned(rect.size.height, scale: scale)
        )
    }

    private func boundedRect(
        _ rect: IslandRect,
        screenWidth: Double,
        screenHeight: Double,
        scale: Double
    ) -> IslandRect {
        let x = min(screenWidth, max(0, rect.minX))
        let y = min(screenHeight, max(0, rect.minY))
        let right = min(screenWidth, max(x, rect.maxX))
        let bottom = min(screenHeight, max(y, rect.maxY))
        return pixelAligned(
            IslandRect(x: x, y: y, width: right - x, height: bottom - y),
            scale: scale
        )
    }
}
