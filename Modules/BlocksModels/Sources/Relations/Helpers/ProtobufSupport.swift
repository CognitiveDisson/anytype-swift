import Foundation
import SwiftProtobuf
import AnytypeCore

public protocol ProtobufSupport {
    init?(_ value: Google_Protobuf_Value)
}

extension String: ProtobufSupport {
    public init?(_ value: Google_Protobuf_Value) {
        self = value.stringValue
    }
}

extension Int: ProtobufSupport {
     public init?(_ value: Google_Protobuf_Value) {
        guard let intValue = value.safeIntValue else { return nil }
        self = intValue
    }
}

extension Bool: ProtobufSupport {
    public init?(_ value: Google_Protobuf_Value) {
        self = value.boolValue
    }
}

extension URL: ProtobufSupport {
    public init?(_ value: Google_Protobuf_Value) {
        guard let url = URL(string: value.stringValue) else { return nil }
        self = url
    }
}

extension Date: ProtobufSupport {
    public init?(_ value: Google_Protobuf_Value) {
        guard let timeInterval = value.safeDoubleValue, !timeInterval.isZero else { return nil }
        self = Date(timeIntervalSince1970: timeInterval)
    }
}

extension Emoji: ProtobufSupport {
    public init?(_ value: Google_Protobuf_Value) {
        guard let emoji = Emoji(value.stringValue) else { return nil }
        self = emoji
    }
}

extension Hash: ProtobufSupport {
    public init?(_ value: Google_Protobuf_Value) {
        guard let hash = Hash(value.unwrapedListValue.stringValue) else { return nil }
        self = hash
    }
}
