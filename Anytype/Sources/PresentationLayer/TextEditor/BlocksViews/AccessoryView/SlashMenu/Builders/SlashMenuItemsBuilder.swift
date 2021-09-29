import BlocksModels

struct SlashMenuItemsBuilder {
    
    private let restrictions: BlockRestrictions
    
    init(blockType: BlockContentType) {
        restrictions = BlockRestrictionsFactory().makeRestrictions(for: blockType)
    }
    
    var slashMenuItems: [SlashMenuItem] {
        return [
            styleMenuItem,
            mediaMenuItem,
            objectsMenuItem,
            relationMenuItem,
            otherMenuItem,
            actionsMenuItem,
            alignmentMenuItem,
            blockColorMenuItem,
            backgroundColorMenuItem
        ].compactMap { $0 }
    }
    
    private var styleMenuItem: SlashMenuItem? {
        let children = SlashActionStyle.allCases.reduce(into: [SlashAction]()) { result, type in
            if let mappedType = type.blockViewsType {
                guard restrictions.turnIntoStyles.contains(mappedType) else { return }
                result.append(.style(type))
            } else {
                if type == .bold, restrictions.canApplyBold {
                    result.append(.style(type))
                }
                if type == .italic, restrictions.canApplyItalic {
                    result.append(.style(type))
                }
                if (type == .code || type == .strikethrough), restrictions.canApplyOtherMarkup {
                    result.append(.style(type))
                }
            }
        }
        if children.isEmpty {
            return nil
        }
        return SlashMenuItem(item: .style, children: children)
    }
    
    private var mediaMenuItem: SlashMenuItem? {
        let children: [SlashAction] = SlashActionMedia.allCases.map { .media($0) }
        return SlashMenuItem(item: .media, children: children)
    }
    
    private var objectsMenuItem: SlashMenuItem? {
        guard let draft = ObjectTypeProvider.objectType(url: ObjectTypeProvider.pageObjectURL) else {
            return nil
        }
        
        let objects = [ draft ]
        return SlashMenuItem(item: .objects, children: objects.map { .objects($0) })
    }
    
    private var relationMenuItem: SlashMenuItem? {
        nil
    }
    
    private var otherMenuItem: SlashMenuItem {
        let children: [SlashAction] = SlashActionOther.allCases.map { .other($0) }
        return SlashMenuItem(item: .other, children: children)
    }
    
    private var actionsMenuItem: SlashMenuItem {
        let children: [SlashAction] = BlockAction.allCases.map { .actions($0) }
        return SlashMenuItem(item: .actions, children: children)
    }
    
    private var alignmentMenuItem: SlashMenuItem? {
        let children = SlashActionAlignment.allCases.reduce(into: [SlashAction]()) { result, alignment in
            guard self.restrictions.availableAlignments.contains(alignment.blockAlignment) else { return }
            result.append(.alignment(alignment))
        }
        if children.isEmpty {
            return nil
        }
        return SlashMenuItem(item: .alignment, children: children)
    }
    
    private var blockColorMenuItem: SlashMenuItem? {
        if !restrictions.canApplyBlockColor {
            return nil
        }
        return SlashMenuItem(item: .color, children: BlockColor.allCases.map { .color($0) })
    }
    
    private var backgroundColorMenuItem: SlashMenuItem? {
        if !restrictions.canApplyBackgroundColor {
            return nil
        }
        return SlashMenuItem(item: .background, children: BlockBackgroundColor.allCases.map { .background($0) })
    }
}