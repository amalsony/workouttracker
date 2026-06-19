//
//  SettingsView.swift
//  WorkoutTracker
//
//  Created by Amal Sony on 6/17/26.
//

import SwiftUI

struct ProfileView: View {
    var body: some View {
        NavigationStack {
            List {
                Section("General") {
                    Text("Settings coming soon")
                        .foregroundStyle(.secondary)
                }
            }
            .navigationTitle("Profile & Settings")
        }
    }
}

#Preview {
    ProfileView()
}
