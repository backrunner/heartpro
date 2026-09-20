// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "HeartProCore",
    defaultLocalization: "en",
    platforms: [.iOS(.v18), .macOS(.v15)],
    products: [.library(name: "HeartProCore", targets: ["HeartProCore"])],
    targets: [
        .target(name: "HeartProCore", resources: [.process("Resources")]),
        .executableTarget(name: "ECGAudit", dependencies: ["HeartProCore"]),
        .testTarget(name: "HeartProCoreTests", dependencies: ["HeartProCore"])
    ]
)
