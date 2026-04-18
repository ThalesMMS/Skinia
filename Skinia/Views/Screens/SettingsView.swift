import SwiftUI
import MessageUI

struct SettingsView: View {
    private let legalDocumentOpener: LegalDocumentOpening

    @State private var showingFeedbackSheet = false
    @State private var showingHelpSheet = false
    @State private var showingPrivacySheet = false
    @State private var showingAboutSheet = false
    @State private var showingNotificationSettings = false
    @State private var showingImageQualitySettings = false

    init(legalDocumentOpener: LegalDocumentOpening = LegalDocumentOpener.shared) {
        self.legalDocumentOpener = legalDocumentOpener
    }
    
    var body: some View {
        NavigationView {
            List {
                // MARK: - Analysis & Quality
                Section("Analysis & Quality") {
                    SettingsRow(
                        icon: "photo.badge.checkmark",
                        iconColor: DesignSystem.Colors.primary,
                        title: "Image Quality",
                        subtitle: "Configure resolution and compression",
                        action: {
                            showingImageQualitySettings = true
                        }
                    )
                    
                    SettingsRow(
                        icon: "bell.badge",
                        iconColor: DesignSystem.Colors.secondary,
                        title: "Notifications",
                        subtitle: "Analysis results and reminders",
                        action: {
                            showingNotificationSettings = true
                        }
                    )
                }
                
                // MARK: - Privacy & Security
                Section("Privacy & Security") {
                    SettingsRow(
                        icon: "lock.shield",
                        iconColor: DesignSystem.Colors.success,
                        title: "Privacy",
                        subtitle: "Manage data and permissions",
                        action: {
                            showingPrivacySheet = true
                        }
                    )
                    
                    SettingsRow(
                        icon: "camera",
                        iconColor: DesignSystem.Colors.info,
                        title: "Camera Permissions",
                        subtitle: "Configure camera and photo access",
                        action: {
                            openAppSettings()
                        }
                    )
                }
                
                // MARK: - Support & Help
                Section("Support & Help") {
                    SettingsRow(
                        icon: "questionmark.circle",
                        iconColor: DesignSystem.Colors.warning,
                        title: "Help & Tutorials",
                        subtitle: "How to use Skinia",
                        action: {
                            showingHelpSheet = true
                        }
                    )
                    
                    SettingsRow(
                        icon: "envelope",
                        iconColor: DesignSystem.Colors.secondary,
                        title: "Send Feedback",
                        subtitle: "Suggestions and issues",
                        action: {
                            showingFeedbackSheet = true
                        }
                    )
                    
                    SettingsRow(
                        icon: "star",
                        iconColor: DesignSystem.Colors.warning,
                        title: "Rate the App",
                        subtitle: "Leave your review on the App Store",
                        action: {
                            openAppStore()
                        }
                    )
                }
                
                // MARK: - About
                Section("About") {
                    SettingsRow(
                        icon: "info.circle",
                        iconColor: DesignSystem.Colors.textSecondary,
                        title: "About Skinia",
                        subtitle: "Version 1.0.0",
                        action: {
                            showingAboutSheet = true
                        }
                    )
                    
                    SettingsRow(
                        icon: "doc.text",
                        iconColor: DesignSystem.Colors.textSecondary,
                        title: "Terms of Use",
                        subtitle: "Terms and conditions",
                        action: {
                            legalDocumentOpener.open(.termsOfUse)
                        }
                    )

                    SettingsRow(
                        icon: "hand.raised",
                        iconColor: DesignSystem.Colors.textSecondary,
                        title: "Privacy Policy",
                        subtitle: "How we protect your data",
                        action: {
                            legalDocumentOpener.open(.privacyPolicy)
                        }
                    )
                }
            }
            .listStyle(InsetGroupedListStyle())
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.large)
        }
        .sheet(isPresented: $showingHelpSheet) {
            HelpAndTutorialsView()
        }
        .sheet(isPresented: $showingFeedbackSheet) {
            FeedbackView()
        }
        .sheet(isPresented: $showingPrivacySheet) {
            PrivacySettingsView()
        }
        .sheet(isPresented: $showingAboutSheet) {
            AboutView()
        }
        .sheet(isPresented: $showingNotificationSettings) {
            NotificationSettingsView()
        }
        .sheet(isPresented: $showingImageQualitySettings) {
            ImageQualitySettingsView()
        }
    }
    
    /// Opens the app's system Settings page if the URL can be constructed and the system can open it.
    /// 
    /// If the settings URL cannot be created or cannot be opened, the function returns without side effects.
    private func openAppSettings() {
        guard let settingsUrl = URL(string: UIApplication.openSettingsURLString) else {
            return
        }
        
        if UIApplication.shared.canOpenURL(settingsUrl) {
            UIApplication.shared.open(settingsUrl)
        }
    }
    
    /// Opens the app's App Store page using the configured App Store URL.
    /// 
    /// If the stored URL is invalid the function performs no action. The current URL is a placeholder and should be replaced with the app's real App Store ID before release.
    private func openAppStore() {
        // TODO: Replace with the real app ID once published
        guard let url = URL(string: "https://apps.apple.com/app/id123456789") else { return }
        UIApplication.shared.open(url)
    }
}

// MARK: - Settings Row Component

struct SettingsRow: View {
    let icon: String
    let iconColor: Color
    let title: String
    let subtitle: String
    let action: () -> Void
    
    var body: some View {
        Button(action: {
            HapticManager.shared.selection()
            action()
        }) {
            HStack(spacing: DesignSystem.Spacing.md) {
                // Icon
                Image(systemName: icon)
                    .font(.system(size: 20, weight: .medium))
                    .foregroundColor(iconColor)
                    .frame(width: 28, height: 28)
                
                // Content
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(DesignSystem.Typography.body)
                        .foregroundColor(DesignSystem.Colors.text)
                    
                    Text(subtitle)
                        .font(DesignSystem.Typography.caption)
                        .foregroundColor(DesignSystem.Colors.textSecondary)
                }
                
                Spacer()
                
                // Arrow indicator
                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(DesignSystem.Colors.textTertiary)
            }
            .padding(.vertical, 4)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

#Preview("Settings") {
    SettingsView()
}

#if DEBUG
private struct SettingsViewPreviewContainer: View {
    @StateObject private var legalOpener = PreviewLegalDocumentOpener()

    var body: some View {
        SettingsView(legalDocumentOpener: legalOpener)
            .overlay(alignment: .bottom) {
                if let document = legalOpener.lastOpenedDocument {
                    PreviewLegalDocumentBanner(title: document.localizedTitle)
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                        .padding()
                }
            }
            .overlay(alignment: .top) {
                PreviewInstructionLabel(text: "Tap the Terms or Privacy links to validate the preview.")
            }
            .animation(.easeInOut, value: legalOpener.lastOpenedDocument)
    }
}

#Preview("Settings • Legal Actions") {
    SettingsViewPreviewContainer()
}
#endif