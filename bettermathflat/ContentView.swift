//
//  ContentView.swift
//  bettermathflat
//
//  Created by youngzheimer on 2/24/25.
//

import SwiftUI

struct ContentView: View {
    let userData = getUserData()
    @State var isLoginRequired = false
    @State private var showAlert = false
    @State private var homeworks: [Homework] = []

    func getSavedAnswersCount(studentBookId: Int) -> Int {
        let answers = loadUserAnswer(studentBookId: String(studentBookId))
        return answers?.filter { $0.answer != "" }.count ?? 0
    }
    
    func convertToLatexFraction(_ input: String) -> String {
        // 정규식 패턴: 부호(선택적)와 함께 숫자/숫자 형식을 찾음
        let pattern = "(-?\\d+)/(\\d+)"
        
        do {
            let regex = try NSRegularExpression(pattern: pattern, options: [])
            let nsString = input as NSString
            let range = NSRange(location: 0, length: nsString.length)
            
            // 결과를 저장할 변수
            var result = input
            
            // 정규식 매칭 결과를 뒤에서부터 처리 (문자열 길이가 변경되어도 영향 없도록)
            let matches = regex.matches(in: input, options: [], range: range).reversed()
            
            for match in matches {
                let numeratorRange = match.range(at: 1)
                let denominatorRange = match.range(at: 2)
                
                let numerator = nsString.substring(with: numeratorRange)
                let denominator = nsString.substring(with: denominatorRange)
                
                // 부호 처리
                var sign = ""
                var numeratorAbs = numerator
                
                if numerator.hasPrefix("-") {
                    sign = "-"
                    numeratorAbs = String(numerator.dropFirst())
                }
                
                // LaTeX 분수 형식으로 변환
                let latexFraction = "\(sign)\\\\frac{\(numeratorAbs)}{\(denominator)}"
                
                // 원본 문자열에서 해당 부분을 대체
                let replaceRange = NSRange(location: match.range.location, length: match.range.length)
                result = (result as NSString).replacingCharacters(in: replaceRange, with: latexFraction)
            }
            
            return result
        } catch {
            print("정규식 오류: \(error)")
            return input
        }
    }
    
    func submitAnswers(studentBookId: String) {
        let answers = loadUserAnswer(studentBookId: studentBookId)
        if (answers == nil || answers!.isEmpty) {
            return
        }
        
        var problems: [ProblemItem] = []
        fetchProblemList(token: userData!.token, studentBookId: studentBookId) { result in
            switch result {
            case .success(let problemListResponse):
                print("ProblemListResponce 디코드 성공:")
                problems = (problemListResponse.data?.content!)!
                answers!.forEach { answer in
                    if (!answer.submited && answer.answer != "") {
//                        if (problems[answer.problemIndex].problem!.type == "SINGLE_CHOICE") {
                        if (problems[answer.problemIndex].problem!.keypadTypes == ["DECIMAL"]) {
                            print(answer)
                            let sub = SubmitProblem(
                                worksheetProblemId: problems[answer.problemIndex].worksheetProblemId!,
                                unknown: answer.idk,
                                userAnswer: convertToLatexFraction(answer.answer)
                            )
                            submitProblems(token: userData!.token, studentBookId: studentBookId, submitProblems: [sub]) { result in
                                switch result {
                                case .success:
                                    break
                                case .failure(let error):
                                    print("실패 \(error)")
                                }
                            }
                        }
//                        } else if (problems[answer.problemIndex].problem!.keypadTypes == ["DECIMAL"]) {
//                            
//                        }
                    }
                }
            case .failure(let error):
                print("ProblemListResponce 디코드 실패: \(error)")
            }
        }
    }

