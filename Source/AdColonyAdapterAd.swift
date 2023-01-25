// Copyright 2022-2023 Chartboost, Inc.
// 
// Use of this source code is governed by an MIT-style
// license that can be found in the LICENSE file.

//
//  AdColonyAdapterAd.swift
//  ChartboostHeliumAdapterAdColony
//

import AdColony
import ChartboostMediationSDK
import Foundation
import UIKit

/// Base class for Helium AdColony adapter ads.
class AdColonyAdapterAd: NSObject {
    
    /// The partner adapter that created this ad.
    let adapter: PartnerAdapter
    
    /// The ad load request associated to the ad.
    /// It should be the one provided on `PartnerAdapter.makeAd(request:delegate:)`.
    let request: PartnerAdLoadRequest
    
    /// The partner ad delegate to send ad life-cycle events to.
    /// It should be the one provided on `PartnerAdapter.makeAd(request:delegate:)`.
    weak var delegate: PartnerAdDelegate?
    
    /// The AdColony zone.
    let zone: AdColonyZone

    /// The completion handler to notify Helium of ad load completion result.
    var loadCompletion: ((Result<PartnerEventDetails, Error>) -> Void)?
    
    init(adapter: PartnerAdapter, request: PartnerAdLoadRequest, delegate: PartnerAdDelegate, zone: AdColonyZone) {
        self.adapter = adapter
        self.request = request
        self.delegate = delegate
        self.zone = zone
    }
}
