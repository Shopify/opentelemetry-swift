Pod::Spec.new do |spec|
  spec.name         = "OpenTelemetryApi"
  spec.version      = "1.9.3-beta"
  spec.summary      = "opentelemetry-swift OpenTelemetryApi SDK for iOS"
  spec.description  = <<-DESC
  OpenTelemetry iOS OpenTelemetryApi SDK distributed via Cocoapods
                   DESC

  spec.homepage     = "https://opentelemetry.io"
  spec.license      = "Apache-2.0"
  spec.author       = 'OpenTelemetry'

  spec.source       = { :git => "https://github.com/shopify/opentelemetry-swift.git", :tag => "#{spec.version}" }
  spec.swift_version = '5.2'
  spec.platform         = :ios, '11.0'

  spec.source_files = 'Sources/OpenTelemetryApi/**/*.swift'
end