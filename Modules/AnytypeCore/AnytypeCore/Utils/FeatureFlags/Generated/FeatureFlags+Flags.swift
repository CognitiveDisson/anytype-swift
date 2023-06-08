// Generated using Sourcery 1.9.2 — https://github.com/krzysztofzablocki/Sourcery
// DO NOT EDIT

// swiftlint:disable file_length

public extension FeatureFlags {

    // Static value reader
    static var setKanbanView: Bool {
        value(for: .setKanbanView)
    }

    static var fullInlineSetImpl: Bool {
        value(for: .fullInlineSetImpl)
    }

    static var dndOnCollectionsAndSets: Bool {
        value(for: .dndOnCollectionsAndSets)
    }

    static var migrationGuide: Bool {
        value(for: .migrationGuide)
    }

    static var fileStorage: Bool {
        value(for: .fileStorage)
    }

    static var newAuthorization: Bool {
        value(for: .newAuthorization)
    }

    static var redesignAbout: Bool {
        value(for: .redesignAbout)
    }

    static var sortIncludeTime: Bool {
        value(for: .sortIncludeTime)
    }

    static var binConfirmAlert: Bool {
        value(for: .binConfirmAlert)
    }

    static var rainbowViews: Bool {
        value(for: .rainbowViews)
    }

    static var showAlertOnAssert: Bool {
        value(for: .showAlertOnAssert)
    }

    static var analytics: Bool {
        value(for: .analytics)
    }

    static var analyticsAlerts: Bool {
        value(for: .analyticsAlerts)
    }

    // All toggles
    static let features: [FeatureDescription] = [
        .setKanbanView,
        .fullInlineSetImpl,
        .dndOnCollectionsAndSets,
        .migrationGuide,
        .fileStorage,
        .newAuthorization,
        .redesignAbout,
        .sortIncludeTime,
        .binConfirmAlert,
        .rainbowViews,
        .showAlertOnAssert,
        .analytics,
        .analyticsAlerts
    ]
}
