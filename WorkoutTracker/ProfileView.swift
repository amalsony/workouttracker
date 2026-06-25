//
//  SettingsView.swift
//  WorkoutTracker
//
//  Created by Amal Sony on 6/17/26.
//

import SwiftUI

struct ProfileView: View {
    @AppStorage("userName") private var userName = ""

    var body: some View {
        NavigationStack {
            Form {
                Section("Your Name") {
                    TextField("Enter your name", text: $userName)
                        .textInputAutocapitalization(.words)
                }
            }
            .navigationTitle("Profile")
            .navigationBarTitleDisplayMode(.inline)   // smaller title, per your note
        }
    }
}
