//
//  AdColonyAdapterConfiguration.swift
//  ChartboostHeliumAdapterAdColony
//

import AdColony

/// A list of externally configurable properties pertaining to the partner SDK that can be retrieved and set by publishers.
public class AdColonyAdapterConfiguration {

    /// Flag that can optionally be set to enable the partner's test mode.
    /// Disabled by default.
    public static var testMode: Bool = false {
        didSet {
            let options = AdColonyAdapter.options
            options.testMode = testMode
            AdColony.setAppOptions(options)

            print("The AdColony SDK's test mode is \(testMode ? "enabled" : "disabled").")
        }
    }
    
    /// Flag that can optionally be set to enable the partner's verbose logging.
    /// Disabled by default.
    public static var verboseLogging: Bool = false {
        didSet {
            let options = AdColonyAdapter.options
            options.disableLogging = !verboseLogging
            AdColony.setAppOptions(options)

            print("The AdColony SDK's verbose logging is \(verboseLogging ? "enabled" : "disabled").")
        }
    }
    
    /// Append any other properties that publishers can configure.
}
