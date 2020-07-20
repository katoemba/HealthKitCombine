//
//  TrWorkoutModel.swift
//  
//
//  Created by Berrie Kremers on 19/07/2020.
//

import Foundation
import Combine
import HealthKit

public class TrWorkoutModel: ObservableObject {
    @Published public var workouts = [TrWorkout]()
    private var workoutCancellable: AnyCancellable?
    
    /// Initialize a workout model that will load the 10 latest workouts.
    /// - Parameter workouts: inject a predefined set of workouts for testing purposes.
    public init(_ workouts: [HKWorkout]? = nil) {
        var workoutPublisher: AnyPublisher<[HKWorkout], Error>
        let subject = PassthroughSubject<[HKWorkout], Error>()

        if workouts != nil {
            workoutPublisher = subject.eraseToAnyPublisher()
        }
        else {
            workoutPublisher = HKHealthStore().workouts(10)
        }

        workoutCancellable = workoutPublisher
            .replaceError(with: [])
            .map({ (workouts) -> [TrWorkout] in
                workouts.map { (workout) -> TrWorkout in
                    TrWorkout(state: .new, workout: workout)
                }
            })
            .assign(to: \.workouts, on: self)

        if let workouts = workouts {
            subject.send(workouts)
            subject.send(completion: .finished)
        }
    }
}
