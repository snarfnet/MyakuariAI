import SwiftUI
import GoogleMobileAds
import AppTrackingTransparency

@main
struct MyakuariAIApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
                .onAppear {
                    guard !AppRuntime.isScreenshotRun else { return }
                    GADMobileAds.sharedInstance().start(completionHandler: nil)
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                        ATTrackingManager.requestTrackingAuthorization { _ in }
                    }
                }
        }
    }
}
