import SwiftUI

public struct KPIsView: View {
    public let kpis: [MonthlyKPI]

    public init(kpis: [MonthlyKPI]) {
        self.kpis = kpis
    }

    public var body: some View {
        List(kpis) { kpi in
            VStack(alignment: .leading) {
                Text(kpi.month.formatted(date: .abbreviated, time: .omitted))
                Text("Moedas: \(kpi.netResult.currencies.map(\.rawValue).joined(separator: ", "))")
                    .foregroundStyle(.secondary)
            }
        }
        .overlay {
            if kpis.isEmpty { EmptyStateView(message: "Nenhum KPI mensal encontrado.") }
        }
    }
}
