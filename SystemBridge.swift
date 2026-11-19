import Foundation

public enum SystemBridgeError: Error, Equatable {
    case springBoardInjectionUnavailable
    case unsupportedSystemBuild
    case environmentMeasurementUnavailable
    case adapterPublishFailed
}

/// A narrow boundary between the portable core and a separately verified
/// SpringBoard-hosted implementation. The protocol does not imply that a
/// normal IPA can access or instantiate private system frameworks.
public protocol SpringBoardSystemBridge: Sendable {
    func measureEnvironment() throws -> IslandLayoutEnvironment
    func publish(_ snapshot: IslandLayoutSnapshot) throws
    func restoreOriginalSystemLayout() throws
}

/// The aperture side is responsible for the system-owned capsule surface.
/// Implementations must be written only after its real iOS-build ABI is verified.
public protocol SystemApertureHostAdapter: Sendable {
    func measureEnvironment() throws -> IslandLayoutEnvironment
    func publishCapsule(_ snapshot: IslandLayoutSnapshot) throws
    func restoreCapsule() throws
}

/// The status-bar side coordinates exclusion/avoidance and restores the
/// platform's original status-bar region when the plugin is disabled.
public protocol SystemStatusRegionHostAdapter: Sendable {
    func publishExclusion(_ frame: IslandRect?, progress: Double) throws
    func restoreStatusBarRegion() throws
}

/// Composes the two system boundaries as one logical transaction. On any
/// publish failure, it asks both adapters to restore their pre-plugin state.
/// This still needs concrete, build-verified SpringBoard adapters to operate.
public struct CoordinatedSpringBoardBridge<
    Aperture: SystemApertureHostAdapter,
    Status: SystemStatusRegionHostAdapter
>: SpringBoardSystemBridge {
    private let aperture: Aperture
    private let status: Status

    public init(aperture: Aperture, status: Status) {
        self.aperture = aperture
        self.status = status
    }

    public func measureEnvironment() throws -> IslandLayoutEnvironment {
        try aperture.measureEnvironment()
    }

    public func publish(_ snapshot: IslandLayoutSnapshot) throws {
        do {
            try aperture.publishCapsule(snapshot)
            try status.publishExclusion(
                snapshot.statusBarExclusionFrame,
                progress: snapshot.normalizedProgress
            )
        } catch {
            try? status.restoreStatusBarRegion()
            try? aperture.restoreCapsule()
            throw error
        }
    }

    public func restoreOriginalSystemLayout() throws {
        // Restore both participants even if the first restore operation fails.
        var firstError: Error?
        do { try status.restoreStatusBarRegion() } catch { firstError = error }
        do { try aperture.restoreCapsule() } catch { if firstError == nil { firstError = error } }
        if let firstError { throw firstError }
    }
}

/// Safe app-only implementation. It never reports a successful system install.
public struct UnavailableSpringBoardBridge: SpringBoardSystemBridge {
    public init() {}
    public func measureEnvironment() throws -> IslandLayoutEnvironment {
        throw SystemBridgeError.springBoardInjectionUnavailable
    }
    public func publish(_ snapshot: IslandLayoutSnapshot) throws {
        throw SystemBridgeError.springBoardInjectionUnavailable
    }
    public func restoreOriginalSystemLayout() throws {
        throw SystemBridgeError.springBoardInjectionUnavailable
    }
}
