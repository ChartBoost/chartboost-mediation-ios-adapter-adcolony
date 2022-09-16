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
    ///   - completion: The completion handler to notify Helium of ad load completion result.
    func loadBanner(viewController: UIViewController, request: PartnerAdLoadRequest, completion: @escaping (Result<PartnerAd, Error>) -> Void) {
        guard request.partnerPlacement == zone.identifier else {
            return completion(.failure(error(.loadFailure(request), description: "partnerPlacement != zone.identifier")))
        }
        guard let bidPayload = request.adm, !bidPayload.isEmpty else {
            return completion(.failure(error(.noBidPayload(request))))
        }

        loadCompletion = completion

        let width = request.size?.width ?? 320
        let height = request.size?.height ?? 50
        let size = AdColonyAdSizeMake(width, height)

        let options = AdColonyAdOptions()
        options.setOption("adm", withStringValue: bidPayload)

        AdColony.requestAdView(inZone: request.partnerPlacement, with: size, andOptions: options, viewController: viewController, andDelegate: self)
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
