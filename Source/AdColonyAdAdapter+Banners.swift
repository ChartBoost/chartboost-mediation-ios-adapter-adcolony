//
//  AdColonyAdAdapter+Banners.swift
//  ChartboostHeliumAdapterAdColony
//

import Foundation
import HeliumSdk
import AdColony

extension AdColonyAdAdapter {
    /// Attempt to load a banner ad.
    /// - Parameters:
    ///   - viewController: The ViewController for ad presentation purposes.
    ///   - request: The relevant data associated with the current ad load call.
    func loadBanner(viewController: UIViewController, request: PartnerAdLoadRequest) {
        let result = validateLoadRequest(request)
        switch result {
        case .failure(let error):
            loadCompletion?(.failure(error))

        case .success(let bidPayload):
            let width = request.size?.width ?? 320
            let height = request.size?.height ?? 50
            let size = AdColonyAdSizeMake(width, height)

            let options = AdColonyAdOptions()
            options.setOption("adm", withStringValue: bidPayload)

            AdColony.requestAdView(inZone: request.partnerPlacement, with: size, andOptions: options, viewController: viewController, andDelegate: self)
        }
    }
}

extension AdColonyAdAdapter: AdColonyAdViewDelegate {
    func adColonyAdViewDidLoad(_ adView: AdColonyAdView) {
        partnerAd = PartnerAd(ad: adView, details: [:], request: request)
        loadCompletion?(.success(partnerAd)) ?? log(.loadResultIgnored)
        loadCompletion = nil
    }

    func adColonyAdViewDidFail(toLoad error: AdColonyAdRequestError) {
        loadCompletion?(.failure(self.error(.loadFailure(request), error: error))) ?? log(.loadResultIgnored)
        loadCompletion = nil
    }

    func adColonyAdViewDidClose(_ adView: AdColonyAdView) {
        log(.didDismiss(partnerAd, error: nil))
        partnerAdDelegate?.didDismiss(partnerAd, error: nil)
    }

    func adColonyAdViewDidReceiveClick(_ adView: AdColonyAdView) {
        log(.didClick(partnerAd, error: nil))
        partnerAdDelegate?.didClick(partnerAd) ?? log(.delegateUnavailable)
    }
}
