import XCTest
@testable import FinSyncCore

final class ForecastPresentationTests: XCTestCase {
    func testForecastHistoryConfidenceRules() {
        XCTAssertNil(ForecastPresentationUseCase.present(TestData.forecast(), currency: .brl, historyMonths: 2))
        XCTAssertEqual(ForecastPresentationUseCase.present(TestData.forecast(confidence: .high), currency: .brl, historyMonths: 6)?.confidence, .low)
        XCTAssertEqual(ForecastPresentationUseCase.present(TestData.forecast(confidence: .high), currency: .brl, historyMonths: 12)?.confidence, .high)
    }
}

