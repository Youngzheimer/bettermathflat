import SwiftUI
import PencilKit

struct DrawingView: UIViewRepresentable {
    @Binding var drawing: PKDrawing
    @Binding var isEraser: Bool
    @Binding var penColor: Color
    @Binding var penWidth: CGFloat
    
    func makeUIView(context: Context) -> PKCanvasView {
        let canvasView = PKCanvasView()
        canvasView.delegate = context.coordinator
        canvasView.drawing = drawing
        canvasView.tool = createTool()
        return canvasView
    }
    
    func updateUIView(_ uiView: PKCanvasView, context: Context) {
        // Update drawing if changed from parent
        if uiView.drawing != drawing {
            uiView.drawing = drawing
            context.coordinator.isUpdatingFromParent = true
        }
        
        // Update tool if parameters changed
        if context.coordinator.lastIsEraser != isEraser ||
            context.coordinator.lastPenColor != penColor ||
            context.coordinator.lastPenWidth != penWidth {
            
            uiView.tool = createTool()
            context.coordinator.lastIsEraser = isEraser
            context.coordinator.lastPenColor = penColor
            context.coordinator.lastPenWidth = penWidth
        }
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(
            drawing: $drawing,
            isEraser: isEraser,
            penColor: penColor,
            penWidth: penWidth
        )
    }
    
    private func createTool() -> PKTool {
        if isEraser {
            return PKEraserTool(.vector)
        } else {
            let inkType: PKInkingTool.InkType = .pencil
            let color = UIColor(penColor)
            return PKInkingTool(inkType, color: color, width: penWidth)
        }
    }
    
    class Coordinator: NSObject, PKCanvasViewDelegate {
        @Binding var drawing: PKDrawing
        var isUpdatingFromParent = false
        
        var lastIsEraser: Bool
        var lastPenColor: Color
        var lastPenWidth: CGFloat
        
        init(
            drawing: Binding<PKDrawing>,
            isEraser: Bool,
            penColor: Color,
            penWidth: CGFloat
        ) {
            self._drawing = drawing
            self.lastIsEraser = isEraser
            self.lastPenColor = penColor
            self.lastPenWidth = penWidth
        }
        
        func canvasViewDidChangeDrawing(_ canvasView: PKCanvasView) {
            guard !isUpdatingFromParent else {
                isUpdatingFromParent = false
                return
            }
            drawing = canvasView.drawing
        }
    }
}
