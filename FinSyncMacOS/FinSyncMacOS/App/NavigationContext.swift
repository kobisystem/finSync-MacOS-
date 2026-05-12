import Foundation

public struct NavigationContext: Equatable, Sendable {
    public var selectedMonth: Date
    public var returnDestination: Destination

    public enum Destination: String, Equatable, Sendable {
        case dashboard
        case imports
        case transactions
    }

    public init(selectedMonth: Date = Date(), returnDestination: Destination = .dashboard) {
        self.selectedMonth = selectedMonth
        self.returnDestination = returnDestination
    }
}

