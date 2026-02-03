//
//  SolveView.swift
//  bettermathflat
//
//  Created by youngzheimer on 2/25/25.
//

import SwiftUI
import PencilKit

struct SolveView: View {
    let userData = getUserData()
    @Environment(\.colorScheme) var scheme
    
    @State private var isPen = true
    @State private var currentDrawing = PKDrawing()
    
    @State var currentAnswer = ""
    @State var currentAnswerSubmited = false
    @State var submittingAnswer = false
    @State var currentAnswerDontKnow: Bool = false
    @State var useranswers: [UserAnswer] = []
    @State var onlyViewUnsolvedProblems = false
    
    @State var showExpVideo: Bool = false
    @State var expVideoURL: URL = URL(string: "https://google.com")!
    @State var isThereExpVideo: Bool = false
    @State var showExpImage: Bool = false

    var studentBookId: String
    @State var problemList: [ProblemItem] = []
    @State var currentProblem = 0

    var body: some View {
        VStack(spacing: 10) { // 요소 간 간격 조정
            if !problemList.isEmpty && currentProblem < problemList.count {
                // MARK: - 문제 번호 표시
                HStack {
                    Text("\(currentProblem + 1) / \(problemList.count)")
                        .font(.headline) // 폰트 조정
                        .foregroundColor(.secondary) // 색상 조정
                    
                    Text("•")
                    
                    Menu("Go To...") {
                        ForEach(problemList.indices, id: \.self) { index in
                            HStack {
                                Button() {
                                    gotoPage(pagenum: index)
                                } label: {
                                    if let useranswer = useranswers.first(where: { $0.problemIndex == index }) {
                                        if (!useranswer.submited) {
                                            if (useranswer.idk) {
                                                ProblemIndicatorView(color: Color.yellow, systemName: "questionmark.circle", index: index + 1)
                                            } else if (useranswer.answer == "") {
                                                ProblemIndicatorView(color: Color.gray, systemName: "ellipsis.circle", index: index + 1)
                                            } else {
                                                ProblemIndicatorView(color: Color.white, systemName: "pencil.circle", index: index + 1)
                                            }
                                        } else {
                                            if (problemList[index].result! == "CORRECT") {
                                                ProblemIndicatorView(color: Color.green, systemName: "checkmark.circle", index: index + 1)
                                            } else if (problemList[index].result! == "WRONG") {
                                                ProblemIndicatorView(color: Color.red, systemName: "xmark.circle", index: index + 1)
                                            } else {
                                                ProblemIndicatorView(color: Color.yellow, systemName: "questionmark.circle", index: index + 1)
                                            }

//                                            ProblemIndicatorView(color: Color.green, systemName: "checkmark.circle", index: index + 1)
                                        }

                                    } else {
                                        if (problemList[index].result! == "NONE") {
                                            ProblemIndicatorView(color: Color.gray, systemName: "ellipsis.circle", index: index + 1)
                                        } else if (problemList[index].result! == "CORRECT") {
                                            ProblemIndicatorView(color: Color.green, systemName: "checkmark.circle", index: index + 1)
                                        } else if (problemList[index].result! == "WRONG") {
                                            ProblemIndicatorView(color: Color.red, systemName: "xmark.circle", index: index + 1)
                                        } else {
                                            ProblemIndicatorView(color: Color.yellow, systemName: "questionmark.circle", index: index + 1)
                                        }
                                    }
                                }
                            }
                        }
                    }
                    
                    Text("•")
                    
                    Button("Unsolved Only") {
                        onlyViewUnsolvedProblems.toggle()
                    }.foregroundStyle(onlyViewUnsolvedProblems ? Color.blue : Color.gray)
                }.frame(maxWidth: .infinity, alignment: .center)
                    
                // MARK: - 정답 상태 / 해설 / 정답률  표시
                HStack {
                    // 정답상태
                    if (currentAnswerSubmited) {
                        if (problemList[currentProblem].result! == "CORRECT") {
                            Image(systemName: "circle.circle")
                                .symbolRenderingMode(.palette)
                                .foregroundColor(.green)
                        } else {
                            Image(systemName: "xmark.circle")
                                .symbolRenderingMode(.palette)
                                .foregroundColor(.red)
                        }
                        Text(problemList[currentProblem].result!)
                            .foregroundStyle(problemList[currentProblem].result! == "CORRECT" ? .green : .red)
                        Text("•")
                    }
                    
                    if (isThereExpVideo) {
                        Button("해설 영상") {
                            showExpImage = false
                            showExpVideo.toggle()
                        }
                        
                        Text("•")
                    }
                    
                    Button("해설") {
                        showExpVideo = false
                        showExpImage.toggle()
                    }
                    
                    Text("•")
                    
                    Text("정답률: \(String(describing: problemList[currentProblem].problem!.problemSummary!.answerRate!))%")
                }
                
                if (showExpVideo) {
                    VideoPlayerView(videoURL: $expVideoURL)
                } else if (showExpImage) {
                    VStack {
                    if let problemImageUrl = problemList[currentProblem].problem?.solutionImageUrl {
                        AsyncImage(url: OfflineManager.shared.getLocalImageURL(for: problemImageUrl) ?? URL(string: problemImageUrl)) { phase in
                            switch phase {
                            case .empty:
                                ProgressView()
                            case .success(let image):
                                image
                                    .resizable()
                                    .scaledToFit()
                            case .failure:
                                Image(systemName: "x.circle.fill")
                                    .foregroundColor(.red)
                            @unknown default:
                                Image(systemName: "questionmark.circle.fill")
                                    .foregroundColor(.gray)
                            }
                        }
                        .padding(20)
                    } else {
                        Text("해답 이미지 URL이 없습니다.")
                            .foregroundColor(.gray)
                    }
                }
                .frame(maxHeight: 300)
                .background(Color.white)
                .cornerRadius(10)
                .padding(20)
                }
                
                else {
                    // MARK: - 문제 이미지
                    VStack {
                        if let problemImageUrl = problemList[currentProblem].problem?.problemImageUrl {
                            AsyncImage(url: OfflineManager.shared.getLocalImageURL(for: problemImageUrl) ?? URL(string: problemImageUrl)) { phase in
                                switch phase {
                                case .empty:
                                    ProgressView()
                                case .success(let image):
                                    image
                                        .resizable()
                                        .scaledToFit()
                                case .failure:
                                    Image(systemName: "x.circle.fill")
                                        .foregroundColor(.red)
                                @unknown default:
                                    Image(systemName: "questionmark.circle.fill")
                                        .foregroundColor(.gray)
                                }
                            }
                            .padding(20)
                        } else {
                            Text("문제 이미지 URL이 없습니다.")
                                .foregroundColor(.gray)
                        }
                    }
                    .frame(maxHeight: 300)
                    .background(Color.white)
                    .cornerRadius(10)
                    .padding(20)
                }
                
                // MARK: - Drawing Canvas
                DrawingView(isUsingPen: $isPen, drawing: $currentDrawing)
                    .onPencilDoubleTap(perform: {value in 
                        isPen.toggle()
                    })
                    .onChange(of: currentDrawing) {
                        saveDrawing(drawing: currentDrawing, studentBookId: studentBookId, problemIndex: currentProblem)
                    }
                    .cornerRadius(10) /// make the background rounded
                    .overlay( /// apply a rounded border
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(scheme == .light ? Color.black : Color.white, lineWidth: 1)
                    )
                    .padding(.horizontal, 20)
//                    .border(scheme == .light ? Color.black : Color.white, width: 1)
                
                Button(isPen ? "펜" : "지우개") {
                    isPen.toggle()
                }
                
                // MARK: - 문제 넘기기 버튼
                HStack(spacing: 20) { // 버튼 간 간격 조정
                    Button {
                        if (!currentAnswerSubmited) { saveUserAnswer(answer: currentAnswer, studentBookId: studentBookId, problemIndex: currentProblem, idk: currentAnswerDontKnow, submited: false) }
                        
                        if (currentProblem > 0) {
                            currentProblem -= 1
                            
                            if (onlyViewUnsolvedProblems) {
                                while (currentProblem > 0) {
                                    if let userAnswer = useranswers.first(where: { $0.problemIndex == currentProblem }) {
                                        if (userAnswer.answer != "" || userAnswer.submited) {
                                            currentProblem -= 1
                                        } else {
                                            break
                                        }
                                    } else {
                                        break
                                    }
                                }
                            }
                        }
                        
                        pageUpdate()
                    } label: {
                        Image(systemName: "chevron.left") // SF Symbols 사용
                    }
                    .buttonStyle(CustomButtonStyle()) // 커스텀 버튼 스타일 적용
                    .disabled(currentProblem == 0) // 첫 문제에서는 비활성화
                    
                    Spacer()
                    
                    // MARK: - 정답입력
//                    TextField("Placeholder? maybe", text: $currentAnswer)
//                        .onChange(of: currentAnswer) {
//                            if (!currentAnswerSubmited) { saveUserAnswer(answer: currentAnswer, studentBookId: studentBookId, problemIndex: currentProblem, submited: false) }
//                        }
//                        .onSubmit {
//                            if (!currentAnswerSubmited) { saveUserAnswer(answer: currentAnswer, studentBookId: studentBookId, problemIndex: currentProblem, submited: false) }
//                        }
//                        .padding(10)
//                        .cornerRadius(10) /// make the background rounded
//                        .overlay( /// apply a rounded border
//                            RoundedRectangle(cornerRadius: 10)
//                                .stroke(scheme == .light ? Color.black : Color.white, lineWidth: 1)
//                        )
//                        .disabled(currentAnswerSubmited)
                    
                    AnswerEnterView(problem: problemList[currentProblem], selected: $currentAnswer, submited: $currentAnswerSubmited, idk: $currentAnswerDontKnow)
                        .opacity(currentAnswerDontKnow ? 0.3 : 1.0)
                    
                    // MARK: - 정답제출
//                    Button("Submit") {
//                        if (currentAnswerSubmited) { return }
//                        submittingAnswer = true
//                        submitProblems(token: userData!.token, studentBookId: studentBookId, submitProblems: [SubmitProblem(worksheetProblemId: problemList[currentProblem].worksheetProblemId!, unknown: false, userAnswer: currentAnswer)]) { _ in
//                                fetchProblemList(token: userData!.token, studentBookId: studentBookId) { result in
//                                    switch result {
//                                    case .success(let problemListResponse):
//                                        print("ProblemListResponce 디코드 성공:")
//                                        problemList = (problemListResponse.data?.content!)!
//                                        savePreviousSubmitedAnswers()
//                                    case .failure(let error):
//                                        print("ProblemListResponce 디코드 실패: \(error)")
//                                    }
//                            }
//                        }
//                    }
//                    .buttonStyle(CustomButtonStyle())
//                    .disabled(currentAnswerSubmited || submittingAnswer)
                    
                    Button("IDK") {
                        currentAnswerDontKnow.toggle()
                    }
                    .foregroundStyle(currentAnswerDontKnow ? Color.blue : Color.gray)
                    
                    Spacer()
                    
                    Button {
                        if (!currentAnswerSubmited) { saveUserAnswer(answer: currentAnswer, studentBookId: studentBookId, problemIndex: currentProblem, idk: currentAnswerDontKnow, submited: false) }
                        
                        if (currentProblem < problemList.count - 1) {
                            currentProblem += 1
                            
                                
                            if (onlyViewUnsolvedProblems) {
                                while (currentProblem < problemList.count - 1) {
                                    print("Checking \(currentProblem)")
                                    if let userAnswer = useranswers.first(where: { $0.problemIndex == currentProblem }) {
                                        if (userAnswer.answer != "" || userAnswer.submited) {
                                            currentProblem += 1
                                        } else {
                                            break
                                        }
                                    } else {
                                        break
                                    }
                                }
                            }
                        }
                        
                        pageUpdate()
                    } label: {
                        Image(systemName: "chevron.right") // SF Symbols 사용
                    }
                    .buttonStyle(CustomButtonStyle()) // 커스텀 버튼 스타일 적용
                    .disabled(currentProblem == problemList.count - 1) // 마지막 문제에서는 비활성화
                }
                .padding(.horizontal, 20) // 좌우 패딩 추가
            } else {
                ProgressView()
            }
        }
        .padding(.bottom, 30) // 상하 패딩 조정
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top) // 화면 전체 채우도록 설정, 상단 정렬
        .onAppear() {
            Task {
                print(userData!.token)
                print(studentBookId)
                fetchProblemList(token: userData!.token, studentBookId: studentBookId) { result in
                    switch result {
                    case .success(let problemListResponse):
                        print("ProblemListResponce 디코드 성공:")
                        if let content = problemListResponse.data?.content {
                            DispatchQueue.main.async {
                                problemList = content
                                savePreviousSubmitedAnswers()
                            }
                            // Save to cache
                            OfflineManager.shared.saveProblemList(studentBookId: studentBookId, list: content)
                        }
                    case .failure(let error):
                        print("ProblemListResponce 디코드 실패: \(error)")
                        // Load from cache
                        if let cached = OfflineManager.shared.loadProblemList(studentBookId: studentBookId) {
                            print("Loaded from cache")
                            DispatchQueue.main.async {
                                problemList = cached
                                savePreviousSubmitedAnswers()
                            }
                        }
                    }
                }
            }
        }
        
    }
    
    private func gotoPage(pagenum: Int) {
        if (!currentAnswerSubmited) { saveUserAnswer(answer: currentAnswer, studentBookId: studentBookId, problemIndex: currentProblem, idk: currentAnswerDontKnow, submited: false) }
        
        currentProblem = pagenum
        
        pageUpdate()

    }
    
    private func pageUpdate() {
        showExpVideo = false
        showExpImage = false
        if (problemList[currentProblem].problem!.video != nil) {
            expVideoURL = URL(string: problemList[currentProblem].problem!.video!.videoUrl!)!
            isThereExpVideo = true
        } else {
            isThereExpVideo = false
        }
        currentAnswer = ""
        let loadedDrawing = loadDrawing(studentBookId: studentBookId, problemIndex: currentProblem)
        if (loadedDrawing != nil) {
            currentDrawing = loadedDrawing!
        } else {
            currentDrawing = PKDrawing()
        }
        
        let loadedUserAnswer = loadIndvUserAnswer(studentBookId: studentBookId, problemIndex: currentProblem)
        if (loadedUserAnswer != nil) {
            currentAnswer = loadedUserAnswer!.answer
            currentAnswerSubmited = loadedUserAnswer!.submited
            currentAnswerDontKnow = loadedUserAnswer!.idk
        } else {
            currentAnswer = ""
            currentAnswerSubmited = false
            currentAnswerDontKnow = false
        }
        
        let loadedUserAnswers = loadUserAnswer(studentBookId: studentBookId)
        if (loadedUserAnswers != nil) {
            useranswers = loadedUserAnswers!
        }
        
        submittingAnswer = false
    }
    
    private func savePreviousSubmitedAnswers() {
        for (index, problem) in problemList.enumerated() {
            if (problem.userAnswer != nil && problem.userAnswer != "") {
                saveUserAnswer(answer: problem.userAnswer!, studentBookId: studentBookId, problemIndex: index, idk: currentAnswerDontKnow, submited: true)
            }
        }
        pageUpdate()
    }
    
