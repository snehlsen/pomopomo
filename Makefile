export DEVELOPER_DIR ?= /Applications/Xcode.app/Contents/Developer

.PHONY: test project app run

test:
	swift test --package-path PomopomoCore

project:
	xcodegen generate

app: project
	xcodebuild -project Pomopomo.xcodeproj -scheme Pomopomo -configuration Release -derivedDataPath build build
	@echo "Built build/Build/Products/Release/Pomopomo.app"

run: app
	open build/Build/Products/Release/Pomopomo.app
