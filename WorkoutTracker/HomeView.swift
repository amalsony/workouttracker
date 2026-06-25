//
//  HomeView.swift
//  WorkoutTracker
//
//  Created by Amal Sony on 6/18/26.
//

import SwiftUI
import SwiftData

struct HomeView: View {
    @AppStorage("userName") private var userName = ""
    @Query(sort: \Workout.date, order: .reverse) private var workouts: [Workout]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(greeting + (userName.isEmpty ? "" : (", " + userName)))
                            .font(.title2.bold())
                    }
                    .padding(.top, 8)

                     StreakCalendarView(workouts: workouts)

                    Spacer(minLength: 0)
                }
                .padding()
            }
        }
    }

    private var greeting: String {
        switch Calendar.current.component(.hour, from: .now) {
        case 5..<12:  "Good morning"
        case 12..<17: "Good afternoon"
        case 17..<22: "Good evening"
        default:      "Good night"
        }
    }
}
