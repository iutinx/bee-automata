import Foundation
import AppKit

struct CalibrationPoint: Codable, Equatable {
    var x: CGFloat
    var y: CGFloat

    init(x: CGFloat, y: CGFloat) {
        self.x = x
        self.y = y
    }
}

struct CalibrationCircle: Codable, Equatable {
    var centerX: CGFloat
    var centerY: CGFloat
    var radius: CGFloat

    var center: NSPoint { NSPoint(x: centerX, y: centerY) }

    init(center: NSPoint, radius: CGFloat) {
        self.centerX = center.x
        self.centerY = center.y
        self.radius = radius
    }
}

struct CalibrationRect: Codable, Equatable {
    var topLeft: CalibrationPoint
    var bottomRight: CalibrationPoint

    var nsRect: NSRect {
        NSRect(
            x: topLeft.x,
            y: bottomRight.y,
            width: bottomRight.x - topLeft.x,
            height: topLeft.y - bottomRight.y
        )
    }

    init(topLeft: CalibrationPoint, bottomRight: CalibrationPoint) {
        self.topLeft = topLeft
        self.bottomRight = bottomRight
    }
}

struct CalibrationProfile: Codable, Equatable {
    var screenResolution: String
    var createdAt: Date
    var abilityROIs: [CalibrationCircle]
    var boostSearchRegion: CalibrationRect

    static let abilityCount = 2

    static var defaultProfile: CalibrationProfile {
        let screen = NSScreen.main?.frame ?? NSRect(x: 0, y: 0, width: 1920, height: 1080)
        let resolution = "\(Int(screen.width))x\(Int(screen.height))"

        let defaultRadius: CGFloat = 30
        var abilities: [CalibrationCircle] = []
        abilities.append(CalibrationCircle(center: NSPoint(x: screen.midX - 100, y: screen.midY), radius: defaultRadius))
        abilities.append(CalibrationCircle(center: NSPoint(x: screen.midX + 100, y: screen.midY), radius: defaultRadius))

        let boostRegion = CalibrationRect(
            topLeft: CalibrationPoint(x: 0, y: screen.height),
            bottomRight: CalibrationPoint(x: screen.width, y: screen.height - 100)
        )

        return CalibrationProfile(
            screenResolution: resolution,
            createdAt: Date(),
            abilityROIs: abilities,
            boostSearchRegion: boostRegion
        )
    }
}

final class ProfileManager {

    static let shared = ProfileManager()

    private let appDirectoryName = "BeeSwarmAssistant"
    private let profileFileName = "profile.json"

    private(set) var currentProfile: CalibrationProfile?

    private var profileDirectoryURL: URL {
        let appSupport = FileManager.default.urls(
            for: .applicationSupportDirectory, in: .userDomainMask
        ).first!
        return appSupport.appendingPathComponent(appDirectoryName)
    }

    private var profileFileURL: URL {
        profileDirectoryURL.appendingPathComponent(profileFileName)
    }

    private init() {}

    func loadProfile() -> CalibrationProfile {
        if let cached = currentProfile { return cached }

        ensureDirectoryExists()

        guard FileManager.default.fileExists(atPath: profileFileURL.path) else {
            let defaultProfile = CalibrationProfile.defaultProfile
            currentProfile = defaultProfile
            return defaultProfile
        }

        do {
            let data = try Data(contentsOf: profileFileURL)
            let profile = try JSONDecoder().decode(CalibrationProfile.self, from: data)
            currentProfile = profile
            return profile
        } catch {
            print("[ProfileManager] Failed to load profile, deleting old file: \(error)")
            try? FileManager.default.removeItem(at: profileFileURL)
            let defaultProfile = CalibrationProfile.defaultProfile
            currentProfile = defaultProfile
            return defaultProfile
        }
    }

    func saveProfile(_ profile: CalibrationProfile) {
        ensureDirectoryExists()

        do {
            let data = try JSONEncoder().encode(profile)
            try data.write(to: profileFileURL, options: .atomic)
            currentProfile = profile
            print("[ProfileManager] Profile saved to \(profileFileURL.path)")
        } catch {
            print("[ProfileManager] Failed to save profile: \(error)")
        }
    }

    func currentScreenResolution() -> String {
        let screen = NSScreen.main?.frame ?? NSRect(x: 0, y: 0, width: 1920, height: 1080)
        return "\(Int(screen.width))x\(Int(screen.height))"
    }

    private func ensureDirectoryExists() {
        let dir = profileDirectoryURL
        if !FileManager.default.fileExists(atPath: dir.path) {
            do {
                try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
            } catch {
                print("[ProfileManager] Failed to create directory: \(error)")
            }
        }
    }
}
