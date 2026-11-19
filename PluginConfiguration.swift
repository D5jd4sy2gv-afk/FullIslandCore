import Foundation

public struct FullIslandConfiguration: Codable, Equatable, Sendable {
    public var enabled: Bool
    public var displayMode: IslandDisplayMode
    public var animationDuration: Double
    /// True means this plugin must not overwrite the original configuration domain.
    public var preserveOriginalConfiguration: Bool
    public var schemaVersion: Int

    public init(
        enabled: Bool = false,
        displayMode: IslandDisplayMode = .fullIsland,
        animationDuration: Double = 0.34,
        preserveOriginalConfiguration: Bool = true,
        schemaVersion: Int = 1
    ) {
        self.enabled = enabled
        self.displayMode = displayMode
        self.animationDuration = min(1.2, max(0.08, animationDuration))
        self.preserveOriginalConfiguration = preserveOriginalConfiguration
        self.schemaVersion = schemaVersion
    }
}

public enum ConfigurationStoreError: Error, Equatable {
    case cannotCreateDirectory
    case cannotEncode
    case cannotWrite
}

/// Stores only this plugin's preferences. It intentionally has no API for
/// writing MobileGestalt, SpringBoard preferences, or system display plists.
public struct FullIslandConfigurationStore: Sendable {
    public let fileURL: URL
    public init(fileURL: URL) { self.fileURL = fileURL }

    public func load() throws -> FullIslandConfiguration {
        guard FileManager.default.fileExists(atPath: fileURL.path) else {
            return FullIslandConfiguration()
        }
        let data = try Data(contentsOf: fileURL)
        return try JSONDecoder().decode(FullIslandConfiguration.self, from: data)
    }

    public func save(_ configuration: FullIslandConfiguration) throws {
        let directory = fileURL.deletingLastPathComponent()
        do {
            try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        } catch {
            throw ConfigurationStoreError.cannotCreateDirectory
        }
        let data: Data
        do {
            let encoder = JSONEncoder()
            encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
            data = try encoder.encode(configuration)
        } catch {
            throw ConfigurationStoreError.cannotEncode
        }
        do {
            try data.write(to: fileURL, options: .atomic)
        } catch {
            throw ConfigurationStoreError.cannotWrite
        }
    }
}
