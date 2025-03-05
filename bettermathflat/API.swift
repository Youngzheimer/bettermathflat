//
//  API.swift
//  bettermathflat
//
//  Created by youngzheimer on 2/24/25.
//

import Foundation


// MARK: - login
func login(phoneNumber: String, completion: @escaping (Result<LoginResponce, Error>) -> Void) {
    guard let url = URL(string: "https://api.mathflat.com/login") else {
        completion(.failure(NSError(domain: "Invalid URL", code: -1, userInfo: nil)))
        return
    }

    var request = URLRequest(url: url)
    request.httpMethod = "POST"
    request.addValue("application/json", forHTTPHeaderField: "Content-Type")
    request.addValue("STUDENT", forHTTPHeaderField: "x-platform")

    let parameters: [String: Any] = ["id": phoneNumber, "password": ""]
    guard let httpBody = try? JSONSerialization.data(withJSONObject: parameters, options: []) else {
        completion(.failure(NSError(domain: "JSON Encoding Error", code: -2, userInfo: nil)))
        return
    }
    request.httpBody = httpBody

    let task = URLSession.shared.dataTask(with: request) { data, response, error in
        if let error = error {
            completion(.failure(error))
            return
        }

        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            completion(.failure(NSError(domain: "Invalid HTTP Response", code: 400, userInfo: nil)))
            return
        }

        guard let data = data else {
            completion(.failure(NSError(domain: "No Data Received", code: -4, userInfo: nil)))
            return
        }

        do {
            let res = try JSONDecoder().decode(LoginResponce.self, from: data)
            completion(.success(res))
        } catch {
            completion(.failure(error))
        }
    }

    task.resume()
}

// MARK: - Homework List
func fetchHomeworkList(token: String, relationId: String, startDate: String, endDate: String, completion: @escaping (Result<HomeworkListResponse, Error>) -> Void) {
    var urlComponents = URLComponents(string: "https://api.mathflat.com/student-history/work/student/\(relationId)/homeworks")! // 기본 URL 설정
    urlComponents.queryItems = [ // 쿼리 파라미터 설정
        URLQueryItem(name: "startDate", value: startDate),
        URLQueryItem(name: "endDate", value: endDate)
    ]
    
    guard let url = urlComponents.url else {
        let error = NSError(domain: "URL 생성 에러", code: -1, userInfo: [NSLocalizedDescriptionKey: "잘못된 URL 형식입니다."])
        completion(.failure(error))
        return
    }
    
    var request = URLRequest(url: url)
    request.httpMethod = "GET"

    request.setValue("STUDENT", forHTTPHeaderField: "x-platform")
    request.setValue(token, forHTTPHeaderField: "x-auth-token")

    let task = URLSession.shared.dataTask(with: request) { data, response, error in
        if let error = error {
            completion(.failure(error))
            return
        }

        guard let httpResponse = response as? HTTPURLResponse else {
            let error = NSError(domain: "HTTP 응답 에러", code: -2, userInfo: [NSLocalizedDescriptionKey: "HTTP 응답이 아닙니다."])
            completion(.failure(error))
            return
        }

        guard (200...299).contains(httpResponse.statusCode) else {
            let error = NSError(domain: "HTTP 상태 코드 에러", code: httpResponse.statusCode, userInfo: [NSLocalizedDescriptionKey: "상태 코드: \(httpResponse.statusCode)"])
            completion(.failure(error))
            return
        }

        guard let data = data else {
            let error = NSError(domain: "데이터 에러", code: -3, userInfo: [NSLocalizedDescriptionKey: "데이터가 없습니다."])
            completion(.failure(error))
            return
        }

        do {
            let decoder = JSONDecoder()
            let homeworkListResponse = try decoder.decode(HomeworkListResponse.self, from: data)
            completion(.success(homeworkListResponse))
        } catch {
            completion(.failure(error))
        }
    }
    task.resume()
}

