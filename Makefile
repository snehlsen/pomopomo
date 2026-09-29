export DEVELOPER_DIR ?= /Applications/Xcode.app/Contents/Developer

.PHONY: test project app run icon

test:
	swift test --package-path PomopomoCore

project:
	xcodegen generate

app: project
	xcodebuild -project Pomopomo.xcodeproj -scheme Pomopomo -configuration Release -derivedDataPath build build
	@# xcodebuild leaves the bundle's own date alone, and macOS keys its icon cache on it.
	touch build/Build/Products/Release/Pomopomo.app
	/System/Library/Frameworks/CoreServices.framework/Frameworks/LaunchServices.framework/Support/lsregister -f build/Build/Products/Release/Pomopomo.app
	@echo "Built build/Build/Products/Release/Pomopomo.app"

run: app
	open build/Build/Products/Release/Pomopomo.app

icon:
	swift tools/make-icon.swift App/Assets.xcassets/AppIcon.appiconset
