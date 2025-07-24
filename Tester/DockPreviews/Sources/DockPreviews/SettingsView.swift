
import SwiftUI

struct SettingsView: View {
    @State private var animationSpeed = 0.5
    @State private var previewResolution = 1.0
    @State private var filteredApps = "java"

    var body: some View {
        Form {
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
    }
}
