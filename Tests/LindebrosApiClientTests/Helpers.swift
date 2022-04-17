@testable import LindebrosApiClient

class CredentialsProviderSpy: CredentialsProvider {
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