// MARK: - ProblemList
func fetchProblemList(token: String, studentBookId: String, completion: @escaping (Result<ProblemListResponse, Error>) -> Void) {
//    var urlComponents = URLComponents(string: "https://api.mathflat.com/student-worksheet/assign/\(studentBookId)/problem")!  기본 URL 설정
    
    guard let url = URL(string: "https://api.mathflat.com/student-worksheet/assign/\(studentBookId)/problem") else {
        let error = NSError(domain: "URL 생성 에러", code: -1, userInfo: [NSLocalizedDescriptionKey: "잘못된 URL 형식입니다."])
        completion(.failure(error))
        return
    }
    
    var request = URLRequest(url: url)
    request.httpMethod = "GET"

    request.setValue("STUDENT", forHTTPHeaderField: "x-platform")
    request.setValue(token, forHTTPHeaderField: "x-auth-token")

    let task = URLSession.shared.dataTask(with: request) { data, response, error in
        if let error = error {
            completion(.failure(error))
            return
        }

        guard let httpResponse = response as? HTTPURLResponse else {
            let error = NSError(domain: "HTTP 응답 에러", code: -2, userInfo: [NSLocalizedDescriptionKey: "HTTP 응답이 아닙니다."])
            completion(.failure(error))
            return
        }

        guard (200...299).contains(httpResponse.statusCode) else {
            let error = NSError(domain: "HTTP 상태 코드 에러", code: httpResponse.statusCode, userInfo: [NSLocalizedDescriptionKey: "상태 코드: \(httpResponse.statusCode)"])
            completion(.failure(error))
            return
        }

        guard let data = data else {
            let error = NSError(domain: "데이터 에러", code: -3, userInfo: [NSLocalizedDescriptionKey: "데이터가 없습니다."])
            completion(.failure(error))
            return
        }
        
        if let rawDataString = String(data: data, encoding: .utf8) {
            print("===== Raw HomeworkList Data Start =====")
            print(rawDataString)
            print("===== Raw HomeworkList Data End =====")
        } else {
            print("Raw 데이터 변환 실패") // UTF8 인코딩 실패 시 에러 출력
        }


        do {
            let decoder = JSONDecoder()
            let problemListResponse = try decoder.decode(ProblemListResponse.self, from: data)
            completion(.success(problemListResponse))
        } catch {
            completion(.failure(error))
        }
    }
    task.resume()
}

// MARK: - submitProblems
func submitProblems(token: String, studentBookId: String, submitProblems: [SubmitProblem], completion: @escaping (Result<String, Error>) -> Void) {
    guard let url = URL(string: "https://api.mathflat.com/student-worksheet/assign/\(studentBookId)/auto-scoring") else {
        let error = NSError(domain: "URL 생성 에러", code: -1, userInfo: [NSLocalizedDescriptionKey: "잘못된 URL 형식입니다."])
        completion(.failure(error))
        return
    }
    
    var request = URLRequest(url: url)
    request.httpMethod = "PATCH"
    
    request.setValue("STUDENT", forHTTPHeaderField: "x-platform")
    request.setValue(token, forHTTPHeaderField: "x-auth-token")
    request.setValue("application/json", forHTTPHeaderField: "Content-Type")
    
    do {
        let jsonData = try JSONEncoder().encode(submitProblems)
        request.httpBody = jsonData
    } catch {
        print("submitProblems JSON 인코딩 에러: \(error)")
        completion(.failure(error))
        return
    }
    
    let task = URLSession.shared.dataTask(with: request) { data, response, error in
        if let error = error {
            print("네트워크 요청 에러: \(error)")
            completion(.failure(error))
            return
        }
        completion(.success("nil"))
    }
    task.resume()
}


// MARK: - Login Codable
struct LoginResponce: Codable {
    let data: UserData
    let code: String?
    let message: String?
}

struct UserData: Codable {
    let id: String
    let userType: String
    let academyId: String
    let relationId: String
    let authorities: [String]
    let token: String
}

// MARK: - Homework Codable
struct HomeworkListResponse: Codable {
    let data: HomeworkListDataContainer?
    let code: String?
    let message: String?
}

struct HomeworkListDataContainer: Codable {
    let items: [Homework]?
    let workbookProblemCount: Int?
    let workbookProblemSolvedCount: Int?
    let worksheetProblemCount: Int?
    let worksheetProblemSolvedCount: Int?
}

struct Homework: Codable {
    let id: Int?
    let bookType: String?
    let type: String?
    let studentBookId: Int?
    let title: String?
    let revision: String?
    let schoolType: String?
    let grade: String?
    let autoScorable: Bool?
    let accessModifierToStudent: String?
    let status: String?
    let totalCount: Int?
    let assignedCount: Int?
    let solvedCount: Int?
    let score: Int?
    let updateDateTime: String?
    let openDatetime: String?
    let scoreDatetime: String?
    let homeworks: [String]? // or [Homework]? if you have homework struct
    let semester: String?
}

