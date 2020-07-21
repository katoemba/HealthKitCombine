//
//  TrWorkout.swift
//
//
//  Created by Berrie Kremers on 19/07/2020.
//

import Foundation
import Combine
import HealthKit

public class TrWorkout: Identifiable, ObservableObject {
    public enum State: String {
        case new = "New"
        case uploaded = "Uploaded"
        case failed = "Failed"
    }
    
    public var id: UUID {
        workout.uuid
    }
    public let workout: HKWorkout
    @Published public var state = State.new
    @Published public var name = ""
    @Published public var description = ""
    @Published public var commute = false
    public var type: String {
        switch workout.workoutActivityType {
        case .running:
            return "Run"
        case .swimming:
            return "Swim"
        case .cycling:
            return "Ride"
        default:
            return "Other"
        }
    }
    public var date: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        formatter.doesRelativeDateFormatting = true

        return formatter.string(from: workout.startDate)
    }
    public var distance: String {
        let km = workout.totalDistance?.doubleValue(for: .meterUnit(with: .kilo)) ?? 0.0
        return String(format: "%.1f km", km)
    }
    public var duration: String {
        let hours = Int(workout.duration / 3600.0)
        let minutes = Int((workout.duration - Double(hours) * 3600.0) / 60.0)
        let seconds = Int(workout.duration - Double(hours) * 3600.0 - Double(minutes) * 60.0)
        
        if hours > 0 {
            return String(format: "%d:%02d:%02d", hours, minutes, seconds)
        }
        else {
            return String(format: "%02d:%02d", minutes, seconds)
        }
    }
    
    init(state: State = .new, workout: HKWorkout) {
        self.state = state
        self.workout = workout
    }
}
