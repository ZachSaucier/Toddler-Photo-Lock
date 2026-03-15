enum OrderedUniqueMerger {
    static func merge<Item, Identifier: Hashable>(
        existing: [Item],
        incoming: [Item],
        identifier: (Item) -> Identifier
    ) -> [Item] {
        var merged = existing
        var existingIndexesByIdentifier: [Identifier: Int] = [:]

        for (index, item) in merged.enumerated() {
            existingIndexesByIdentifier[identifier(item)] = index
        }

        for item in incoming {
            let itemIdentifier = identifier(item)
            if let existingIndex = existingIndexesByIdentifier[itemIdentifier] {
                merged[existingIndex] = item
            } else {
                existingIndexesByIdentifier[itemIdentifier] = merged.count
                merged.append(item)
            }
        }

        return merged
    }
}