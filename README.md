[![bitrise CI](https://img.shields.io/bitrise/d9182b6e1f480313?token=jIwLDgiM2T_3-S9J7dxZJg)](https://bitrise.io)
![platforms](https://img.shields.io/badge/platforms-iOS-lightgrey)
[![Swift Package Manager compatible](https://img.shields.io/badge/Swift%20Package%20Manager-compatible-brightgreen.svg)](https://github.com/apple/swift-package-manager)

# HealthKitCombine

HealthKitCombine is a library that makes HealthKit functions for retrieving workouts via Swift Combine publishers. This makes it easy to integrate
HealthKit into a SwiftUI application. This library is used in Travaartje: https://travaartje.net.

## How to use

See https://github.com/katoemba/travaartje for examples how this library can be used.

## Requirements

* iOS 13, watchOS 6
* Swift 5.1

## Installation

Build and usage via swift package manager is supported:

### [Swift Package Manager](https://github.com/apple/swift-package-manager)

The easiest way to add the library is directly from within XCode (11). Alternatively you can create a `Package.swift` file. 

```swift
// swift-tools-version:5.0

import PackageDescription

let package = Package(
  name: "MyProject",
  dependencies: [
  .package(url: "https://github.com/katoemba/healthkitcombine.git", from: "1.0.0")
  ],
  targets: [
    .target(name: "MyProject", dependencies: ["HealthKitCombine"])
  ]
)
```

## Testing ##

There are no unit tests, as this would require extensive mocking of HealthKit which doesn't seem worth the trouble.

## Who do I talk to? ##

* In case of questions you can contact berrie at travaartje dot net
