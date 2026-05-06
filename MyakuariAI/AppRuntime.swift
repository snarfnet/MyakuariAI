import Foundation

enum AppRuntime {
    static var isScreenshotRun: Bool {
        ProcessInfo.processInfo.arguments.contains("-screenshots")
    }

    static var screenshotScreen: String {
        guard let index = ProcessInfo.processInfo.arguments.firstIndex(of: "-screenshotScreen"),
              ProcessInfo.processInfo.arguments.indices.contains(index + 1) else {
            return "home"
        }
        return ProcessInfo.processInfo.arguments[index + 1]
    }
}
