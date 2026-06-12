import SwiftUI
import MahjongOCR

struct RecalibrateFlow: View {
    @State private var step: Int = 0
    let onComplete: (LayoutTemplate) -> Void

    var body: some View {
        VStack {
            Text("校准窗口布局 - 步骤 \(step + 1) / 5")
                .font(.headline)
            Text("请点击：手牌左上角")
                .padding()
            Button("下一项") {
                step += 1
                if step >= 5 {
                    // TODO: collect clicks and build LayoutTemplate
                    onComplete(LayoutTemplate(
                        handRect: .zero, meldRect: .zero,
                        discardRects: Array(repeating: .zero, count: 4),
                        doraRect: .zero
                    ))
                }
            }
        }
        .padding()
        .frame(width: 400, height: 200)
    }
}
