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
            VStack {
                Image(systemName: "globe")
                    .imageScale(.large)
                    .foregroundStyle(.tint)
                Text("Hello, world!")
                Button("Show Alert") {
                    showAlert = true
                }
                .alert(isPresented: $showAlert) {
                    Alert(
                        title: Text("경고"),
                        message: Text("\(String(describing: userData?.token))"),
                        primaryButton: .destructive(Text("삭제")) {
                            // 삭제 작업 수행
                        },
                        secondaryButton: .cancel(Text("취소"))
                    )
                }

//                Button("Get Homeworks") {
//                    let startDate = getDate(days: -7)
//                    let endDate = getDate(days: 0)
//
//                    fetchHomeworkList(token: userData!.token, relationId: userData!.relationId, startDate: startDate, endDate: endDate) { result in
//                        switch result {
//                        case .success(let homeworkListResponse):
//                            // 성공적으로 데이터를 받아왔을 때 처리
//                            print("HomeworkListResponce 디코드 성공:")
//                            if let homeworkList = homeworkListResponse.data?.items {
//                                for homework in homeworkList {
//                                    print("- 제목: \(homework.title ?? "제목 없음"), 생성일: \(homework.updateDateTime ?? "마감일 없음")")
//                                }
//                                homeworks = (homeworkListResponse.data?.items)!
//                            } else {
//                                print("homeworks 배열이 비어있거나 nil입니다.")
//                            }
//
//
//                        case .failure(let error):
//                            // 에러 발생 시 처리
//                            print("HomeworkListResponce 디코드 실패: \(error)")
//                        }
//
//                    }
//                }

                VStack(spacing: 30) {
                    ScrollView {
                        ForEach(homeworks, id: \.id) { homework in
                            let studentBookId = homework.studentBookId ?? 0
                            let savedCount = getSavedAnswersCount(studentBookId: studentBookId)
                            
                            HStack {
                                NavigationLink(destination: SolveView(studentBookId: String(homework.studentBookId ?? 0))
                                    .navigationTitle(homework.title ?? "풀이하기")) {
                                        // Content of the NavigationLink
                                        HStack {
                                            VStack() {
                                                Text("제목: \(homework.title ?? "제목 없음")")
                                                    .font(.headline)
                                                Spacer()
                                                Text("생성일: \(homework.updateDateTime ?? "마감일 없음")")
                                                    .font(.subheadline)
                                            }
                                            Spacer()
                                            VStack() {
                                                if (homework.status == "COMPLETE") {
                                                    Image(systemName: "checkmark.circle")
                                                        .foregroundStyle(Color.blue)
                                                } else if (homework.status == "INCOMPLETE") {
                                                    Image(systemName: "x.circle")
                                                        .foregroundStyle(Color.red)
                                                } else {
                                                    Image(systemName: "triangle.circle")
                                                        .foregroundStyle(Color.yellow)
                                                }
                                                Spacer()
                                                if (homework.status == "COMPLETED") {
                                                    Text("Complete")
                                                } else {
                                                    Text("\(String(homework.solvedCount ?? 0)) (\(savedCount)) / \(String(homework.totalCount ?? 0))")
                                                }
                                            }
                                        }
                                        .frame(width: 300, height: 60)
                                        .padding(20)
                                        .background(Color.gray.opacity(0.3).clipShape(RoundedRectangle(cornerRadius:20)))
                                    }
                                
                                // Submit All button outside of the NavigationLink
                                                            Button(action: {
                                                                let bookId = String(homework.studentBookId ?? 0)
                                                                self.submitAnswers(studentBookId: bookId)
                                                            }) {
                                                                Text("Submit All")
                                                            }
                                                            .padding(.horizontal, 10)
                            }
                        }
                    }
                }
            }
            .padding()
            .onAppear {
                if (userData == nil || userData?.token == nil) {
                    isLoginRequired = true
                }
                Task {
                    let startDate = getDate(days: -28)
                    let endDate = getDate(days: 0)

                    if (userData != nil) {
                        fetchHomeworkList(token: userData!.token, relationId: userData!.relationId, startDate: startDate, endDate: endDate) { result in
                            switch result {
                            case .success(let homeworkListResponse):
                                // 성공적으로 데이터를 받아왔을 때 처리
                                print("HomeworkListResponce 디코드 성공:")
                                if let homeworkList = homeworkListResponse.data?.items {
                                    for homework in homeworkList {
                                        print("- 제목: \(homework.title ?? "제목 없음"), 생성일: \(homework.updateDateTime ?? "마감일 없음")")
                                    }
                                    homeworks = (homeworkListResponse.data?.items)!
                                } else {
                                    print("homeworks 배열이 비어있거나 nil입니다.")
                                }
                                
                                
                            case .failure(let error):
                                // 에러 발생 시 처리
                                print("HomeworkListResponce 디코드 실패: \(error)")
                            }
                            
                        }
                    }
                }
            }
        }.fullScreenCover(isPresented: $isLoginRequired, content: { // fullScreenCover modifier 추가
            LoginView() // LoginView 추가 및 isLoginRequired binding
        })
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
