//
//  TrHealthKitQueryWorkout.swift
//  Travaartje
//
//  Created by Berrie Kremers on 18-07-20.
//  Copyright © 2020 Katoemba Software. All rights reserved.
//

import Foundation
import HealthKit
import CoreLocation
import Combine

/// Relevant data from a HKWorkout including samples
public struct WorkoutDetails {
    /// The actual workout
    public let workout: HKWorkout
    /// A sorted array of location samples, across all HKWorkoutRoutes that are part of the workout
    public let locationSamples: [CLLocation]
    /// A sorted array of heartrate samples taken during the workout
    public let heartRateSamples: [HKQuantitySample]
    
    public init(workout: HKWorkout, locationSamples: [CLLocation], heartRateSamples: [HKQuantitySample]) {
        self.workout = workout
        self.locationSamples = locationSamples
        self.heartRateSamples = heartRateSamples
    }
}

public struct HealthKitCombineError: Error {
    public enum ErrorKind {
        case notAvailableOnDevice
        case dataTypeNotAvailable
        case noDataFound
        case noRoutePointsFound
    }
    
    public let kind: ErrorKind
    public let errorCode: String
    
    public init(kind: ErrorKind, errorCode: String) {
        self.kind = kind
        self.errorCode = errorCode
    }
}

extension HealthKitCombineError: LocalizedError {
    public var errorDescription: String? {
        switch self.kind {
        case .notAvailableOnDevice:
            return NSLocalizedString("HealthKit data not available on this device.", comment: "")
        case .dataTypeNotAvailable:
            return NSLocalizedString("Datatype not available.", comment: "")
        case .noDataFound:
            return NSLocalizedString("No data found for workout.", comment: "")
        case .noRoutePointsFound:
            return NSLocalizedString("No gps route found.", comment: "")
        }
    }
}

public protocol HKHealthStoreCombine {
    func shouldAuthorize() -> AnyPublisher<Bool, Error>
    func authorize() -> AnyPublisher<Bool, Error>
    func workouts(_ limit: Int) -> AnyPublisher<[HKWorkout], Error>
    func workouts(_ ids: [UUID]) -> AnyPublisher<[HKWorkout], Error>
    func workout(_ id: UUID) -> AnyPublisher<HKWorkout, Error>
    func workoutDetails(_ workout: HKWorkout) -> AnyPublisher<WorkoutDetails, Error>
}

extension HKHealthStore: HKHealthStoreCombine {
    public func shouldAuthorize() -> AnyPublisher<Bool, Error> {
        let subject = PassthroughSubject<Bool, Error>()
        let callback: (HKAuthorizationRequestStatus, Error?) -> Swift.Void = {
            result, error in
            if let error = error {
                subject.send(completion: .failure(error))
            }
            else {
                subject.send(result == .shouldRequest)
                subject.send(completion: .finished)
            }
        }
        
        if !HKHealthStore.isHealthDataAvailable() {
            callback(.unknown, HealthKitCombineError.init(kind: .notAvailableOnDevice, errorCode: "Not available on device"))
        }
        else {
            var healthKitTypesToRead: Set<HKObjectType> = [HKObjectType.workoutType(),
                                                           HKSeriesType.workoutRoute()]
            if let heartRateQuantityType = HKQuantityType.quantityType(forIdentifier: .heartRate) {
                healthKitTypesToRead.insert(heartRateQuantityType)
            }
            
            self.getRequestStatusForAuthorization(toShare: Set<HKSampleType>(),
                                                  read: healthKitTypesToRead) { (result, error) in
                                                    callback(result, error)
            }
        }
        
        return subject.eraseToAnyPublisher()
    }
    
