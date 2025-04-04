// swift-tools-version:5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription
import Foundation

let package = Package(name: "opentelemetry-swift",
                      platforms: [
                        .macOS(.v12),
                        .iOS(.v13),
                        .tvOS(.v13),
                        .watchOS(.v5)
                      ],
                      products: [
                        .library(name: "OpenTelemetryApi", targets: ["OpenTelemetryApi"]),
                        .library(name: "OpenTelemetrySdk", targets: ["OpenTelemetrySdk"]),
                        .library(name: "OpenTelemetryProtocolExporterHTTP", targets: ["OpenTelemetryProtocolExporterHttp"]),
                        .library(name: "DataCompression", type: .static, targets: ["DataCompression"]),
                      ],
                      dependencies: [
                        .package(url: "https://github.com/apple/swift-protobuf.git", from: "1.20.2"),
                        .package(url: "https://github.com/apple/swift-log.git", from: "1.4.4"),
                        .package(url: "https://github.com/apple/swift-atomics.git", from: "1.2.0")
                      ],
                      targets: [
                        .target(name: "OpenTelemetryApi",
                                dependencies: []),
                        .target(name: "OpenTelemetrySdk",
                                dependencies: ["OpenTelemetryApi",
                                               .product(name: "Atomics", package: "swift-atomics", condition: .when(platforms: [.linux]))]),
                        .target(name: "OpenTelemetryProtocolExporterCommon",
                                dependencies: ["OpenTelemetrySdk",
                                               .product(name: "Logging", package: "swift-log"),
                                               .product(name: "SwiftProtobuf", package: "swift-protobuf")],
                                path: "Sources/Exporters/OpenTelemetryProtocolCommon"),
                        .target(name: "OpenTelemetryProtocolExporterHttp",
                                dependencies: ["OpenTelemetrySdk",
                                               "OpenTelemetryProtocolExporterCommon",
                                               "DataCompression"],
                                path: "Sources/Exporters/OpenTelemetryProtocolHttp"),
                        .target(name: "DataCompression",
                                dependencies: [],
                                path: "Sources/Exporters/DataCompression"),
                      ]).addPlatformSpecific()

extension Package {
  func addPlatformSpecific() -> Self {
    #if canImport(ObjectiveC)
      targets.append(contentsOf: [
      ])
    #endif

    #if canImport(Darwin)
      products.append(contentsOf: [
        .library(name: "ResourceExtension", targets: ["ResourceExtension"])
      ])
      targets.append(contentsOf: [
        .target(name: "ResourceExtension",
                dependencies: ["OpenTelemetrySdk"],
                path: "Sources/Instrumentation/SDKResourceExtension",
                exclude: ["README.md"]),
        .testTarget(name: "ResourceExtensionTests",
                    dependencies: ["ResourceExtension", "OpenTelemetrySdk"],
                    path: "Tests/InstrumentationTests/SDKResourceExtensionTests")
      ])
    #endif

    return self
  }
}
