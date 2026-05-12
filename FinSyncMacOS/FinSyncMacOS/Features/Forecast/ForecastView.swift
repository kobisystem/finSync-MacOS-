import SwiftUI

public struct ForecastView: View {
    public let forecast: ForecastPresentation?

    public init(forecast: ForecastPresentation?) {
        self.forecast = forecast
    }

    public var body: some View {
        if let forecast {
            VStack(alignment: .leading) {
                Text("Previsao")
                    .font(.title2)
                Text("Confianca: \(forecast.confidence.rawValue)")
                Text(forecast.basisSummary)
                Text("Gerado em: \(forecast.generatedAt.formatted())")
            }
            .padding()
        } else {
            EmptyStateView(message: "Sem previsao mensal disponivel.")
        }
    }
}

