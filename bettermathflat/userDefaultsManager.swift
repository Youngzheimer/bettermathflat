//
//  UserDataManager.swift
//  bettermathflat
//
//  Created by youngzheimer on 2/24/25.
//

import Foundation
import PencilKit

func getUserData() -> UserData? {
    if let savedUser = UserDefaults.standard.data(forKey: "userData") {
        let decoder = JSONDecoder()
        if let loadedUser = try? decoder.decode(UserData.self, from: savedUser) {
            return loadedUser
        }
    }
    return nil
}

func saveUserData(data: UserData) {
    let encoder = JSONEncoder()
    if let encoded = try? encoder.encode(data) {
        UserDefaults.standard.set(encoded, forKey: "userData")
    }
}

func saveDrawing(drawing: PKDrawing, studentBookId: String, problemIndex: Int) {
    print("saving Drawing Data for \(problemIndex)")
    let drawingData = drawing.dataRepresentation()
    UserDefaults.standard.set(drawingData, forKey: "drawing-\(studentBookId)-\(problemIndex)")
}

func loadDrawing(studentBookId: String, problemIndex: Int) -> PKDrawing? {
    print("loading Drawing Data for \(problemIndex)")
    if let data = UserDefaults.standard.data(forKey: "drawing-\(studentBookId)-\(problemIndex)") {
        let loadedDrawing = try? PKDrawing(data: data)
        print("done")
        return loadedDrawing
    }
    print("no data nigga")
    return nil
}

func saveUserAnswer(answer: String, studentBookId: String, problemIndex: Int, idk: Bool, submited: Bool) {
    print("saveing answer \(problemIndex)")
    let savedAnswer = loadUserAnswer(studentBookId: studentBookId)
    let encoder = JSONEncoder()
    var data: [UserAnswer] = []
    if let savedAnswer = savedAnswer {
        data = savedAnswer.filter { $0.problemIndex != problemIndex }
        data.append(UserAnswer(problemIndex: problemIndex, answer: answer, idk: idk, submited: submited)) // 새로운 답변 추가
    } else {
        data = [UserAnswer(problemIndex: problemIndex, answer: answer, idk: idk, submited: submited)]
    }
    
    print(data)
    
    if let encoded = try? encoder.encode(data) {
        UserDefaults.standard.set(encoded, forKey: "userAnswer-\(studentBookId)")
    }
}

func loadUserAnswer(studentBookId: String) -> [UserAnswer]? {
    if let savedAnswer = UserDefaults.standard.data(forKey: "userAnswer-\(studentBookId)") {
        let decoder = JSONDecoder()
        if let loadedAnswers = try? decoder.decode([UserAnswer].self, from: savedAnswer) {
            return loadedAnswers
        }
    }
    return nil
}

func loadIndvUserAnswer(studentBookId: String, problemIndex: Int) -> UserAnswer? {
    if let savedAnswer = UserDefaults.standard.data(forKey: "userAnswer-\(studentBookId)") {
        let decoder = JSONDecoder()
        if let loadedAnswers = try? decoder.decode([UserAnswer].self, from: savedAnswer) {
            for (_, value) in loadedAnswers.enumerated() {
                if value.problemIndex == problemIndex {
                    return value
                }
            }
            return nil
        }
    }
    return nil
}

struct UserAnswer: Codable {
    var problemIndex: Int
    var answer: String
    var idk: Bool
    var submited: Bool
}