// MARK: - Problem Codable
struct ProblemListResponse: Codable {
    let data: ProblemListData?
    let code: String?
    let message: String?
}

struct ProblemListData: Codable {
    let content: [ProblemItem]?
    let pageable: Pageable?
    let first: Bool?
    let sort: Sort?
    let numberOfElements: Int?
    let last: Bool?
    let size: Int?
    let number: Int?
    let empty: Bool?
}

struct ProblemItem: Codable {
    let worksheetProblemId: Int?
    let result: String?
    let userAnswer: String?
    let problem: Problem?
    let handwrittenNoteUrl: String?
    let conceptHidden: Bool?
}

struct Problem: Codable {
    let id: Int?
    let conceptId: Int?
    let groupCode: Int?
    let topicId: Int?
    let subTopicId: Int?
    let groupCase: String?
    let type: String?
    let optionCount: Int?
    let level: Int?
    let levelOfConceptChip: String?
    let problemImageUrl: String?
    let answerImageUrl: String?
    let solutionImageUrl: String?
    let answer: String?
    let answerUnits: [AnswerUnit]?
    let autoScoredType: String?
    let autoScored: Bool?
    let keypadTypes: [String]?
    let hidden: Bool?
    let trendy: Bool?
    let sample: Bool?
    let problemSummary: ProblemSummary?
    let video: Video?
    let index: Int?
    let favorite: Bool?
    let conceptName: String?
    let tagTop: String?
}

struct AnswerUnit: Codable {
    let unit: String?
    let index: Int?
}

struct ProblemSummary: Codable {
    let problemId: Int?
    let totalUsed: Int?
    let correctTimes: Int?
    let wrongTimes: Int?
    let answerRate: Int? // or Double if needed decimal point. example is integer in json
}

struct Video: Codable {
    let id: Int?
    let title: String?
    let thumbnailUrl: String?
    let videoUrl: String?
    let subtitleUrl: String?
}

struct Pageable: Codable {
    let sort: Sort?
    let pageNumber: Int?
    let pageSize: Int?
    let offset: Int?
    let unpaged: Bool?
    let paged: Bool?
}

struct Sort: Codable {
    let sorted: Bool?
    let unsorted: Bool?
    let empty: Bool?
}

// MARK: - SubmitProblem
struct SubmitProblem: Codable {
    let worksheetProblemId: Int
    let unknown: Bool
    let userAnswer: String
}

//struct ProblemListResponse: Codable {
//    let data: ProblemListDataContainer
//}
//
//struct ProblemListDataContainer: Codable {
//    let content: [ProblemListContentItem]
//}
//
//struct ProblemListContentItem: Codable {
//    let worksheetProblemId: Int
//    let result: String
//    let userAnswer: String
//    let problem: Problem
//    let handwrittenNoteUrl: String?
//    let conceptHidden: Bool
//}
//
//struct Problem: Codable {
//    let id: Int
//    let conceptId: Int
//    let groupCode: Int
//    let topicId: Int
//    let subTopicId: Int
//    let groupCase: String
//    let type: String
//    let optionCount: Int
//    let level: Int
//    let levelOfConceptChip: String
//    let problemImageUrl: String
//    let answerImageUrl: String
//    let solutionImageUrl: String
//    let answer: String
//    let answerUnits: [AnswerUnit]
//    let autoScoredType: String
//    let autoScored: Bool
//    let keypadTypes: [String]
//    let hidden: Bool
//    let trendy: Bool
//    let sample: Bool
//    let problemSummary: ProblemSummary
//    let video: Video
//    let index: Int
//    let favorite: Bool
//    let conceptName: String
//    let tagTop: String
//}
//
//struct AnswerUnit: Codable {
//    let unit: String
//    let index: Int
//}
//
//struct ProblemSummary: Codable {
//    let problemId: Int
//    let totalUsed: Int
//    let correctTimes: Int
//    let wrongTimes: Int
//    let answerRate: Int
//}
//
//struct Video: Codable {
//    let id: Int
//    let title: String
//    let thumbnailUrl: String
//    let videoUrl: String
//    let subtitleUrl: String
//}
