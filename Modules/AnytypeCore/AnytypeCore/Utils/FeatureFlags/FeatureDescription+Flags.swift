import Foundation

extension FeatureDescription {
    static let rainbowViews = FeatureDescription(
        title: "Paint editor views 🌈",
        author: "debug",
        releaseVersion: "-",
        defaultValue: false
    )
    
    static let showAlertOnAssert = FeatureDescription(
        title: "Show alerts on asserts\n(only in testflight dev)",
        author: "debug",
        releaseVersion: "-",
        defaultValue: true
    )
    
    static let analytics = FeatureDescription(
        title: "Analytics Amplitude (only in development)",
        author: "debug",
        releaseVersion: "-",
        defaultValue: false
    )
    
    static let middlewareLogs = FeatureDescription(
        title: "Show middleware logs in Xcode console",
        author: "debug",
        releaseVersion: "-",
        defaultValue: false
    )
    
    static let objectPreview = FeatureDescription(
        title: "Object preview",
        author: "k@anytype.io",
        releaseVersion: "?",
        defaultValue: false
    )
    
    static let setFilters = FeatureDescription(
        title: "Set filters",
        author: "joe_pusya@anytype.io",
        releaseVersion: "0.17.0",
        defaultValue: false
    )
    
    static let relationDetails = FeatureDescription(
        title: "Relation details in read only mode",
        author: "m@anytype.io",
        releaseVersion: "0.17.0",
        defaultValue: true
    )
    
    static let bookmarksFlow = FeatureDescription(
        title: "New bookmarks flow",
        author: "m@anytype.io",
        releaseVersion: "0.17.0",
        defaultValue: false
    )
}