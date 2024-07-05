Pod::Spec.new do |spec|
  spec.name         = "OpenTelemetryProtocolExporterCommon"
  spec.version      = "1.9.3-beta"
  spec.summary      = "opentelemetry-swift OpenTelemetryProtocolExporterCommon SDK for iOS"
  spec.description  = <<-DESC
  OpenTelemetry iOS OpenTelemetryProtocolExporterCommon SDK distributed via Cocoapods
                   DESC

  spec.homepage     = "https://opentelemetry.io"
  spec.license      = "Apache-2.0"
  spec.author       = 'OpenTelemetry'

  spec.source       = { :git => "https://github.com/shopify/opentelemetry-swift.git", :tag => "#{spec.version}" }
  spec.swift_version = '5.2'
  spec.platform         = :ios, '11.0'

  spec.source_files = 'Sources/Exporters/OpenTelemetryProtocolCommon/**/*.swift'

  spec.dependency 'OpenTelemetrySdk', "#{spec.version}"
  spec.dependency 'SwiftProtobuf', "1.20.2"
	spec.vendored_frameworks = 'Vendor/Logging.xcframework'

end