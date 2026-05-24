import SwiftUI

public struct AuditView: View {
    public let events: [AuditPresentation]

    public init(events: [AuditPresentation]) {
        self.events = events
    }

    public var body: some View {
        List(events) { event in
            VStack(alignment: .leading) {
                Text(event.eventType)
                Text("\(event.actor.rawValue) - \(event.entityType)")
                    .foregroundStyle(.secondary)
            }
        }
        .overlay {
            if events.isEmpty { EmptyStateView(message: "Nenhum evento de auditoria encontrado.") }
        }
    }
}