//    var controlPanel: some View {
//        VStack {
//            Toggle("지우개", isOn: $isEraser)
//            
//            ColorPicker("펜 색상", selection: $penColor)
//                .disabled(isEraser)
//            
//            Slider(value: $penWidth, in: 1...20) {
//                Text("굵기: \(Int(penWidth))")
//            }
//            
//            Button("초기화") {
//                drawing = PKDrawing()
//            }
//        }
//    }
}

struct ProblemSelectMenuView: View {
    let useranswers: [UserAnswer]
    let index: Int
    let problemList: [ProblemItem]
    
    var body: some View {
        if let useranswer = useranswers.first(where: { $0.problemIndex == index }) {
            if (!useranswer.submited) {
                if (useranswer.idk) {
                    ProblemIndicatorView(color: Color.yellow, systemName: "questionmark.circle", index: index + 1)
                } else if (useranswer.answer == "") {
                    ProblemIndicatorView(color: Color.primary, systemName: "ellipsis.circle", index: index + 1)
                } else {
                    ProblemIndicatorView(color: Color.gray, systemName: "ellipsis.circle", index: index + 1)
                }
            } else {
                if (problemList[index].result! == "CORRECT") {
                    ProblemIndicatorView(color: Color.green, systemName: "checkmark.circle", index: index + 1)
                    
                } else if (problemList[index].result! == "WRONG") {
                    ProblemIndicatorView(color: Color.red, systemName: "xmark.circle", index: index + 1)
                } else {
                    ProblemIndicatorView(color: Color.yellow, systemName: "questionmark.circle", index: index + 1)
                }
                
                //                                            ProblemIndicatorView(color: Color.green, systemName: "checkmark.circle", index: index + 1)
            }
            
        } else {
            ProblemIndicatorView(color: Color.gray, systemName: "ellipsis.circle", index: index + 1)
        }
    }
}

