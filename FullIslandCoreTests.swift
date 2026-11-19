import XCTest
@testable import FullIslandCore


private final class AdapterCallLog: @unchecked Sendable {
    private let lock = NSLock()
    private var storage: [String] = []
    func append(_ value: String) {
        lock.lock(); defer { lock.unlock() }
        storage.append(value)
    }
    func values() -> [String] {
        lock.lock(); defer { lock.unlock() }
        return storage
    }
}

private struct TestApertureAdapter: SystemApertureHostAdapter {
    let log: AdapterCallLog
    func measureEnvironment() throws -> IslandLayoutEnvironment {
        IslandLayoutEnvironment(
            screen: IslandSize(width: 390, height: 844),
            nativeSafeArea: IslandInsets(top: 47),
            sensorAnchor: IslandRect(x: 90, y: 8, width: 210, height: 34),
            displayScale: 3
        )
    }
    func publishCapsule(_ snapshot: IslandLayoutSnapshot) throws {
        log.append("aperture.publish")
    }
    func restoreCapsule() throws { log.append("aperture.restore") }
}

private struct TestStatusAdapter: SystemStatusRegionHostAdapter {
    let log: AdapterCallLog
    let shouldFail: Bool
    func publishExclusion(_ frame: IslandRect?, progress: Double) throws {
        log.append("status.publish")
        if shouldFail { throw SystemBridgeError.adapterPublishFailed }
    }
    func restoreStatusBarRegion() throws { log.append("status.restore") }
}

final class FullIslandCoreTests: XCTestCase {
    private var environment: IslandLayoutEnvironment {
        IslandLayoutEnvironment(
            screen: IslandSize(width: 390, height: 844),
            nativeSafeArea: IslandInsets(top: 47, left: 0, bottom: 34, right: 0),
            sensorAnchor: IslandRect(x: 90, y: 8, width: 210, height: 34),
            displayScale: 3,
            contentSpacing: 8,
            statusBarSideClearance: 6
        )
    }

    private var style: IslandStyle {
        IslandStyle(
            compactSize: IslandSize(width: 126, height: 34),
            expandedSize: IslandSize(width: 250, height: 112),
            compactCornerRadius: 17,
            expandedCornerRadius: 28
        )
    }

    func testExpandedLayoutUsesSharedProgressAndAddsContentInset() {
        let result = IslandLayoutCoordinator().calculate(
            progress: 1,
            mode: .fullIsland,
            environment: environment,
            style: style
        )
        XCTAssertEqual(result.capsuleFrame?.size.width, 250)
        XCTAssertEqual(result.capsuleFrame?.size.height, 112)
        XCTAssertGreaterThan(result.contentSafeArea.top, environment.nativeSafeArea.top)
        XCTAssertEqual(result.statusBarExclusionFrame?.size.width, 262)
        XCTAssertEqual(result.opacity, 1)
    }

    func testCompactLayoutKeepsNativeTopSafeAreaWhenAlreadyLargeEnough() {
        let result = IslandLayoutCoordinator().calculate(
            progress: 0,
            mode: .fullIsland,
            environment: environment,
            style: style
        )
        XCTAssertEqual(result.capsuleFrame?.size.width, 126)
        XCTAssertEqual(result.contentSafeArea.top, 50)
    }

    func testOriginalModeReturnsUnmodifiedSafeAreaAndNoCapsule() {
        let result = IslandLayoutCoordinator().calculate(
            progress: 1,
            mode: .original,
            environment: environment,
            style: style
        )
        XCTAssertNil(result.capsuleFrame)
        XCTAssertNil(result.statusBarExclusionFrame)
        XCTAssertEqual(result.contentSafeArea, environment.nativeSafeArea)
        XCTAssertEqual(result.opacity, 0)
    }

    func testTransitionCoordinatorIgnoresSupersededAnimationTicket() {
        var coordinator = IslandTransitionCoordinator()
        let first = coordinator.beginTransition(to: .expanded)
        _ = coordinator.beginTransition(to: .compact)
        let ignored = coordinator.sample(ticket: first, elapsed: first.duration)
        XCTAssertEqual(ignored, 0)
    }

    func testTransitionCompletesAtSharedEndpoint() {
        var coordinator = IslandTransitionCoordinator()
        let ticket = coordinator.beginTransition(to: .expanded, duration: 0.4)
        let value = coordinator.sample(ticket: ticket, elapsed: 0.4)
        XCTAssertEqual(value, 1)
        XCTAssertEqual(coordinator.phase, .expanded)
    }

