import GoogleMobileAds
import SwiftUI

class InterstitialAdManager: NSObject, ObservableObject, GADFullScreenContentDelegate {
    @Published var isReady = false
    private var interstitial: GADInterstitialAd?
    private let adUnitID: String

    init(adUnitID: String = "ca-app-pub-9404799280370656/1324458051") {
        self.adUnitID = adUnitID
        super.init()
        loadAd()
    }

    func loadAd() {
        GADInterstitialAd.load(withAdUnitID: adUnitID, request: GADRequest()) { [weak self] ad, error in
            if let ad = ad {
                self?.interstitial = ad
                self?.interstitial?.fullScreenContentDelegate = self
                self?.isReady = true
            }
        }
    }

    func showAd() {
        guard let ad = interstitial,
              let root = UIApplication.shared.connectedScenes
                .compactMap({ $0 as? UIWindowScene })
                .flatMap({ $0.windows })
                .first(where: { $0.isKeyWindow })?.rootViewController else {
            return
        }
        ad.present(fromRootViewController: root)
    }

    func ad(_ ad: GADFullScreenPresentingAd, didFailToPresentFullScreenContentWithError error: Error) {
        isReady = false
        loadAd()
    }

    func adDidDismissFullScreenContent(_ ad: GADFullScreenPresentingAd) {
        isReady = false
        loadAd()
    }
}
