import Foundation

public enum IslandPhase: String, Codable, Sendable {
    case compact
    case expanded
}

public struct IslandTransitionTicket: Equatable, Sendable {
    fileprivate let generation: UInt64
    public let fromProgress: Double
    public let toProgress: Double
    public let duration: Double
    public let targetPhase: IslandPhase
}

/// Single source of transition timing. The returned eased progress is consumed
/// unchanged by all geometry outputs (capsule, status-bar exclusion, safe area).
public struct IslandTransitionCoordinator: Sendable {
    public private(set) var phase: IslandPhase = .compact
    public private(set) var progress: Double = 0
    private var generation: UInt64 = 0

    public init() {}

    public mutating func beginTransition(
        to target: IslandPhase,
        duration: Double = 0.34
    ) -> IslandTransitionTicket {
        generation &+= 1
        let targetValue = target == .expanded ? 1.0 : 0.0
        return IslandTransitionTicket(
            generation: generation,
            fromProgress: progress,
            toProgress: targetValue,
            duration: max(0.01, duration.isFinite ? duration : 0.34),
            targetPhase: target
        )
    }

    /// Returns current shared progress. A superseded ticket is ignored.
    @discardableResult
    public mutating func sample(
        ticket: IslandTransitionTicket,
        elapsed: Double
    ) -> Double {
        guard ticket.generation == generation else { return progress }
        let safeElapsed = elapsed.isFinite ? max(0, elapsed) : 0
        let linear = min(1, max(0, safeElapsed / ticket.duration))
        let eased = linear * linear * (3 - 2 * linear)
        progress = ticket.fromProgress + (ticket.toProgress - ticket.fromProgress) * eased
        if linear >= 1 { phase = ticket.targetPhase }
        return progress
    }
}
