//
//  AdColonyAdapter.swift
//  ChartboostHeliumAdapterAdColony
//

import Foundation
import HeliumSdk
import AdColony
import UIKit

final class AdColonyAdapter: NSObject, PartnerAdapter {
    /// Get the version of the partner SDK.
    let partnerSDKVersion: String = AdColony.getSDKVersion()
    
    /// Get the version of the mediation adapter.
    let adapterVersion = "4.4.9.0.0"
    
    /// Get the internal name of the partner.
    let partnerIdentifier = "adcolony"
    
    /// Get the external/official name of the partner.
    let partnerDisplayName = "AdColony"
    
    /// Storage of adapter instances.  Keyed by the request identifier.
    var adapters: [String: AdColonyAdAdapter] = [:]

    /// AdColony app options.  It's static, for the sake of AdColonyAdapterConfiguration needing to
    /// amend these options for verbose logging, test mode, and perhaps others in the future.
    static var options: AdColonyAppOptions = {
        let options = AdColonyAppOptions()
        options.disableLogging = true
        return options
    }()

    /// The AdColony zones, populated during setup.
    private typealias ZoneIdentifier = String
    private var zones: [ZoneIdentifier: AdColonyZone] = [:]

    /// Onitialize the partner SDK so that it's ready to request and display ads.
    /// - Parameters:
    ///   - configuration: The necessary initialization data provided by Helium.
    ///   - completion: Handler to notify Helium of task completion.
    func setUp(with configuration: PartnerConfiguration, completion: @escaping (Error?) -> Void) {
        log(.setUpStarted)
        guard let appID = configuration.appID, !appID.isEmpty else {
            let error = error(.missingSetUpParameter(key: .appIDKey))
            log(.setUpFailed(error))
            return completion(error)
        }

        Self.options.mediationNetwork = "Helium"
        Self.options.mediationNetworkVersion = Helium.sdkVersion

        AdColony.configure(withAppID: appID, options: Self.options) { [weak self] zones in
            guard let self = self else { return }
            if zones.isEmpty {
                let error = self.error(.setUpFailure, description: "No active zones")
                self.log(.setUpFailed(error))
               completion(error)
            }
            else {
                // Map the zones array into the zones dictionary property with the key
                // being the zone.identifer and the value being the zone.
                self.zones = zones.reduce(into: [ZoneIdentifier: AdColonyZone]()) {
                    $0[$1.identifier] = $1
                }

                self.log(.setUpSucceded)
                completion(nil)
            }
        }
    }
    
    /// Compute and return a bid token for the bid request.
    /// - Parameters:
    ///   - request: The necessary data associated with the current bid request.
    ///   - completion: Handler to notify Helium of task completion.
    func fetchBidderInformation(request: PreBidRequest, completion: @escaping ([String : String]) -> Void) {
        log(.fetchBidderInfoStarted(request))
        AdColony.collectSignals { [weak self] signals, error in
            guard let self = self else { return }
            if let error = error {
                self.log(.fetchBidderInfoFailed(request, error: error))
                completion([:])
            }
            else {
                self.log(.fetchBidderInfoSucceeded(request))
                completion(["adc_data": signals ?? ""])
            }
        }
    }
    
    /// Notify the partner SDK of GDPR applicability as determined by the Helium SDK.
    /// - Parameter applies: true if GDPR applies, false otherwise.
    func setGDPRApplies(_ applies: Bool) {
        log("The AdColony adapter has been notified that GDPR \(applies ? "applies" : "does not apply").")
        Self.options.setPrivacyFrameworkOfType(ADC_GDPR, isRequired: applies)
        AdColony.setAppOptions(Self.options)
   }
    
    /// Notify the partner SDK of the GDPR consent status as determined by the Helium SDK.
    /// - Parameter status: The user's current GDPR consent status.
    func setGDPRConsentStatus(_ status: GDPRConsentStatus) {
        log("The AdColony adapter has been notified that the user's GDPR consent status is \(status).")
        guard status != .unknown else { return }
        Self.options.setPrivacyConsentString(status == .granted ? "1" : "0", forType: ADC_GDPR)
        AdColony.setAppOptions(Self.options)
    }