    public func authorize() -> AnyPublisher<Bool, Error> {
        let subject = PassthroughSubject<Bool, Error>()
        let callback: (Bool, Error?) -> Swift.Void = {
            result, error in
            if let error = error {
                subject.send(completion: .failure(error))
            }
            else {
                subject.send(result)
                subject.send(completion: .finished)
            }
        }
        
        if !HKHealthStore.isHealthDataAvailable() {
            callback(false, HealthKitCombineError.init(kind: .notAvailableOnDevice, errorCode: "Not available on device"))
        }
        else {
            var healthKitTypesToRead: Set<HKObjectType> = [HKObjectType.workoutType(),
                                                           HKSeriesType.workoutRoute()]
            if let heartRateQuantityType = HKQuantityType.quantityType(forIdentifier: .heartRate) {
                healthKitTypesToRead.insert(heartRateQuantityType)
            }
            
            self.requestAuthorization(toShare: nil,
                                      read: healthKitTypesToRead) { (result, error) in
                                        callback(result, error)
            }
        }
        
        return subject.eraseToAnyPublisher()
    }
    
    public func workouts(_ limit: Int) -> AnyPublisher<[HKWorkout], Error> {
        let subject = PassthroughSubject<[HKWorkout], Error>()
        
        let workoutPredicate = NSCompoundPredicate(orPredicateWithSubpredicates: [HKQuery.predicateForWorkouts(with: .running),
                                                                                  HKQuery.predicateForWorkouts(with: .cycling),
                                                                                  HKQuery.predicateForWorkouts(with: .hiking),
                                                                                  HKQuery.predicateForWorkouts(with: .swimming),
                                                                                  HKQuery.predicateForWorkouts(with: .walking),
                                                                                  HKQuery.predicateForWorkouts(with: .rowing)])
        
        let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierEndDate,
                                              ascending: false)
        
        let query = HKSampleQuery(sampleType: HKObjectType.workoutType(),
                                  predicate: workoutPredicate,
                                  limit: limit,
                                  sortDescriptors: [sortDescriptor]) { (query, samples, error) in
                                    DispatchQueue.main.async {
                                        guard error == nil else {
                                            subject.send(completion: .failure(error!))
                                            return
                                        }
                                        guard let workouts = samples as? [HKWorkout] else {
                                            subject.send(completion: .failure(HealthKitCombineError.init(kind: .noDataFound, errorCode: "No workouts found")))
                                            return
                                        }
                                        
                                        subject.send(workouts)
                                        subject.send(completion: .finished)
                                    }
        }
        
        self.execute(query)
        
        return subject.eraseToAnyPublisher()
    }
    
    private func workoutsSubject(_ ids: [UUID]) -> PassthroughSubject<[HKWorkout], Error> {
        let subject = PassthroughSubject<[HKWorkout], Error>()
        
        let workoutPredicate = NSCompoundPredicate(orPredicateWithSubpredicates: [HKQuery.predicateForObjects(with: Set(ids))])
        
        let query = HKSampleQuery(sampleType: HKObjectType.workoutType(),
                                  predicate: workoutPredicate,
                                  limit: 0,
                                  sortDescriptors: []) { (query, samples, error) in
                                    DispatchQueue.main.async {
                                        guard error == nil else {
                                            subject.send(completion: .failure(error!))
                                            return
                                        }
                                        guard let workouts = samples as? [HKWorkout], workouts.count > 0 else {
                                            subject.send(completion: .failure(HealthKitCombineError.init(kind: .noDataFound, errorCode: "No workouts found")))
                                            return
                                        }
                                        
                                        subject.send(workouts)
                                        subject.send(completion: .finished)
                                    }
        }
        
        self.execute(query)
        
        return subject
    }
    
    public func workouts(_ ids: [UUID]) -> AnyPublisher<[HKWorkout], Error> {
        workoutsSubject(ids)
            .eraseToAnyPublisher()
    }
    
    public func workout(_ id: UUID) -> AnyPublisher<HKWorkout, Error> {
        workoutsSubject([id])
            .filter({ (workouts) -> Bool in
                workouts.count > 0
            })
            .tryMap({ (workouts) -> HKWorkout in
                guard workouts.count > 0 else { throw HealthKitCombineError(kind: .noDataFound, errorCode: "Workout with id \(id) not found") }
                return workouts[0]
            })
            .eraseToAnyPublisher()
    }
    
    public func workoutDetails(_ workout: HKWorkout) -> AnyPublisher<WorkoutDetails, Error> {
        return workout.workoutWithDetails
    }
}

