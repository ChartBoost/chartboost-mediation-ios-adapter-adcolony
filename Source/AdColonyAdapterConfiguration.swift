// Copyright 2022-2023 Chartboost, Inc.
// 
// Use of this source code is governed by an MIT-style
// license that can be found in the LICENSE file.

//
//  AdColonyAdapterConfiguration.swift
//  ChartboostHeliumAdapterAdColony
//

import AdColony

/// A list of externally configurable properties pertaining to the partner SDK that can be retrieved and set by publishers.
@objc public class AdColonyAdapterConfiguration: NSObject {

    /// Flag that can optionally be set to enable the partner's test mode.
    /// Disabled by default.
    @objc public static var testMode: Bool = false {
        didSet {
            let options = AdColonyAdapter.options
            options.testMode = testMode
            AdColony.setAppOptions(options)
            print("AdColony SDK test mode set to \(testMode)")
        }
    }
    
    /// Flag that can optionally be set to enable the partner's verbose logging.
    /// Disabled by default.
    @objc public static var verboseLogging: Bool = false {
        didSet {
            let options = AdColonyAdapter.options
            options.disableLogging = !verboseLogging
            AdColony.setAppOptions(options)
            print("AdColony SDK verbose logging set to \(verboseLogging)")
        }
    }
}