    /// Notify the partner SDK of the COPPA subjectivity as determined by the Helium SDK.
    /// - Parameter isSubject: True if the user is subject to COPPA, false otherwise.
    func setUserSubjectToCOPPA(_ isSubject: Bool) {
        log("The AdColony adapter has been notified that the user is \(isSubject ? "subject" : "not subject") to COPPA.")
        Self.options.setPrivacyFrameworkOfType(ADC_COPPA, isRequired: isSubject)
        AdColony.setAppOptions(Self.options)
    }
    
    /// Notify the partner SDK of the CCPA privacy String as supplied by the Helium SDK.
    /// - Parameters:
    ///   - hasGivenConsent: True if the user has given CCPA consent, false otherwise.
    ///   - privacyString: The CCPA privacy String.
    func setCCPAConsent(hasGivenConsent: Bool, privacyString: String?) {
        log("The AdColony adapter has been notified that the user has \(hasGivenConsent ? "given" : "not given") CCPA consent.")
        Self.options.setPrivacyConsentString(hasGivenConsent ? "1" : "0", forType: ADC_CCPA)
        AdColony.setAppOptions(Self.options)
    }
    
    /// Make an ad request to the partner SDK for the given ad format.
    /// - Parameters:
    ///   - request: The relevant data associated with the current ad load call.
    ///   - partnerAdDelegate: Delegate for ad lifecycle notification purposes.
    ///   - viewController: The ViewController for ad presentation purposes.
    ///   - completion: Handler to notify Helium of task completion.
    func load(request: PartnerAdLoadRequest, partnerAdDelegate: PartnerAdDelegate, viewController: UIViewController?, completion: @escaping (Result<PartnerAd, Error>) -> Void) {
        log(.loadStarted(request))
        guard let zone = zones[request.partnerPlacement] else {
            let error = error(.loadFailure(request), description: "zone not found for partner placement")
            log(.loadFailed(request, error: error))
            return completion(.failure(error))
        }

        let adapter = AdColonyAdAdapter(adapter: self, request: request, partnerAdDelegate: partnerAdDelegate, zone: zone)
        adapter.load(viewController: viewController, completion: completion)

        adapters[request.identifier] = adapter
    }

    /// Show the currently loaded ad.
    /// - Parameters:
    ///   - partnerAd: The PartnerAd instance containing the ad to be shown.
    ///   - viewController: The ViewController for ad presentation purposes.
    ///   - completion: Handler to notify Helium of task completion.
    func show(_ partnerAd: PartnerAd, viewController: UIViewController, completion: @escaping (Result<PartnerAd, Error>) -> Void) {
        log(.showStarted(partnerAd))

        // Retrieve the adapter instance to show the ad
        if let adapter = adapters[partnerAd.request.identifier] {
            adapter.show(viewController: viewController, completion: completion)
        } else {
            let error = error(.noAdReadyToShow(partnerAd))
            log(.showFailed(partnerAd, error: error))

            completion(.failure(error))
        }
    }
    
    /// Discard current ad objects and release resources.
    /// - Parameters:
    ///   - partnerAd: The PartnerAd instance containing the ad to be invalidated.
    ///   - completion: Handler to notify Helium of task completion.
    func invalidate(_ partnerAd: PartnerAd, completion: @escaping (Result<PartnerAd, Error>) -> Void) {
        log(.invalidateStarted(partnerAd))

        if adapters[partnerAd.request.identifier] != nil {
            adapters.removeValue(forKey: partnerAd.request.identifier)

            log(.invalidateSucceeded(partnerAd))
            completion(.success(partnerAd))
        } else {
            let error = error(.noAdToInvalidate(partnerAd))

            log(.invalidateFailed(partnerAd, error: error))
            completion(.failure(error))
        }
    }
}

/// Convenience extension to access AdColony credentials from the configuration.
private extension PartnerConfiguration {
    var appID: String? { credentials[.appIDKey] }
}

private extension String {
    /// AdColony keys
    static let appIDKey = "adc_app_id"
}
