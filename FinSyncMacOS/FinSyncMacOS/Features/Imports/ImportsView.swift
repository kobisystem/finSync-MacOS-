import SwiftUI

public struct ImportsView: View {
    public let imports: [ImportPresentation]

    public init(imports: [ImportPresentation]) {
        self.imports = imports
    }

    public var body: some View {
        List(imports) { item in
            VStack(alignment: .leading) {
                Text(item.fileName)
                Text(item.status.rawValue)
                    .foregroundStyle(.secondary)
                if let reason = item.actionableReason {
                    Text(reason)
                        .font(.caption)
                }
            }
        }
        .overlay {
            if imports.isEmpty { EmptyStateView(message: "Nenhuma importacao encontrada.") }
        }
    }
}

