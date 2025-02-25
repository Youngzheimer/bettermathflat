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
                    ForEach(homeworks, id: \.id) { homework in
                        NavigationLink(destination: SolveView(studentBookId: String(homework.studentBookId ?? 0)).navigationTitle(homework.title ?? "풀이하기")) {
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
                                        Text("\(String(homework.solvedCount ?? 0)) / \(String(homework.totalCount ?? 0))")
                                    }
                                }
                            }
                            .frame(width: 300, height: 60)
                            .padding(20)
                            .background(Color.gray.opacity(0.3).clipShape(RoundedRectangle(cornerRadius:20)))
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
                    let startDate = getDate(days: -7)
                    let endDate = getDate(days: 0)

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