struct ProblemIndicatorView: View {
    let color: Color
    let systemName: String
    let index: Int
    
    var body: some View {
        Text("Problem \(index)")
            .foregroundStyle(color)
        Image(systemName: systemName)
            .symbolRenderingMode(.palette)
            .foregroundColor(color)
    }
}

// MARK: - Custom Button Style (모던 버튼 스타일)
struct CustomButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .padding(.vertical, 12) // 세로 패딩 증가
            .padding(.horizontal, 25) // 가로 패딩 증가
            .font(.headline) // 폰트 조정
            .foregroundColor(.white) // 텍스트 색상 흰색
            .background(Color.accentColor) // 배경색 accentColor 사용
            .cornerRadius(10) // 모서리 둥글게
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0) // 눌렀을 때 스케일 효과
    }
}

struct AnswerEnterView: View {
    let problem: ProblemItem
    @Binding var selected: String
    @Binding var submited: Bool
    @Binding var idk: Bool
    
    var body: some View {
        if (problem.problem!.type! == "SINGLE_CHOICE") {
            // problem.problem!.optionCount!
            HStack(spacing: 20) {
                ForEach(0..<problem.problem!.optionCount!, id: \.self) { index in
                    Button("\(index + 1)") {
                        selected = String(index + 1)
                    }
                    .disabled(Int(selected) == index + 1 || submited || idk)
                    .frame(width: 40, height: 40, alignment: .center)
                    .background(Int(selected) == index + 1 ? Color.accentColor : Color.gray)
                    .cornerRadius(1000)
                    .foregroundColor(Color.white)
                }
            }
        } else {
            TextField("Enter Your Answer", text: $selected)
                .disabled(submited || idk)
                .padding(.horizontal, 10)
                .frame(width: 300, height: 40, alignment: .center)
                .background(Color.gray.opacity(0.2))
                .cornerRadius(10)
        }
    }
}

#Preview {
    SolveView(studentBookId: "61562121")
}
