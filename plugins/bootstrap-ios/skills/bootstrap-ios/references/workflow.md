# Workflow

## 1. Detect the Apple surface

Look for:

- `*.xcodeproj`, `*.xcworkspace`
- `Package.swift`
- `project.yml`, `tuist/`, `Tuist.swift`
- `Podfile`
- `Info.plist`
- `*.swift`, `*.entitlements`, `*.xcdatamodeld`
- iOS markers: `.iOS(...)`, `platform :ios`, `UIDeviceFamily`, `ios/`
- macOS markers: `.macOS(...)`, AppKit imports, `.app`, `LSMinimumSystemVersion`

Record:

- platform(s): iOS, iPadOS, macOS, watchOS, visionOS, mixed
- project system: Xcode, SwiftPM, Tuist, XcodeGen, CocoaPods
- scheme(s)
- deployment target
- test framework: Swift Testing, XCTest, both, none
- data layer: SwiftData, Core Data, files, network, unknown
- build entry point: XcodeBuildMCP, Makefile, package command, raw xcodebuild

## 2. Load only the needed references

Use `skill-map.md` as the menu. Do not load every linked skill or rule file.
Choose by task:

- UI work -> SwiftUI skill pack(s)
- async/concurrency -> concurrency pack(s)
- tests -> testing pack(s)
- persistence -> SwiftData or Core Data
- slow build/project config -> Xcode Build Optimization
- architecture/refactor -> Merowing rules plus relevant SwiftUI/concurrency refs
- simulator/build/debug -> XcodeBuildMCP

## 3. Establish build truth

Before editing, find the fastest reliable command:

1. Existing `Makefile` target if present.
2. XcodeBuildMCP project/workspace discovery and build/test tools.
3. Existing README command.
4. Raw `xcodebuild` only if no cleaner path exists.

Prefer warnings-as-errors if the repo already enforces it. Do not add that policy
to someone else's repo unless asked.

## 4. Edit with Apple-platform discipline

- Prefer modern APIs for the deployment target.
- Respect existing architecture and naming.
- Keep SwiftUI views small and extract only when it improves clarity.
- Avoid force unwraps except where local style clearly allows them.
- Keep main-actor/UI mutations explicit.
- Preserve accessibility labels, previews, tests, and localization patterns.

## 5. Verify

Minimum verification by task:

- Small Swift change: targeted build.
- UI change: build plus simulator run/screenshot when feasible.
- Test change: targeted test run.
- Concurrency/refactor: build plus targeted tests.
- Persistence migration: build plus migration/test path if present.

If blocked, report the exact blocker and the closest command/tool output.
