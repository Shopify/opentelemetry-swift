PROJECT_NAME="opentelemetry-swift-Package"

XCODEBUILD_OPTIONS_IOS=\
	-configuration Debug \
	-destination platform='iOS Simulator,name=iPhone 14,OS=latest' \
	-scheme $(PROJECT_NAME) \
	-workspace .

XCODEBUILD_OPTIONS_TVOS=\
	-configuration Debug \
	-destination platform='tvOS Simulator,name=Apple TV 4K (3rd generation),OS=latest' \
	-scheme $(PROJECT_NAME) \
	-workspace .

XCODEBUILD_OPTIONS_WATCHOS=\
	-configuration Debug \
	-destination platform='watchOS Simulator,name=Apple Watch Series 8 (45mm),OS=latest' \
	-scheme $(PROJECT_NAME) \
	-workspace .

.PHONY: setup-brew
setup-brew:
	brew update && brew install xcbeautify

.PHONY: build-ios
build-ios:
	set -o pipefail && xcodebuild $(XCODEBUILD_OPTIONS_IOS) build | xcbeautify

.PHONY: build-tvos
build-tvos:
	set -o pipefail && xcodebuild $(XCODEBUILD_OPTIONS_TVOS) build | xcbeautify

.PHONY: build-watchos
build-watchos:
	set -o pipefail && xcodebuild $(XCODEBUILD_OPTIONS_IOS) build | xcbeautify

.PHONY: build-for-testing-ios
build-for-testing-ios:
	set -o pipefail && xcodebuild $(XCODEBUILD_OPTIONS_IOS) build-for-testing | xcbeautify

.PHONY: build-for-testing-tvos
build-for-testing-tvos:
	set -o pipefail && xcodebuild $(XCODEBUILD_OPTIONS_TVOS) build-for-testing | xcbeautify

.PHONY: build-for-testing-watchos
build-for-testing-watchos:
	set -o pipefail && xcodebuild $(XCODEBUILD_OPTIONS_WATCHOS) build-for-testing | xcbeautify

.PHONY: test-ios
test-ios:
	set -o pipefail && xcodebuild $(XCODEBUILD_OPTIONS_IOS) test | xcbeautify

.PHONY: test-tvos
test-tvos:
	set -o pipefail && xcodebuild $(XCODEBUILD_OPTIONS_TVOS) test | xcbeautify

.PHONY: test-watchos
test-watchos:
	set -o pipefail && xcodebuild $(XCODEBUILD_OPTIONS_WATCHOS) test | xcbeautify

.PHONY: test-without-building-ios
test-without-building-ios:
	set -o pipefail && xcodebuild $(XCODEBUILD_OPTIONS_IOS) test-without-building | xcbeautify

.PHONY: test-without-building-tvos
test-without-building-tvos:
	set -o pipefail && xcodebuild $(XCODEBUILD_OPTIONS_TVOS) test-without-building | xcbeautify

.PHONY: test-without-building-watchos
test-without-building-watchos:
	set -o pipefail && xcodebuild $(XCODEBUILD_OPTIONS_WATCHOS) test-without-building | xcbeautify

.PHONY: build-xcframework
build-xcframework:
	$(MAKE) clear-build ; \
	for target in Logging SwiftProtobuf OpenTelemetryApi OpenTelemetrySdk ResourceExtension OpenTelemetryProtocolExporterCommon OpenTelemetryProtocolExporterHttp ; do \
		$(MAKE) target=$$target build-sdk ; \
	done
	$(MAKE) clear-tmp ; \

.PHONY: build-sdk
build-sdk:
	xcodebuild -project opentelemetry-swift.xcodeproj archive -scheme $(target) -destination=iOS -archivePath tmp/archive/ios -derivedDataPath tmp/ios -sdk iphoneos SKIP_INSTALL=NO BUILD_LIBRARY_FOR_DISTRIBUTION=YES
	xcodebuild -project opentelemetry-swift.xcodeproj archive -scheme $(target) -destination="iOS Simulator" -archivePath tmp/archive/ios-sim -derivedDataPath tmp/ios-sim -sdk iphonesimulator SKIP_INSTALL=NO BUILD_LIBRARY_FOR_DISTRIBUTION=YES
	xcodebuild -project opentelemetry-swift.xcodeproj archive -scheme $(target) -destination=watchOS -archivePath tmp/archive/watchos -derivedDataPath tmp/watchos -sdk watchos SKIP_INSTALL=NO BUILD_LIBRARY_FOR_DISTRIBUTION=YES
	xcodebuild -project opentelemetry-swift.xcodeproj archive -scheme $(target) -destination="watchOS Simulator" -archivePath tmp/archive/watchos-sim -derivedDataPath tmp/watchos-sim -sdk watchsimulator SKIP_INSTALL=NO BUILD_LIBRARY_FOR_DISTRIBUTION=YES
	xcodebuild -create-xcframework \
		-framework tmp/archive/ios.xcarchive/Products/Library/Frameworks/$(target).framework -debug-symbols `pwd`/tmp/archive/ios.xcarchive/dSYMs/$(target).framework.dSYM \
		-framework tmp/archive/ios-sim.xcarchive/Products/Library/Frameworks/$(target).framework -debug-symbols `pwd`/tmp/archive/ios-sim.xcarchive/dSYMs/$(target).framework.dSYM \
		-framework tmp/archive/watchos.xcarchive/Products/Library/Frameworks/$(target).framework -debug-symbols `pwd`/tmp/archive/watchos.xcarchive/dSYMs/$(target).framework.dSYM \
		-framework tmp/archive/watchos-sim.xcarchive/Products/Library/Frameworks/$(target).framework -debug-symbols `pwd`/tmp/archive/watchos-sim.xcarchive/dSYMs/$(target).framework.dSYM \
		-output ./frameworks/$(target).xcframework

.PHONY: clear-tmp
clear-tmp:
	rm -rf ./tmp

.PHONY: clear-build
clear-build:
	rm -rf ./frameworks
