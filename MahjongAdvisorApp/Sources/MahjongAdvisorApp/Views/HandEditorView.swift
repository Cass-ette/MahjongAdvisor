import SwiftUI
import MahjongCore
import MahjongOCR

struct HandEditorView: View {
    @Bindable var state: AppState
    @State private var editSession: EditSession?

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("修正模式 (按 Esc 退出)")
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(.secondary)

            if let result = state.ocrResult {
                handDisplay(result: result)
                HStack {
                    Button("Hotkey 编辑") { /* TODO: enter hotkey mode */ }
                        .disabled(true)
                    Button("点击编辑") { /* TODO: open 34-tile popover */ }
                        .disabled(true)
                    Button("AI 候选") { /* TODO: show Top-3 */ }
                        .disabled(true)
                }
            }

            HStack {
                Button("✓ 确认") { state.mode = .collapsed }
                Spacer()
            }
        }
        .padding(8)
    }

    private func handDisplay(result: OCRResult) -> some View {
        HStack(spacing: 4) {
            ForEach(Array((result.handTiles ?? []).enumerated()), id: \.offset) { _, tile in
                Text("\(tile.rank)")
                    .frame(width: 24, height: 32)
                    .background(tile.isRed ? Color.red.opacity(0.3) : Color.gray.opacity(0.2))
                    .cornerRadius(2)
            }
        }
    }
}

final class EditSession {
    var cursor: Int = 0
    var activePath: Path?

    enum Path {
        case hotkey
        case click
        case aiCandidates
    }
}
