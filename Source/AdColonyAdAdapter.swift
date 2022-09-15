//
//  AdColonyAdAdapter.swift
//  ChartboostHeliumAdapterAdColony
//

import Foundation
import HeliumSdk
import AdColony
import UIKit

final class AdColonyAdAdapter: NSObject, PartnerLogger, PartnerErrorFactory {
    /// The current adapter instance
    let adapter: PartnerAdapter

    /// The current PartnerAdLoadRequest containing data relevant to the curent ad request
    let request: PartnerAdLoadRequest

    /// A PartnerAd object with a placeholder (nil) ad object.
    lazy var partnerAd = PartnerAd(ad: nil, details: [:], request: request)

    /// The partner ad delegate to send ad life-cycle events to.
    weak var partnerAdDelegate: PartnerAdDelegate?

    /// The AdColony zone.
    var zone: AdColonyZone

    /// The completion handler to notify Helium of ad load completion result.
    var loadCompletion: ((Result<PartnerAd, Error>) -> Void)?

    /// Create a new instance of the adapter.
    /// - Parameters:
    ///   - adapter: The current adapter instance
    ///   - request: The current AdLoadRequest containing data relevant to the curent ad request
    ///   - partnerAdDelegate: The partner ad delegate to notify Helium of ad lifecycle events.
    init(adapter: PartnerAdapter, request: PartnerAdLoadRequest, partnerAdDelegate: PartnerAdDelegate, zone: AdColonyZone) {
        self.adapter = adapter
        self.request = request
        self.partnerAdDelegate = partnerAdDelegate
        self.zone = zone

        super.init()
    }

    /// Attempt to load an ad.
    /// - Parameters:
    ///   - viewController: The ViewController for ad presentation purposes.
    ///   - completion: The completion handler to notify Helium of ad load completion result.
    func load(viewController: UIViewController?, completion: @escaping (Result<PartnerAd, Error>) -> Void) {
        let loadCompletion: (Result<PartnerAd, Error>) -> Void = { [weak self] result in
            if let self = self {
                do {
                    self.log(.loadSucceeded(try result.get()))
                } catch {
                    self.log(.loadFailed(self.request, error: error))
                }
            }

            self?.loadCompletion = nil
            completion(result)
        }

        switch request.format {
        case .banner:
            guard let viewController = viewController else {
                let error = error(.noViewController)
                log(.loadFailed(request, error: error))
                return completion(.failure(error))
            }
            loadBanner(viewController: viewController, request: request, completion: loadCompletion)

        case .interstitial, .rewarded:
            loadInterstitial(request: request, completion: loadCompletion)
        }
    }

    /// Attempt to show the currently loaded ad.
    /// - Parameters:
    ///   - viewController: The ViewController for ad presentation purposes.
    ///   - completion: The completion handler to notify Helium of ad show completion result.
    func show(viewController: UIViewController?, completion: @escaping (Result<PartnerAd, Error>) -> Void) {
        switch request.format {
        case .banner:
            // Banner does not have a separate show mechanism
            log(.showSucceeded(partnerAd))
            completion(.success(partnerAd))

        case .interstitial, .rewarded:
            guard let viewController = viewController else {
                let error = error(.noViewController)
                log(.loadFailed(request, error: error))
                return completion(.failure(error))
            }
            showInterstitial(viewController: viewController, completion: completion)
        }
    }
}
