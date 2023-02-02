// Copyright 2022-2023 Chartboost, Inc.
//
// Use of this source code is governed by an MIT-style
// license that can be found in the LICENSE file.

import AdColony
import ChartboostMediationSDK
import Foundation

/// The Chartboost Mediation InMobi adapter fullscreen ad.
final class AdColonyAdapterFullscreenAd: AdColonyAdapterAd, PartnerAd {
    
    /// The partner ad view to display inline. E.g. a banner view.
    /// Should be nil for full-screen ads.
    var inlineView: UIView? { nil }
    
    /// AdColony's interstitial ad instance.
    private var ad: AdColonyInterstitial?
    
    /// Loads an ad.
    /// - parameter viewController: The view controller on which the ad will be presented on. Needed on load for some banners.
    /// - parameter completion: Closure to be performed once the ad has been loaded.
    func load(with viewController: UIViewController?, completion: @escaping (Result<PartnerEventDetails, Error>) -> Void) {
        log(.loadStarted)
        
        guard let bidPayload = request.adm, !bidPayload.isEmpty else {
            let error = error(.loadFailureInvalidAdMarkup)
            log(.loadFailed(error))
            completion(.failure(error))
            return
        }
        
        loadCompletion = completion

        let options = AdColonyAdOptions()
        options.setOption("adm", withStringValue: bidPayload)

        if request.format == .rewarded {
            zone.setReward { [weak self] success, _, _ in
                if success {
                    self?.didReceiveReward()
                }
            }
        }

        AdColony.requestInterstitial(inZone: request.partnerPlacement, options: options, andDelegate: self)
    }
    
    /// Shows a loaded ad.
    /// It will never get called for banner ads. You may leave the implementation blank for that ad format.
    /// - parameter viewController: The view controller on which the ad will be presented on.
    /// - parameter completion: Closure to be performed once the ad has been shown.
    func show(with viewController: UIViewController, completion: @escaping (Result<PartnerEventDetails, Error>) -> Void) {
        log(.showStarted)
        
        guard let ad = ad else {
            let error = error(.showFailureAdNotReady)
            log(.showFailed(error))
            completion(.failure(error))
            return
        }

        ad.show(withPresenting: viewController)
        
        log(.showSucceeded)
        completion(.success([:]))
    }
    
    private func didReceiveReward() {
        log(.didReward)
        delegate?.didReward(self, details: [:]) ?? log(.delegateUnavailable)
    }
}

// MARK: - AdColonyInterstitialDelegate

extension AdColonyAdapterFullscreenAd: AdColonyInterstitialDelegate {
    
    func adColonyInterstitialDidLoad(_ interstitial: AdColonyInterstitial) {
        log(.loadSucceeded)
        self.ad = interstitial
        loadCompletion?(.success([:])) ?? log(.loadResultIgnored)
        loadCompletion = nil
    }

    func adColonyInterstitialDidFail(toLoad partnerError: AdColonyAdRequestError) {
        log(.loadFailed(partnerError))
        loadCompletion?(.failure(partnerError)) ?? log(.loadResultIgnored)
        loadCompletion = nil
    }

    func adColonyInterstitialDidReceiveClick(_ interstitial: AdColonyInterstitial) {
        log(.didClick(error: nil))
        delegate?.didClick(self, details: [:]) ?? log(.delegateUnavailable)
    }

    func adColonyInterstitialDidClose(_ interstitial: AdColonyInterstitial) {
        log(.didDismiss(error: nil))
        delegate?.didDismiss(self, details: [:], error: nil) ?? log(.delegateUnavailable)
    }
}
