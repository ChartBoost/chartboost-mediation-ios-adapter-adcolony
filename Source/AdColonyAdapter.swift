//
//  AdColonyAdapter.swift
//  ChartboostHeliumAdapterAdColony
//

import Foundation
import HeliumSdk
import AdColony
import UIKit

/// The Helium AdColony adapter.
final class AdColonyAdapter: NSObject, PartnerAdapter {
    
    /// The version of the partner SDK.
    let partnerSDKVersion: String = AdColony.getSDKVersion()
    
    /// The version of the adapter.
    /// It should have 6 digits separated by periods, where the first digit is Helium SDK's major version, the last digit is the adapter's build version, and intermediate digits are the partner SDK's version.
    /// Format: `"<Helium major version>.<Partner major version>.<Partner minor version>.<Partner patch version>.<Partner build version>.<Adapter build version>"`.
    let adapterVersion = "4.4.9.0.0.0"
    
    /// The partner's unique identifier.
    let partnerIdentifier = "adcolony"
    
    /// The human-friendly partner name.
    let partnerDisplayName = "AdColony"
    
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
    
    /// The designated initializer for the adapter.
    /// Helium SDK will use this constructor to create instances of conforming types.
    /// - parameter storage: An object that exposes storage managed by the Helium SDK to the adapter.
    /// It includes a list of created `PartnerAd` instances. You may ignore this parameter if you don't need it.
    init(storage: PartnerAdapterStorage) {}

    /// Does any setup needed before beginning to load ads.
    /// - parameter configuration: Configuration data for the adapter to set up.
    /// - parameter completion: Closure to be performed by the adapter when it's done setting up. It should include an error indicating the cause for failure or `nil` if the operation finished successfully.
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
                self.zones = zones.reduce(into: [ZoneIdentifier: AdColonyZone]()) { dictionary, zone in
                    dictionary[zone.identifier] = zone
                }

                self.log(.setUpSucceded)
                completion(nil)
            }
        }
    }
    
    /// Fetches bidding tokens needed for the partner to participate in an auction.
    /// - parameter request: Information about the ad load request.
    /// - parameter completion: Closure to be performed with the fetched info.
    func fetchBidderInformation(request: PreBidRequest, completion: @escaping ([String : String]?) -> Void) {
        log(.fetchBidderInfoStarted(request))
        AdColony.collectSignals { [weak self] signals, error in
            guard let self = self else { return }
            if let error = error {
                self.log(.fetchBidderInfoFailed(request, error: error))
                completion(nil)
            }
            else {
                self.log(.fetchBidderInfoSucceeded(request))
                completion(["adc_data": signals ?? ""])
            }
        }
    }
    
    /// Indicates if GDPR applies or not and the user's GDPR consent status.
    /// - parameter applies: `true` if GDPR applies, `false` if not, `nil` if the publisher has not provided this information.
    /// - parameter status: One of the `GDPRConsentStatus` values depending on the user's preference.
    func setGDPR(applies: Bool?, status: GDPRConsentStatus) {
        if let applies = applies {
            Self.options.setPrivacyFrameworkOfType(ADC_GDPR, isRequired: applies)
            log(.privacyUpdated(setting: "privacyFrameworkOfTypeIsRequired", value: [ADC_GDPR: applies]))
        }
        if status != .unknown {
            let consentString = status == .granted ? "1" : "0"
            Self.options.setPrivacyConsentString(consentString, forType: ADC_GDPR)
            log(.privacyUpdated(setting: "privacyConsentString", value: [ADC_GDPR: consentString]))
        }
        AdColony.setAppOptions(Self.options)
    }
    
    /// Indicates if the user is subject to COPPA or not.
    /// - parameter isChildDirected: `true` if the user is subject to COPPA, `false` otherwise.
    func setCOPPA(isChildDirected: Bool) {
        Self.options.setPrivacyFrameworkOfType(ADC_COPPA, isRequired: isChildDirected)
        AdColony.setAppOptions(Self.options)
        log(.privacyUpdated(setting: "privacyFrameworkOfTypeIsRequired", value: [ADC_COPPA: isChildDirected]))
    }
    
    /// Indicates the CCPA status both as a boolean and as an IAB US privacy string.
    /// - parameter hasGivenConsent: A boolean indicating if the user has given consent.
    /// - parameter privacyString: An IAB-compliant string indicating the CCPA status.
    func setCCPA(hasGivenConsent: Bool, privacyString: String) {
        let consentString = hasGivenConsent ? "1" : "0"
        Self.options.setPrivacyConsentString(consentString, forType: ADC_CCPA)
        AdColony.setAppOptions(Self.options)
        log(.privacyUpdated(setting: "privacyConsentString", value: [ADC_CCPA: consentString]))
    }
    
    /// Creates a new ad object in charge of communicating with a single partner SDK ad instance.
    /// Helium SDK calls this method to create a new ad for each new load request. Ad instances are never reused.
    /// Helium SDK takes care of storing and disposing of ad instances so you don't need to.
    /// `invalidate()` is called on ads before disposing of them in case partners need to perform any custom logic before the object gets destroyed.
    /// If, for some reason, a new ad cannot be provided, an error should be thrown.
    /// - parameter request: Information about the ad load request.
    /// - parameter delegate: The delegate that will receive ad life-cycle notifications.
    func makeAd(request: PartnerAdLoadRequest, delegate: PartnerAdDelegate) throws -> PartnerAd {
        guard let zone = zones[request.partnerPlacement] else {
            throw error(.adCreationFailure(request), description: "Zone not found for partner placement")
        }
        guard request.partnerPlacement == zone.identifier else {
            throw error(.adCreationFailure(request), description: "Placement is different from the zone identifier.")
        }
        switch request.format {
        case .interstitial, .rewarded:
            return AdColonyAdapterFullscreenAd(adapter: self, request: request, delegate: delegate, zone: zone)
        case .banner:
            return AdColonyAdapterBannerAd(adapter: self, request: request, delegate: delegate, zone: zone)
        }
    }
}

/// Convenience extension to access AdColony credentials from the configuration.
private extension PartnerConfiguration {
    var appID: String? { credentials[.appIDKey] as? String }
}

private extension String {
    /// AdColony keys
    static let appIDKey = "adc_app_id"
}
