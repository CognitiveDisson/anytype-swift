import BlocksModels

struct HighlightedBlockRestrictions: BlockRestrictions {
    let canApplyBold = true
    let canApplyItalic = true
    let canApplyOtherMarkup = true
    let canApplyBlockColor = true
    let canApplyBackgroundColor = true
    let canApplyMention = true
    let canDeleteOrDuplicate = true
    let turnIntoStyles: [BlockContentType] = [
        .text(.text), .text(.header), .text(.header2), .text(.header3), .text(.quote), .text(.code),
        .text(.checkbox), .text(.bulleted), .text(.numbered), .text(.toggle),
        .smartblock(.page)
    ]
   
    let availableAlignments: [LayoutAlignment] = [.left, .right]
}
