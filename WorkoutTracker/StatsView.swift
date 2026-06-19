//
//  StatsView.swift
//  WorkoutTracker
//
//  Created by Amal Sony on 6/17/26.
//

import SwiftUI

struct StatsView: View {
    var body: some View {
        NavigationStack {
            ContentUnavailableView(
                "Progress Coming Soon",
                systemImage: "chart.line.upward.xyaxis",
                description: Text("Charts and stats about your workouts will live here.")
            )
            .navigationTitle("Progress")
        }
    }
}

#Preview {
    StatsView()
}
