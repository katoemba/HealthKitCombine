import XCTest
@testable import TrWorkout
import HealthKit

final class TrWorkoutModelTests: XCTestCase {
    func testModel() {
        let runDate = DateComponents(calendar: Calendar.current, timeZone: TimeZone.current, year: 2020, month: 5, day: 17, hour: 14, minute: 7, second: 23).date!
        let rideDate = DateComponents(calendar: Calendar.current, timeZone: TimeZone.current, year: 2020, month: 5, day: 17, hour: 08, minute: 58, second: 23).date!
        let workouts: [HKWorkout] = [HKWorkout(activityType: .running, start: runDate, end: runDate.addingTimeInterval(2000), workoutEvents: nil, totalEnergyBurned: nil, totalDistance: HKQuantity(unit: .meter(), doubleValue: 8765.9), metadata: nil),
                                     HKWorkout(activityType: .cycling, start: rideDate, end: rideDate.addingTimeInterval(1000), workoutEvents: nil, totalEnergyBurned: nil, totalDistance: HKQuantity(unit: .meter(), doubleValue: 5609.0), metadata: nil)]
        
        let model = TrWorkoutModel(workouts)
        _ = model.$workouts
            .sink { (workouts) in
                XCTAssert(workouts.count == 2, "Expected 2 workouts, got \(workouts.count)")
                
                let run = workouts[0]
                XCTAssertEqual(run.state, .new)
                XCTAssertEqual(run.type, "Run")
                XCTAssertEqual(run.distance, "8.8 km")
                XCTAssertEqual(run.duration, "33:20")
                XCTAssertEqual(run.date, "May 17, 2020 at 2:07 PM")

                let ride = workouts[1]
                XCTAssertEqual(ride.state, .new)
                XCTAssertEqual(ride.type, "Ride")
                XCTAssertEqual(ride.distance, "5.6 km")
                XCTAssertEqual(ride.duration, "16:40")
                XCTAssertEqual(ride.date, "May 17, 2020 at 8:58 AM")
        }
    }
    
    static var allTests = [
        ("testModel", testModel),
    ]
}