extension HKWorkout {
    /// Get a workout together with workout route samples
    public var workoutWithDetails: AnyPublisher<WorkoutDetails, Error> {
        let locationSamplesPublisher = workoutRouteSubject
            .flatMap({ (workoutRoute) -> PassthroughSubject<[CLLocation], Error> in
                workoutRoute.locationsSubject
            })
            .replaceEmpty(with: [])
            .scan([], { (locations, newLocations) -> [CLLocation] in
                locations + newLocations
            })
            .last()
            .map({ (locationSamples) -> [CLLocation] in
                locationSamples.sorted(by: { (loc1, loc2) -> Bool in
                    loc1.timestamp <= loc2.timestamp
                })
            })
        
        return Publishers.CombineLatest(locationSamplesPublisher, heartRateSampleSubject)
            .map({ (locationSamples, heartRateSamples) -> WorkoutDetails in
                WorkoutDetails(workout: self,
                               locationSamples: locationSamples,
                               heartRateSamples: heartRateSamples)
            })
            .eraseToAnyPublisher()
    }
    
    private var workoutRouteSubject: PassthroughSubject<HKWorkoutRoute, Error> {
        let subject = PassthroughSubject<HKWorkoutRoute, Error>()
        
        let workoutPredicate = HKQuery.predicateForObjects(from: self)
        let query = HKSampleQuery(sampleType: HKSeriesType.workoutRoute(),
                                  predicate: workoutPredicate,
                                  limit: HKObjectQueryNoLimit,
                                  sortDescriptors: nil) { (query, workoutRoutes, error) in
                                    guard let workoutRoutes = workoutRoutes as? [HKWorkoutRoute],
                                        error == nil else {
                                            subject.send(completion: .failure(error!))
                                            return
                                    }
                                    
                                    for workoutRoute in workoutRoutes {
                                        subject.send(workoutRoute)
                                    }
                                    subject.send(completion: .finished)
        }
        
        HKHealthStore().execute(query)
        
        return subject
    }
    
    private var heartRateSampleSubject: AnyPublisher<[HKQuantitySample], Error> {
        let subject = PassthroughSubject<[HKQuantitySample], Error>()
        
        let heartRateType = HKQuantityType.quantityType(forIdentifier: HKQuantityTypeIdentifier.heartRate)!
        let workoutPredicate = HKQuery.predicateForSamples(withStart: startDate, end: endDate)
        let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierEndDate,
                                              ascending: true)
        
        let query = HKSampleQuery(sampleType: heartRateType,
                                  predicate: workoutPredicate,
                                  limit: HKObjectQueryNoLimit,
                                  sortDescriptors: [sortDescriptor]) { (query, samples, error) in
                                    let quantitySamples = samples as? [HKQuantitySample] ?? []
                                    subject.send(quantitySamples)
                                    subject.send(completion: .finished)
        }
        
        HKHealthStore().execute(query)
        
        // In case there was a problem getting the heart rates, just return an empty array.
        return subject.eraseToAnyPublisher()
    }
}

private extension HKWorkoutRoute {
    /// Get all location samples for a workout route.
    var locationsSubject: PassthroughSubject<[CLLocation], Error> {
        let subject = PassthroughSubject<[CLLocation], Error>()
        var workoutLocations = Array<CLLocation>()
        
        let query = HKWorkoutRouteQuery(route: self) { (routeQuery, locations, done, error) in
            guard error == nil else {
                subject.send(completion: .failure(error!))
                return
            }
            guard let locations = locations else {
                subject.send(completion: .failure(HealthKitCombineError.init(kind: .noRoutePointsFound, errorCode: "No routepoints found")))
                return
            }
            
            workoutLocations.append(contentsOf: locations)
            if done {
                subject.send(workoutLocations)
                subject.send(completion: .finished)
            }
        }
        HKHealthStore().execute(query)
        
        return subject
    }
}
