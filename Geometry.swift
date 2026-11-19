import Foundation

public struct IslandPoint: Codable, Equatable, Sendable {
    public var x: Double
    public var y: Double
    public init(x: Double, y: Double) { self.x = x; self.y = y }
}

public struct IslandSize: Codable, Equatable, Sendable {
    public var width: Double
    public var height: Double
    public init(width: Double, height: Double) { self.width = width; self.height = height }
}

public struct IslandInsets: Codable, Equatable, Sendable {
    public var top: Double
    public var left: Double
    public var bottom: Double
    public var right: Double
    public init(top: Double = 0, left: Double = 0, bottom: Double = 0, right: Double = 0) {
        self.top = top; self.left = left; self.bottom = bottom; self.right = right
    }
}

public struct IslandRect: Codable, Equatable, Sendable {
    public var origin: IslandPoint
    public var size: IslandSize
    public init(x: Double, y: Double, width: Double, height: Double) {
        self.origin = IslandPoint(x: x, y: y)
        self.size = IslandSize(width: width, height: height)
    }
    public var minX: Double { origin.x }
    public var minY: Double { origin.y }
    public var maxX: Double { origin.x + size.width }
    public var maxY: Double { origin.y + size.height }
    public var midX: Double { origin.x + size.width / 2 }
    public var midY: Double { origin.y + size.height / 2 }
}

/// Measurements must come from the runtime adapter for the actual device.
/// The core deliberately does not guess iPhone 12 notch or status-bar dimensions.
public struct IslandLayoutEnvironment: Codable, Equatable, Sendable {
    public var screen: IslandSize
    public var nativeSafeArea: IslandInsets
    public var sensorAnchor: IslandRect
    public var displayScale: Double
    public var contentSpacing: Double
    public var statusBarSideClearance: Double

    public init(
        screen: IslandSize,
        nativeSafeArea: IslandInsets,
        sensorAnchor: IslandRect,
        displayScale: Double = 1,
        contentSpacing: Double = 8,
        statusBarSideClearance: Double = 6
    ) {
    self.screen = screen
    self.nativeSafeArea = nativeSafeArea
    self.sensorAnchor = sensorAnchor
    self.displayScale = max(0.1, displayScale)
    self.contentSpacing = max(0, contentSpacing)
    self.statusBarSideClearance = max(0, statusBarSideClearance)
    }
}
