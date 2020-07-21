import XCTest
@testable import TrWorkout
import HealthKit

final class TrWorkoutModelTests: XCTestCase {
    func testModel() {
        let runDate = DateComponents(calendar: Calendar.current, timeZone: TimeZone(abbreviation: "CEST"), year: 2020, month: 5, day: 17, hour: 14, minute: 7, second: 58).date!
        let rideDate = DateComponents(calendar: Calendar.current, timeZone: TimeZone(abbreviation: "CEST"), year: 2020, month: 5, day: 17, hour: 08, minute: 58, second: 23).date!
        let workouts: [HKWorkout] = [HKWorkout(activityType: .running, start: runDate, end: runDate.addingTimeInterval(4040), workoutEvents: nil, totalEnergyBurned: nil, totalDistance: HKQuantity(unit: .meter(), doubleValue: 8765.9), metadata: nil),
                                     HKWorkout(activityType: .cycling, start: rideDate, end: rideDate.addingTimeInterval(1000), workoutEvents: nil, totalEnergyBurned: nil, totalDistance: HKQuantity(unit: .meter(), doubleValue: 5609.0), metadata: nil)]
        
        let model = TrWorkoutModel(workouts)
        _ = model.$workouts
            .sink { (workouts) in
                XCTAssertEqual(workouts.count, 2)
                
                let run = workouts[0]
                XCTAssertEqual(run.state, .new)
                XCTAssertEqual(run.type, "Run")
                XCTAssertEqual(run.distance, "8.8 km")
                XCTAssertEqual(run.duration, "1:07:20")
                XCTAssertEqual(run.date, "17 mei 2020 14:07")

                let ride = workouts[1]
                XCTAssertEqual(ride.state, .new)
                XCTAssertEqual(ride.type, "Ride")
                XCTAssertEqual(ride.distance, "5.6 km")
                XCTAssertEqual(ride.duration, "16:40")
                XCTAssertEqual(ride.date, "17 mei 2020 08:58")
        }
    }
    
    static var allTests = [
        ("testModel", testModel),
    ]
}
