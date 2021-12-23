import BlocksModels

extension BlockText {
    var anytypeText: UIKitAnytypeText {
        AttributedTextConverter.asModel(
            text: text,
            marks: marks,
            style: contentType
        )
    }
}
