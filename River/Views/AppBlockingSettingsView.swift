import SwiftUI
import FamilyControls

struct AppBlockingSettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var authService = AppBlockingAuthorizationService.shared
    @State private var blockingService = AppBlockingService.shared
    @State private var isPickerPresented = false
    @State private var showingTestSheet = false
    @State private var errorMessage: String?

    var body: some View {
        NavigationStack {
            List {
                if !authService.isAuthorized {
                    authorizationSection
                } else {
                    appSelectionSection
                    if blockingService.hasSelectedApps {
                        testSection
                    }
                }
            }
            .navigationTitle("App Blocking")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
            .familyActivityPicker(
                isPresented: $isPickerPresented,
                selection: $blockingService.selectedApps
            )
            .alert("Authorization Error", isPresented: .constant(errorMessage != nil)) {
                Button("OK") {
                    errorMessage = nil
                }
            } message: {
                if let errorMessage {
                    Text(errorMessage)
                }
            }
        }
    }

    private var authorizationSection: some View {
        Section {
            VStack(spacing: 16) {
                Image(systemName: "hand.raised.circle.fill")
                    .font(.system(size: 60))
                    .foregroundStyle(.blue)
                    .padding(.top)

                Text("Screen Time Permission Required")
                    .font(.headline)

                Text("To block distracting apps during focus sessions, River needs access to Screen Time.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)

                Button("Request Permission") {
                    Task {
                        do {
                            try await authService.requestAuthorization()
                        } catch {
                            errorMessage = "Failed to request authorization: \(error.localizedDescription)"
                        }
                    }
                }
                .buttonStyle(.borderedProminent)
                .padding(.bottom)
            }
            .frame(maxWidth: .infinity)
        }
    }

    private var appSelectionSection: some View {
        Section {
            Button {
                isPickerPresented = true
            } label: {
                HStack {
                    Label("Select Apps to Block", systemImage: "app.badge.checkmark")
                    Spacer()
                    if blockingService.selectedAppsCount > 0 {
                        Text("\(blockingService.selectedAppsCount) selected")
                            .foregroundStyle(.secondary)
                    }
                }
            }

            if blockingService.hasSelectedApps {
                Button(role: .destructive) {
                    blockingService.selectedApps = FamilyActivitySelection()
                } label: {
                    Label("Clear Selection", systemImage: "trash")
                }
            }
        } header: {
            Text("App Selection")
        } footer: {
            Text("Selected apps will be blocked when a focus timer is running. You can select up to 50 apps or use categories for broader blocking.")
        }
    }

    private var testSection: some View {
        Section {
            Button {
                blockingService.enableBlocking()
                showingTestSheet = true
            } label: {
                Label("Test Blocking", systemImage: "testtube.2")
            }

            if showingTestSheet {
                Button {
                    blockingService.disableBlocking()
                    showingTestSheet = false
                } label: {
                    Label("Stop Test", systemImage: "stop.circle")
                        .foregroundStyle(.red)
                }
            }
        } header: {
            Text("Testing")
        } footer: {
            Text("Test your app blocking configuration. Try opening a blocked app after enabling the test.")
        }
    }
}

#Preview {
    AppBlockingSettingsView()
}
