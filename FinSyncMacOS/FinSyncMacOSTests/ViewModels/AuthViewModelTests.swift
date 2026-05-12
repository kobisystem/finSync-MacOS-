import XCTest
@testable import FinSyncCore

final class AuthViewModelTests: XCTestCase {
    @MainActor
    func testSignInAuthenticatesOwner() async {
        let auth = SupabaseAuthRepository(store: KeychainSessionStore())
        let owners = SupabaseAccountOwnerRepository(owners: [TestData.owner()])
        let viewModel = AuthViewModel(authRepository: auth, accountOwnerRepository: owners)

        await viewModel.signIn(email: "owner@example.com", password: "secret")

        if case .authenticated(let owner) = viewModel.state {
            XCTAssertEqual(owner.id, "owner-1")
        } else {
            XCTFail("Expected authenticated state")
        }
    }
}

