import SwiftUI

struct SettingsView: View {
    @State private var pollInterval: Double = 3
    @State private var logLevel: String = "info"

    var body: some View {
        Form {
            Section("轮询") {
                Slider(value: $pollInterval, in: 1...10, step: 1) {
                    Text("轮询间隔: \(Int(pollInterval))秒")
                }
            }
            Section("日志") {
                Picker("日志级别", selection: $logLevel) {
                    Text("Debug").tag("debug")
                    Text("Info").tag("info")
                    Text("Warn").tag("warn")
                    Text("Error").tag("error")
                }
            }
        }
        .padding()
        .frame(width: 300, height: 200)
    }
}
