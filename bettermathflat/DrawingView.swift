import PencilKit
import SwiftUI

struct DrawingView: UIViewRepresentable {
    @Binding var isUsingPen: Bool
    @Binding var drawing: PKDrawing
    var setDrawingData: ((PKDrawing) -> Void)? // 외부에서 PKDrawing 데이터를 설정하는 클로저

    func makeUIView(context: Context) -> UIScrollView {
        // UIScrollView로 감싸서 스크롤 가능하도록 함
        let scrollView = UIScrollView()
        // 두 손가락으로 스크롤을 하도록 제스처 최소/최대 터치 수 설정
        scrollView.panGestureRecognizer.minimumNumberOfTouches = 2
        scrollView.panGestureRecognizer.maximumNumberOfTouches = 2
        
        scrollView.alwaysBounceVertical = true
        scrollView.showsHorizontalScrollIndicator = false
        scrollView.showsVerticalScrollIndicator = true

        // 캔버스의 크기를 화면보다 크게 설정 (예: 세로 길이를 2배)
        let canvasSize = CGSize(width: UIScreen.main.bounds.width,
                                height: UIScreen.main.bounds.height * 2)
        let canvas = PKCanvasView(frame: CGRect(origin: .zero, size: canvasSize))
        canvas.tool = PKInkingTool(.pen, color: .black, width: 4)
        canvas.drawing = drawing // 초기 drawing 설정
        canvas.delegate = context.coordinator
        // Apple Pencil로만 그리기 (손가락 드로잉 비활성화)
        canvas.allowsFingerDrawing = false

        scrollView.addSubview(canvas)
        scrollView.contentSize = canvasSize
        
        return scrollView
    }

    func updateUIView(_ scrollView: UIScrollView, context: Context) {
        // scrollView 내부의 PKCanvasView를 업데이트
        if let canvas = scrollView.subviews.first as? PKCanvasView {
            canvas.tool = changeTool()
            if canvas.drawing != drawing {
                canvas.drawing = drawing
            }
        }
    }
    
    // 코디네이터 생성
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    // PKCanvasViewDelegate를 채택한 Coordinator 클래스
    class Coordinator: NSObject, PKCanvasViewDelegate {
        var parent: DrawingView
        
        init(_ parent: DrawingView) {
            self.parent = parent
        }
        
        func canvasViewDrawingDidChange(_ canvasView: PKCanvasView) {
            // 캔버스의 drawing이 변경되면 상위 뷰에 전달
            parent.drawing = canvasView.drawing
            parent.setDrawingData?(canvasView.drawing)
        }
    }
    
    // 도구 변경 메서드
    private func changeTool() -> PKTool {
        return isUsingPen
            ? PKInkingTool(.pen, color: .black, width: 4)
            : PKEraserTool(.vector, width: 10)
    }
}
