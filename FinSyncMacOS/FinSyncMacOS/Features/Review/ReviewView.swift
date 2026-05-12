import SwiftUI

public struct ReviewView: View {
    public let items: [ReviewItem]
    public let onClose: () -> Void

    public init(items: [ReviewItem], onClose: @escaping () -> Void = {}) {
        self.items = items
        self.onClose = onClose
    }

    public var body: some View {
        VStack(alignment: .leading) {
            HStack {
                Text("Revisao")
                    .font(.title2)
                Spacer()
                Button("Voltar", action: onClose)
            }
            if items.isEmpty {
                EmptyStateView(message: "Nenhuma classificacao pendente.")
            } else {
                List(items) { item in
                    VStack(alignment: .leading) {
                        Text(item.transaction.descriptionNormalized)
                        Text(item.suggestedCategory?.name ?? "Sem categoria")
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
        .padding()
        .accessibilityIdentifier(Accessibility.reviewView)
    }
}

