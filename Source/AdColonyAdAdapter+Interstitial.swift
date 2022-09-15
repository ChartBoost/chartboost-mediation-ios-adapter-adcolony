//
//  AdColonyAdAdapter+Interstitial.swift
//  ChartboostHeliumAdapterAdColony
//

import Foundation
import HeliumSdk
import AdColony

extension AdColonyAdAdapter: AdColonyInterstitialDelegate {
    /// Attempt to load an interstitial ad.
    /// - Parameters:
    ///   - request: The relevant data associated with the current ad load call.
    ///   - completion: The completion handler to notify Helium of ad load completion result.
    func loadInterstitial(request: PartnerAdLoadRequest, completion: @escaping (Result<PartnerAd, Error>) -> Void) {
        guard request.partnerPlacement == zone.identifier else {
            return completion(.failure(error(.loadFailure(request), description: "partnerPlacement != zone.identifier")))
        }
        guard let bidPayload = request.adm, !bidPayload.isEmpty else {
            return completion(.failure(error(.noBidPayload(request))))
        }

        loadCompletion = completion

        let options = AdColonyAdOptions()
        options.setOption("adm", withStringValue: bidPayload)
        if request.format == .rewarded {
            zone.setReward { [weak self] success, _, amount in
                guard let self = self, success else { return }
                self.didReceiveReward(amount: Int(amount))
            }
        }
        AdColony.requestInterstitial(inZone: request.partnerPlacement, options: options, andDelegate: self)
    }

    /// Attempt to show the currently loaded interstitial ad.
    /// - Parameters:
    ///   - viewController: The ViewController for ad presentation purposes.
    ///   - completion: The completion handler to notify Helium of ad show completion result.
    func showInterstitial(viewController: UIViewController, completion: @escaping (Result<PartnerAd, Error>) -> Void) {
        guard let ad = partnerAd.ad as? AdColonyInterstitial else {
            return completion(.failure(error(.showFailure(partnerAd), description: "Ad instance is nil/not a AdColonyInterstitial.")))
        }
        ad.show(withPresenting: viewController)
        return completion(.success(partnerAd))
    }

    // MARK: - AdColonyInterstitialDelegate
    
    func adColonyInterstitialDidLoad(_ interstitial: AdColonyInterstitial) {
        partnerAd = PartnerAd(ad: interstitial, details: [:], request: request)
        loadCompletion?(.success(partnerAd)) ?? log(.loadResultIgnored)
        loadCompletion = nil
    }

    func adColonyInterstitialDidFail(toLoad error: AdColonyAdRequestError) {
        loadCompletion?(.failure(self.error(.loadFailure(request), error: error))) ?? log(.loadResultIgnored)
        loadCompletion = nil
    }

    func adColonyInterstitialDidReceiveClick(_ interstitial: AdColonyInterstitial) {
        log(.didClick(partnerAd, error: nil))
        partnerAdDelegate?.didClick(partnerAd) ?? log(.delegateUnavailable)
    }

    func adColonyInterstitialDidClose(_ interstitial: AdColonyInterstitial) {
        log(.didDismiss(partnerAd, error: nil))
        partnerAdDelegate?.didDismiss(partnerAd, error: nil) ?? log(.delegateUnavailable)
    }

    // MARK: - Private

    private func didReceiveReward(amount: Int) {
        let reward = Reward(amount: Int(amount), label: "")
        log(.didReward(partnerAd, reward: reward))
        partnerAdDelegate?.didReward(partnerAd, reward: reward) ?? log(.delegateUnavailable)
    }
}
