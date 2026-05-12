import SwiftUI

public struct CategoriesView: View {
    public let categories: [Category]

    public init(categories: [Category]) {
        self.categories = categories
    }

    public var body: some View {
        List(categories.filter(\.isActive)) { category in
            Text(category.name)
        }
        .overlay {
            if categories.isEmpty { EmptyStateView(message: "Nenhuma categoria ativa encontrada.") }
        }
    }
}

