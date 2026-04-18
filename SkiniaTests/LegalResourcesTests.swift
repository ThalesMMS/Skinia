import Testing
import Foundation
@testable import Skinia

// MARK: - LegalDocument Tests

@MainActor
struct LegalDocumentTests {

    // MARK: localizedTitle

    @Test func localizedTitlesMatchExpectedDisplayTitles() {
        let cases: [(name: String, document: LegalDocument, expectedTitle: String)] = [
            ("termsOfUse", .termsOfUse, "Terms of Use"),
            ("privacyPolicy", .privacyPolicy, "Privacy Policy"),
            ("thirdPartyLicenses", .thirdPartyLicenses, "Third-Party Licenses"),
        ]

        for entry in cases {
            #expect(
                entry.document.localizedTitle == entry.expectedTitle,
                "Expected \(entry.name) to display \(entry.expectedTitle)"
            )
        }
    }

    @Test func allLocalizedTitlesAreEnglish() {
        let titles = LegalDocument.allCases.map(\.localizedTitle)
        for title in titles {
            #expect(!title.isEmpty)
            // Titles must not contain Portuguese-only characters that would indicate
            // untranslated strings (ç, ã, ê used exclusively in the old Portuguese labels).
            #expect(!title.contains("ç"))
            #expect(!title.contains("ã"))
            #expect(!title.contains("ê"))
        }
    }

    // MARK: Identifiable (id)

    @Test func idsUseStableLocaleIndependentValues() {
        let cases: [(document: LegalDocument, expectedID: String)] = [
            (.termsOfUse, "terms_of_use"),
            (.privacyPolicy, "privacy_policy"),
            (.thirdPartyLicenses, "third_party_licenses"),
        ]

        for entry in cases {
            #expect(entry.document.id == entry.expectedID)
        }
    }

    @Test func allDocumentIdsAreUnique() {
        let ids = LegalDocument.allCases.map(\.id)
        let uniqueIds = Set(ids)
        #expect(ids.count == uniqueIds.count)
    }

    // MARK: CaseIterable

    @Test func allCasesContainsThreeDocuments() {
        #expect(LegalDocument.allCases.count == 3)
    }

    @Test func allCasesContainsExpectedDocuments() {
        let cases = LegalDocument.allCases
        #expect(cases.contains(.termsOfUse))
        #expect(cases.contains(.privacyPolicy))
        #expect(cases.contains(.thirdPartyLicenses))
    }

    // MARK: url

    @Test func termsOfUseUrlMatchesLegalResources() {
        #expect(LegalDocument.termsOfUse.url == LegalResources.termsOfUseURL)
    }

    @Test func privacyPolicyUrlMatchesLegalResources() {
        #expect(LegalDocument.privacyPolicy.url == LegalResources.privacyPolicyURL)
    }

    @Test func thirdPartyLicensesUrlMatchesLegalResources() {
        #expect(LegalDocument.thirdPartyLicenses.url == LegalResources.thirdPartyLicensesURL)
    }

    @Test func allDocumentUrlsAreNonNil() {
        for document in LegalDocument.allCases {
            #expect(document.url != nil, "Expected non-nil URL for \(document)")
        }
    }

    @Test func allDocumentUrlsAreDistinct() {
        let urls = LegalDocument.allCases.compactMap(\.url)
        let uniqueUrls = Set(urls)
        #expect(urls.count == uniqueUrls.count)
    }
}

// MARK: - LegalResources Tests

struct LegalResourcesTests {

    @Test func termsOfUseUrlIsNonNil() {
        #expect(LegalResources.termsOfUseURL != nil)
    }

    @Test func privacyPolicyUrlIsNonNil() {
        #expect(LegalResources.privacyPolicyURL != nil)
    }

    @Test func thirdPartyLicensesUrlIsNonNil() {
        #expect(LegalResources.thirdPartyLicensesURL != nil)
    }

    @Test func termsOfUseUrlString() {
        #expect(LegalResources.termsOfUseURL?.absoluteString == "https://skinia.app/legal/terms")
    }

    @Test func privacyPolicyUrlString() {
        #expect(LegalResources.privacyPolicyURL?.absoluteString == "https://skinia.app/legal/privacy")
    }

    @Test func thirdPartyLicensesUrlString() {
        #expect(LegalResources.thirdPartyLicensesURL?.absoluteString == "https://skinia.app/legal/licenses")
    }

    @Test func allUrlsUseHttpsScheme() {
        let urls = [
            LegalResources.termsOfUseURL,
            LegalResources.privacyPolicyURL,
            LegalResources.thirdPartyLicensesURL,
        ].compactMap { $0 }

        for url in urls {
            #expect(url.scheme == "https", "Expected HTTPS scheme for \(url)")
        }
    }

    @Test func allUrlsHaveSkiniaAppHost() {
        let urls = [
            LegalResources.termsOfUseURL,
            LegalResources.privacyPolicyURL,
            LegalResources.thirdPartyLicensesURL,
        ].compactMap { $0 }

        for url in urls {
            #expect(url.host == "skinia.app", "Expected host 'skinia.app' for \(url)")
        }
    }

    @Test func allUrlsAreDistinct() {
        let urls = [
            LegalResources.termsOfUseURL,
            LegalResources.privacyPolicyURL,
            LegalResources.thirdPartyLicensesURL,
        ].compactMap { $0 }

        let uniqueUrls = Set(urls)
        #expect(urls.count == uniqueUrls.count)
    }
}

// MARK: - LegalDocumentOpening Protocol Tests

@MainActor
struct LegalDocumentOpeningTests {

    /// Minimal in-test spy that records which documents were opened.
    private final class SpyLegalDocumentOpener: LegalDocumentOpening {
        private(set) var openedDocuments: [LegalDocument] = []

        func open(_ document: LegalDocument) {
            openedDocuments.append(document)
        }
    }

    @Test func openRecordsTermsOfUse() {
        let spy = SpyLegalDocumentOpener()
        spy.open(.termsOfUse)
        #expect(spy.openedDocuments == [.termsOfUse])
    }

    @Test func openRecordsPrivacyPolicy() {
        let spy = SpyLegalDocumentOpener()
        spy.open(.privacyPolicy)
        #expect(spy.openedDocuments == [.privacyPolicy])
    }

    @Test func openRecordsThirdPartyLicenses() {
        let spy = SpyLegalDocumentOpener()
        spy.open(.thirdPartyLicenses)
        #expect(spy.openedDocuments == [.thirdPartyLicenses])
    }

    @Test func openPreservesOrderOfMultipleCalls() {
        let spy = SpyLegalDocumentOpener()
        spy.open(.termsOfUse)
        spy.open(.privacyPolicy)
        spy.open(.thirdPartyLicenses)
        #expect(spy.openedDocuments == [.termsOfUse, .privacyPolicy, .thirdPartyLicenses])
    }

    @Test func openCanBeCalledRepeatedly() {
        let spy = SpyLegalDocumentOpener()
        spy.open(.privacyPolicy)
        spy.open(.privacyPolicy)
        #expect(spy.openedDocuments.count == 2)
        #expect(spy.openedDocuments.allSatisfy { $0 == .privacyPolicy })
    }
}