    var body: some View {
        NavigationStack {
            ZStack(alignment: .top) {
                // Background Color
                Color(UIColor.systemGroupedBackground)
                    .edgesIgnoringSafeArea(.all)
                
                if homeworks.isEmpty {
                    VStack {
                        Spacer()
                        Image(systemName: "doc.text.magnifyingglass")
                            .font(.system(size: 60))
                            .foregroundColor(.gray)
                            .padding(.bottom, 10)
                        Text("숙제가 없습니다.")
                            .font(.headline)
                            .foregroundColor(.gray)
                        Spacer()
                    }
                } else {
                    ScrollView {
                        LazyVStack(spacing: 16) {
                            // Spacer for OfflineStatusView
                            Spacer().frame(height: 40)
                            
                            ForEach(homeworks, id: \.id) { homework in
                                let studentBookId = homework.studentBookId ?? 0
                                let savedCount = getSavedAnswersCount(studentBookId: studentBookId)
                                
                                NavigationLink(destination: SolveView(studentBookId: String(homework.studentBookId ?? 0))
                                    .navigationTitle(homework.title ?? "풀이하기")
                                ) {
                                    VStack(alignment: .leading, spacing: 12) {
                                        HStack {
                                            VStack(alignment: .leading, spacing: 4) {
                                                Text(homework.title ?? "제목 없음")
                                                    .font(.headline)
                                                    .foregroundColor(.primary)
                                                    .lineLimit(1)
                                                
                                                Text("생성일: \(homework.updateDateTime?.prefix(10) ?? "날짜 없음")")
                                                    .font(.caption)
                                                    .foregroundColor(.secondary)
                                            }
                                            Spacer()
                                            
                                            StatusBadge(status: homework.status ?? "UNKNOWN")
                                        }
                                        
                                        Divider()
                                        
                                        HStack {
                                            Label("\(String(homework.solvedCount ?? 0)) / \(String(homework.totalCount ?? 0)) 문제 풀이", systemImage: "pencil.and.outline")
                                                .font(.subheadline)
                                                .foregroundColor(.secondary)
                                            
                                            Spacer()
                                            
                                            if savedCount > 0 {
                                                Text("(\(savedCount) 저장됨)")
                                                    .font(.caption)
                                                    .foregroundColor(.blue)
                                            }
                                            
                                            // Submit Button within the card logic or separate?
                                            // Let's use a small button style
                                            Button(action: {
                                                let bookId = String(homework.studentBookId ?? 0)
                                                self.submitAnswers(studentBookId: bookId)
                                            }) {
                                                Text("제출")
                                                    .font(.caption)
                                                    .fontWeight(.bold)
                                                    .padding(.horizontal, 12)
                                                    .padding(.vertical, 6)
                                                    .background(Color.accentColor)
                                                    .foregroundColor(.white)
                                                    .cornerRadius(12)
                                            }
                                        }
                                    }
                                    .padding()
                                    .background(Color(UIColor.secondarySystemGroupedBackground))
                                    .cornerRadius(16)
                                    .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
                                }
                                .buttonStyle(PlainButtonStyle()) // To make the whole card tapable without triggering the inner button usually? No.
                                // SwiftUI Nested Buttons are tricky. It's better to tap the card to go to solve view.
                                // The submit button might conflict. Rework: Make the submit button separate or use highPriorityGesture.
                                // Actually, simpler: Just let the user enter the view to solve. Submit logic is usually inside or "Long press" or separate menu.
                                // But since the user had a separate button before, let's keep it but make it work.
                                // Using a button inside a NavigationLink can be problematic.
                                // Let's put the Submit button in a ContextMenu or distinct tappable area if possible.
                                // Or, just put the Submit button NEXT to the progress text, but as a plain view inside the link? No, that won't work.
                                // Alternative: Swipe Actions!
                            }
                            // Swipe actions replacement or keep simple?
                            // Let's stick to the card design but maybe move "Submit" into the `SolveView` or keep it accessible.
                            // If I keep the nested button, I need to ensure the tap areas don't conflict.
                            // Actually, native style is often list rows.
                            
                        }
                        .padding()
                    }
                    .refreshable {
                         loadData()
                    }
                }
                
                // Floating Status Bar
                OfflineStatusView()
            }
            .navigationTitle("나의 숙제")
            .onAppear {
                if (userData == nil || userData?.token == nil) {
                    isLoginRequired = true
                }
                loadData()
            }
        }
        .fullScreenCover(isPresented: $isLoginRequired) {
            LoginView()
        }
    }
    
    func loadData() {
        Task {
            let startDate = getDate(days: -28)
            let endDate = getDate(days: 0)

            if (userData != nil) {
                fetchHomeworkList(token: userData!.token, relationId: userData!.relationId, startDate: startDate, endDate: endDate) { result in
                    switch result {
                    case .success(let homeworkListResponse):
                        if let homeworkList = homeworkListResponse.data?.items {
                            DispatchQueue.main.async {
                                homeworks = homeworkList
                            }
                            OfflineManager.shared.saveHomeworkList(homeworkList)
                            OfflineManager.shared.cacheAllHomeworkDetails(token: userData!.token, homeworks: homeworkList)
                        }
                    case .failure:
                        if let cachedList = OfflineManager.shared.loadHomeworkList() {
                            DispatchQueue.main.async {
                                homeworks = cachedList
                            }
                        }
                    }
                }
            }
        }
    }
}

// Subview for Status
struct StatusBadge: View {
    let status: String
    
    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: iconName)
            Text(statusText)
        }
        .font(.caption)
        .fontWeight(.bold)
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(backgroundColor.opacity(0.1))
        .foregroundColor(backgroundColor)
        .cornerRadius(8)
    }
    
    var iconName: String {
        switch status {
        case "COMPLETE", "COMPLETED": return "checkmark.circle.fill"
        case "INCOMPLETE": return "xmark.circle.fill"
        default: return "hourglass"
        }
    }
    
    var statusText: String {
        switch status {
        case "COMPLETE", "COMPLETED": return "완료"
        case "INCOMPLETE": return "미완료"
        default: return "진행중"
        }
    }
    
    var backgroundColor: Color {
        switch status {
        case "COMPLETE", "COMPLETED": return .green
        case "INCOMPLETE": return .red
        default: return .orange
        }
    }
}

extension UIImageView {
    func load(url: URL) {
        DispatchQueue.global().async { [weak self] in
            if let data = try? Data(contentsOf: url) {
                if let image = UIImage(data: data) {
                    DispatchQueue.main.async {
                        self?.image = image
                    }
                }
            }
        }
    }
}

#Preview {
    ContentView()
}
