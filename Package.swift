// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "Numeric",
    platforms: [
        .macOS(.v14)
    ],
    products: [
        .executable(name: "Numeric", targets: ["Numeric"])
    ],
    targets: [
        .executableTarget(
            name: "Numeric",
            path: "Sources/Numeric"
        ),
        .testTarget(
            name: "NumericTests",
            dependencies: ["Numeric"],
            path: "Tests/NumericTests"
        )
    ]
)
