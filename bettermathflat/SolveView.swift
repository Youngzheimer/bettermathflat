//
//  SolveView.swift
//  bettermathflat
//
//  Created by youngzheimer on 2/25/25.
//

import SwiftUI

// CGPoint를 Codable하게 만들기 위한 래퍼 구조체
struct CodablePoint: Codable {
    let x: CGFloat
    let y: CGFloat

    init(from point: CGPoint) {
        self.x = point.x
        self.y = point.y
    }

    var pointValue: CGPoint {
        return CGPoint(x: x, y: y)
    }
}

struct SolveView: View {
    let userData = getUserData()

    // 문제별로 선 데이터를 저장하는 Dictionary (CodablePoint 사용)
    @State var problemLines: [Int: [[CodablePoint]]] = [:]
    @State var currentProblemLines: [[CGPoint]] = [] // 현재 문제에 대한 선 데이터 (그리기 캔버스 사용을 위해 CGPoint 유지)

    var studentBookId: String
    @State var problemList: [ProblemItem] = []
    @State var currentProblem = 0

    var body: some View {
        VStack(spacing: 10) { // 요소 간 간격 조정
            if !problemList.isEmpty && currentProblem < problemList.count {
                // MARK: - 문제 번호 표시
                Text("\(currentProblem + 1) / \(problemList.count)")
                    .font(.headline) // 폰트 조정
                    .foregroundColor(.secondary) // 색상 조정

                // MARK: - 문제 이미지
                VStack {
                    if let problemImageUrl = problemList[currentProblem].problem?.problemImageUrl {
                        AsyncImage(url: URL(string: problemImageUrl)) { phase in
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
                .frame(maxHeight: 500)
                .background(Color.white)
                .cornerRadius(10)
                .padding(20)
                
                // MARK: - Drawing Canvas
                DrawingCanvasView(lines: problemLinesBinding)
                    .frame(height: 600)
                    .background(Color(.systemGray6)) // 은은한 배경색 적용
                    .cornerRadius(10) // 캔버스 모서리 둥글게
                    .padding(20)

                // MARK: - 문제 넘기기 버튼
                HStack(spacing: 20) { // 버튼 간 간격 조정
                    Button {
                        if (currentProblem > 0) {
                            saveDrawingToUserDefaults()
                            currentProblem -= 1
                            loadDrawingFromUserDefaults()
                        }
                    } label: {
                        Image(systemName: "chevron.left") // SF Symbols 사용
                    }
                    .buttonStyle(CustomButtonStyle()) // 커스텀 버튼 스타일 적용
                    .disabled(currentProblem == 0) // 첫 문제에서는 비활성화

                    Spacer() // 가운데 여백

                    Button {
                        if (currentProblem < problemList.count - 1) {
                            saveDrawingToUserDefaults()
                            currentProblem += 1
                            loadDrawingFromUserDefaults()
                        }
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
        .padding(.vertical, 30) // 상하 패딩 조정
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top) // 화면 전체 채우도록 설정, 상단 정렬
        .onAppear() {
            Task {
                print(userData!.token)
                print(studentBookId)
                fetchProblemList(token: userData!.token, studentBookId: studentBookId) { result in
                    switch result {
                    case .success(let problemListResponse):
                        print("ProblemListResponce 디코드 성공:")
                        problemList = (problemListResponse.data?.content!)!
                        loadDrawingFromUserDefaults()
                    case .failure(let error):
                        print("ProblemListResponce 디코드 실패: \(error)")
                    }
                }
            }
        }
        .onDisappear(perform: {
            saveDrawingToUserDefaults()
        })
        .onChange(of: currentProblem) { newProblemIndex in
            loadDrawingFromUserDefaults()
        }
    }

    // problemLines의 currentProblem에 해당하는 Binding을 계산 속성으로 제공
    private var problemLinesBinding: Binding<[[CGPoint]]> {
        Binding<[[CGPoint]]>(
            get: {
                problemLines[currentProblem]?.map { $0.map { $0.pointValue } } ?? []
            },
            set: { newLines in
                problemLines[currentProblem] = newLines.map { $0.map { CodablePoint(from: $0) } }
            }
        )
    }

    // UserDefaults에 필기 데이터 저장
    func saveDrawingToUserDefaults() {
        guard !problemList.isEmpty else { return }
        let problemIndex = currentProblem
        var currentProblemCodableLines = problemLines[problemIndex] ?? []

        if !currentProblemLines.isEmpty {
            currentProblemCodableLines = currentProblemLines.map { $0.map { CodablePoint(from: $0) } }
            problemLines[problemIndex] = currentProblemCodableLines
        }

        if let codableProblemLinesData = try? JSONEncoder().encode(problemLines) {
            UserDefaults.standard.set(codableProblemLinesData, forKey: userDefaultsKey())
            print("필기 데이터 UserDefaults 저장 성공")
        } else {
            print("필기 데이터 UserDefaults 저장 실패")
        }
    }

    // UserDefaults에서 필기 데이터 불러오기
    func loadDrawingFromUserDefaults() {
        guard !problemList.isEmpty else { return }

        if let savedProblemLinesData = UserDefaults.standard.data(forKey: userDefaultsKey()),
           let savedProblemLines = try? JSONDecoder().decode([Int: [[CodablePoint]]].self, from: savedProblemLinesData) {
            problemLines = savedProblemLines
            currentProblemLines = problemLines[currentProblem]?.map { $0.map { $0.pointValue } } ?? []
            print("필기 데이터 UserDefaults 로드 성공")
        } else {
            problemLines = [:]
            currentProblemLines = []
            print("UserDefaults에 저장된 필기 데이터 없음 또는 로드 실패")
        }
        currentProblemLines = problemLines[currentProblem]?.map { $0.map { $0.pointValue } } ?? []
    }

    private func userDefaultsKey() -> String {
        return "problemLines_\(studentBookId)"
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


#Preview {
    SolveView(studentBookId: "61317886")
}
