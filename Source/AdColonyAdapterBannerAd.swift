// Copyright 2022-2023 Chartboost, Inc.
//
// Use of this source code is governed by an MIT-style
// license that can be found in the LICENSE file.

import AdColony
import ChartboostMediationSDK
import Foundation

/// The Chartboost Mediation AdColony adapter banner ad.
final class AdColonyAdapterBannerAd: AdColonyAdapterAd, PartnerAd {
    
    /// The partner ad view to display inline. E.g. a banner view.
    /// Should be nil for full-screen ads.
    var inlineView: UIView?
    
    /// Loads an ad.
    /// - parameter viewController: The view controller on which the ad will be presented on. Needed on load for some banners.
    /// - parameter completion: Closure to be performed once the ad has been loaded.
    func load(with viewController: UIViewController?, completion: @escaping (Result<PartnerEventDetails, Error>) -> Void) {
        log(.loadStarted)
        
        guard let viewController = viewController else {
            let error = error(.loadFailureViewControllerNotFound)
            log(.loadFailed(error))
            return completion(.failure(error))
        }
        
        loadCompletion = completion

        // Fail if we cannot fit a fixed size banner in the requested size.
        guard let size = fixedBannerSize(for: request.size ?? IABStandardAdSize) else {
            let error = error(.loadFailureInvalidBannerSize)
            log(.loadFailed(error))
            return completion(.failure(error))
        }

        let adColonySize = AdColonyAdSizeFromCGSize(size)
        let options = AdColonyAdOptions()
        if let adm = request.adm {
            options.setOption("adm", withStringValue: adm)
        }

        AdColony.requestAdView(
            inZone: request.partnerPlacement,
            with: adColonySize,
            andOptions: options,
            viewController: viewController,
            andDelegate: self
        )
    }
    
    /// Shows a loaded ad.
    /// It will never get called for banner ads. You may leave the implementation blank for that ad format.
    /// - parameter viewController: The view controller on which the ad will be presented on.
    /// - parameter completion: Closure to be performed once the ad has been shown.
    func show(with viewController: UIViewController, completion: @escaping (Result<PartnerEventDetails, Error>) -> Void) {
        // no-op
    }
}

extension AdColonyAdapterBannerAd: AdColonyAdViewDelegate {
    
    func adColonyAdViewDidLoad(_ adView: AdColonyAdView) {
        log(.loadSucceeded)
        self.inlineView = adView

        var partnerDetails: [String: String] = [:]
        if let loadedSize = fixedBannerSize(for: request.size ?? IABStandardAdSize) {
            partnerDetails["bannerWidth"] = "\(loadedSize.width)"
            partnerDetails["bannerHeight"] = "\(loadedSize.height)"
            partnerDetails["bannerType"] = "0" // Fixed banner
        }
        loadCompletion?(.success(partnerDetails)) ?? log(.loadResultIgnored)
        loadCompletion = nil
    }

    func adColonyAdViewDidFail(toLoad partnerError: AdColonyAdRequestError) {
        log(.loadFailed(partnerError))
        loadCompletion?(.failure(partnerError)) ?? log(.loadResultIgnored)
        loadCompletion = nil
    }

    func adColonyAdViewDidClose(_ adView: AdColonyAdView) {
        log(.delegateCallIgnored)
    }

    func adColonyAdViewDidReceiveClick(_ adView: AdColonyAdView) {
        log(.didClick(error: nil))
        delegate?.didClick(self, details: [:]) ?? log(.delegateUnavailable)
    }
}

// MARK: - Helpers
extension AdColonyAdapterBannerAd {
    private func fixedBannerSize(for requestedSize: CGSize) -> CGSize? {
        let sizes = [IABLeaderboardAdSize, IABMediumAdSize, IABStandardAdSize]
        // Find the largest size that can fit in the requested size.
        for size in sizes {
            // If height is 0, the pub has requested an ad of any height, so only the width matters.
            if requestedSize.width >= size.width &&
                (size.height == 0 || requestedSize.height >= size.height) {
                return size
            }
        }
        // The requested size cannot fit any fixed size banners.
        return nil
    }
}
