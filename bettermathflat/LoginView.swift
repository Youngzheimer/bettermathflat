//
//  LoginView.swift
//  bettermathflat
//
//  Created by youngzheimer on 2/24/25.
//

import SwiftUI

struct LoginView: View {
    @State var phoneNumber = ""
    @State var password = ""
    
    var body: some View {
        VStack {
            Text("Better Mathflat")
                .bold()
                .font(.largeTitle)
                .padding()
            TextField("Please Enter Your Phone Number", text: $phoneNumber)
            SecureField("Please Enter Your password", text: $password)
            Button("Login") {
                login(phoneNumber: phoneNumber, password: password) { result in
                    switch result {
                    case .success(let responce):
                        print("Successed")
                        saveUserData(data: responce.data)
                        NotificationCenter.default.post(name: NSNotification.Name("LoginSuccess"), object: nil)
                    case .failure(let error):
                        print("Failed: \(error)")
                        Alert(title: Text("Failed To Login"), message: Text("\(error)"))
                    }
                }
            }
            .padding()
            .background(Color.blue.opacity(0.3))
        }
        .padding()
    }
}

#Preview {
    LoginView()
}