    func testIntermediateProgressIsConsumedWithoutSecondEasingCurve() {
        let result = IslandLayoutCoordinator().calculate(
            progress: 0.5,
            mode: .fullIsland,
            environment: environment,
            style: style
        )
        // The transition coordinator owns easing; layout interpolates linearly.
        XCTAssertEqual(result.capsuleFrame?.size.width, 188)
        XCTAssertEqual(result.capsuleFrame?.size.height, 73)
        XCTAssertEqual(result.normalizedProgress, 0.5)
    }

    func testHugeCapsuleProfileIsClampedInsideScreenBounds() {
        let smallEnvironment = IslandLayoutEnvironment(
            screen: IslandSize(width: 320, height: 600),
            nativeSafeArea: IslandInsets(top: 45, bottom: 20),
            sensorAnchor: IslandRect(x: 145, y: -8, width: 30, height: 30),
            displayScale: 2
        )
        let hugeStyle = IslandStyle(
            compactSize: IslandSize(width: 200, height: 100),
            expandedSize: IslandSize(width: 900, height: 900),
            compactCornerRadius: 100,
            expandedCornerRadius: 500
        )
        let result = IslandLayoutCoordinator().calculate(
            progress: 1,
            mode: .fullIsland,
            environment: smallEnvironment,
            style: hugeStyle
        )
        let capsule = try! XCTUnwrap(result.capsuleFrame)
        let exclusion = try! XCTUnwrap(result.statusBarExclusionFrame)
        XCTAssertGreaterThanOrEqual(capsule.minX, 0)
        XCTAssertGreaterThanOrEqual(capsule.minY, 0)
        XCTAssertLessThanOrEqual(capsule.maxX, 320)
        XCTAssertLessThanOrEqual(capsule.maxY, 600)
        XCTAssertGreaterThanOrEqual(exclusion.minX, 0)
        XCTAssertGreaterThanOrEqual(exclusion.minY, 0)
        XCTAssertLessThanOrEqual(exclusion.maxX, 320)
        XCTAssertLessThanOrEqual(exclusion.maxY, 600)
        XCTAssertLessThanOrEqual(result.cornerRadius, min(capsule.size.width, capsule.size.height) / 2)
    }

    func testGeometryIsSnappedToDisplayPixels() {
        let result = IslandLayoutCoordinator().calculate(
            progress: 0.37,
            mode: .fullIsland,
            environment: environment,
            style: style
        )
        let capsule = try! XCTUnwrap(result.capsuleFrame)
        for value in [capsule.minX, capsule.minY, capsule.size.width, capsule.size.height,
                      result.cornerRadius, result.contentSafeArea.top] {
            XCTAssertEqual(value * environment.displayScale,
                           (value * environment.displayScale).rounded(), accuracy: 0.000001)
        }
    }

    func testNonFiniteProgressUsesCompactGeometry() {
        let result = IslandLayoutCoordinator().calculate(
            progress: .nan,
            mode: .fullIsland,
            environment: environment,
            style: style
        )
        XCTAssertEqual(result.normalizedProgress, 0)
        XCTAssertEqual(result.capsuleFrame?.size.width, 126)
    }

    func testResearchCatalogKeepsPrivateSymbolsMarkedAsUnverifiedABI() {
        XCTAssertTrue(IOS27RuntimeResearchCatalog.candidateBoundaries.contains {
            $0.framework == "SystemApertureUI" && $0.symbol == "SAUILayoutContext"
        })
        XCTAssertTrue(IOS27RuntimeResearchCatalog.candidateBoundaries.allSatisfy {
            $0.verification == .presentInRuntimeHeaderIndex
        })
    }

    func testBridgeRollsBackBothSidesWhenStatusBarPublishFails() {
        let log = AdapterCallLog()
        let bridge = CoordinatedSpringBoardBridge(
            aperture: TestApertureAdapter(log: log),
            status: TestStatusAdapter(log: log, shouldFail: true)
        )
        let snapshot = IslandLayoutCoordinator().calculate(
            progress: 1,
            mode: .fullIsland,
            environment: environment,
            style: style
        )
        XCTAssertThrowsError(try bridge.publish(snapshot))
        XCTAssertEqual(log.values(), [
            "aperture.publish", "status.publish", "status.restore", "aperture.restore"
        ])
    }

    func testConfigurationStoreIsNamespacedAndRoundTrips() throws {
        let root = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: root) }
        let url = root.appendingPathComponent("FullIsland/plugin-config.json")
        let store = FullIslandConfigurationStore(fileURL: url)
        let expected = FullIslandConfiguration(enabled: true, animationDuration: 0.42)
        try store.save(expected)
        XCTAssertEqual(try store.load(), expected)
    }
}
