
import SwiftUI

struct SettingsView: View {
    @State private var animationSpeed = 0.5
    @State private var previewResolution = 1.0
    @State private var filteredApps = "java"
    @State private var accessibilityGranted = false
    @State private var screenRecordingGranted = false

    private func refreshPermissions() {
        let status = PermissionsManager.permissionsStatus()
        accessibilityGranted = status["Accessibility"] ?? false
        screenRecordingGranted = status["Screen Recording"] ?? false
    }

    var body: some View {
        Form {
            Section(header: Text("Permissions")) {
                HStack {
                    Text(accessibilityGranted ? "Accessibility: Granted" : "Accessibility: Not Granted")
                        .foregroundColor(accessibilityGranted ? .green : .red)
                    Spacer()
                    Button("Grant") {
                        PermissionsManager.requestAccessibilityPermission()
                        refreshPermissions()
                    }
                }
                HStack {
                    Text(screenRecordingGranted ? "Screen Recording: Granted" : "Screen Recording: Not Granted")
                        .foregroundColor(screenRecordingGranted ? .green : .red)
                    Spacer()
                    Button("Grant") {
                        PermissionsManager.requestScreenRecordingPermission()
                        refreshPermissions()
                    }
                }
                Button("Refresh") {
                    refreshPermissions()
                }
            }
            Section(header: Text("General")) {
                Slider(value: $animationSpeed, in: 0.1...2.0) {
                    Text("Animation Speed")
                }
                Slider(value: $previewResolution, in: 0.5...2.0) {
                    Text("Preview Resolution")
                }
            }
            Section(header: Text("Filters")) {
                TextField("Filtered Apps (comma-separated)", text: $filteredApps)
            }
        }
        .padding()
        .onAppear {
            refreshPermissions()
        }
    }
}
