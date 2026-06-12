import SwiftUI
import MahjongCore
import MahjongOCR

struct PanelContentView: View {
    @Bindable var state: AppState
    let onToggleExpanded: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            // Status icon (top-right)
            HStack {
                Spacer()
                statusIcon
            }
            .frame(height: 12)

            // Top line: recommendation
            if let rec = state.lastRecommendation {
                recommendationLine(rec)
            } else {
                Text(state.mode == .paused ? "已暂停" : "未检测到推荐")
                    .font(.system(size: 14, weight: .medium))
            }

            // Bottom line: status
            statusLine

            // Edit button (only in expanded)
            if state.mode == .expanded {
                Button("修正") {
                    state.mode = .editing
                }
            }
        }
        .padding(8)
        .frame(minWidth: 280, minHeight: 80)
        .onTapGesture {
            onToggleExpanded()
        }
    }

    @ViewBuilder
    private func recommendationLine(_ rec: Recommendation) -> some View {
        switch rec {
        case .discard(let tile, _, let shanten, let ukeIra):
            HStack(spacing: 8) {
                Text("推荐：打 \(tileCode(tile))")
                    .font(.system(size: 14, weight: .semibold))
                Text("·")
                Text("向听 \(shanten)")
                Text("·")
                Text("\(ukeIra.reduce(0) { $0 + $1.count }) 种听牌")
            }
        case .riichi(let discardTile, let ukeIra):
            HStack(spacing: 8) {
                Image(systemName: "circle.fill")
                    .foregroundStyle(.yellow)
                Text("立直：打 \(tileCode(discardTile)) · \(ukeIra.reduce(0) { $0 + $1.count }) 种")
            }
        }
    }

    private var statusLine: some View {
        HStack {
            if let result = state.ocrResult {
                Text("置信度: \(Int(result.confidence.hand * 100))%")
            }
            Spacer()
        }
        .font(.system(size: 11))
        .foregroundStyle(.secondary)
    }

    @ViewBuilder
    private var statusIcon: some View {
        if let result = state.ocrResult {
            if result.confidence.hand >= 0.7 && result.confidence.dora >= 0.7 {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundStyle(.green)
            } else if result.confidence.hand >= 0.5 {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundStyle(.yellow)
            } else {
                Image(systemName: "xmark.circle.fill")
                    .foregroundStyle(.red)
            }
        }
    }

    private func tileCode(_ tile: Tile) -> String {
        if let honor = tile.honor {
            switch honor {
            case .wind(let w):
                switch w {
                case .east: return "東"
                case .south: return "南"
                case .west: return "西"
                case .north: return "北"
                }
            case .white: return "白"
            case .green: return "發"
            case .red: return "中"
            }
        }
        let suitChar: String
        switch tile.suit {
        case .m: suitChar = "m"
        case .p: suitChar = "p"
        case .s: suitChar = "s"
        case .z: suitChar = "z"
        }
        return "\(tile.rank)\(suitChar)"
    }
}
