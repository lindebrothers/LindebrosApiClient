@testable import LindebrosApiClient

class CredentialsProviderSpy: CredentialsProvider {
    func fetchNewCredentials() async -> Client.Credentials? {
        return Client.Credentials(accessToken: "awesome")
    }

    var credentials: Client.Credentials?

    func provideCredentials() -> Client.Credentials? {
        return credentials
    }

    func setCredentials(to credentials: Client.Credentials) {
        self.credentials = credentials
    }

    func createCredentials() -> Self {
        credentials = Client.Credentials(accessToken: "awesome")
        return self
    }
}
