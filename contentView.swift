//
//  ContentView.swift
//  windows
//
//  Created by Derek Wood on 7/23/25.
//

import SwiftUI

/// Primary settings view used by ``SettingsWindowController``.
/// This SwiftUI implementation mirrors the previous AppKit based
/// interface so the settings can also be displayed in SwiftUI
/// previews or embedded in a hosting window.
struct ContentView: View {
    /// Shared settings model used across the application.
    @ObservedObject private var settings = Settings.shared

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Toggle("Enable Window Previews", isOn: $settings.enabled)

            VStack(alignment: .leading) {
                Text("Animation Speed:")
                Slider(value: $settings.animationSpeed, in: 0.1...1.0)
            }

            Picker("Preview Size:", selection: $settings.previewSize) {
                ForEach(Settings.PreviewSize.allCases, id: \.self) { size in
                    Text(size.rawValue).tag(size)
                }
            }

            Spacer()
        }
        .padding(20)
        .frame(width: 300)
    }
}

#if DEBUG
struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
#endif
