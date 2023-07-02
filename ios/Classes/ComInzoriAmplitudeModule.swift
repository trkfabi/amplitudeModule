//
//  ComInzoriAmplitudeModule.swift
//  Amplitude
//
//  Created by Fabian Martinez
//  Copyright (c) 2023 Your Company. All rights reserved.
//

import UIKit
import TitaniumKit
import Amplitude_Swift
import Experiment
/**
 
 Titanium Swift Module Requirements
 ---
 
 1. Use the @objc annotation to expose your class to Objective-C (used by the Titanium core)
 2. Use the @objc annotation to expose your method to Objective-C as well.
 3. Method arguments always have the "[Any]" type, specifying a various number of arguments.
 Unwrap them like you would do in Swift, e.g. "guard let arguments = arguments, let message = arguments.first"
 4. You can use any public Titanium API like before, e.g. TiUtils. Remember the type safety of Swift, like Int vs Int32
 and NSString vs. String.
 
 */

@objc(ComInzoriAmplitudeModule)
class ComInzoriAmplitudeModule: TiModule {

  public var doLog: Bool = false
  
  func moduleGUID() -> String {
    return "178f5fc0-f47b-4a58-a81b-63547fa0c38b"
  }
  
  override func moduleId() -> String! {
    return "com.inzori.amplitude"
  }

  override func startup() {
    super.startup()
    debugPrint("[DEBUG] \(self) loaded")
  }
    
    var amplitude:Amplitude? = nil
    var client:ExperimentClient? = nil

    
    @objc(initialize:)
    func initialize(arguments: Array<Any>?) {
        guard let arguments = arguments, let options = arguments[0] as? [String: Any] else { return }
        let apiKey = options["apiKey"] as? String ?? ""
        let experimentApiKey = options["experimentApiKey"] as? String ?? ""
        doLog = options["doLog"] as? Bool ?? false
        self.fireEvent("app:amplitude_log", with: ["method": "initialize", "apiKey": apiKey, "experimentApiKey": experimentApiKey])
        amplitude = Amplitude(
          configuration: Configuration(
            apiKey: apiKey,
            trackingSessionEvents: true
          )
        )
        if (doLog) {
            amplitude?.logger?.logLevel = LogLevelEnum.DEBUG.rawValue
        }
        
        if (!experimentApiKey.isEmpty) {
            self.fireEvent("app:amplitude_log", with: ["method": "initialize", "message": "Initialize Experiment"])
            let experimentConfig = ExperimentConfigBuilder()
                .debug(true)
                .build()
            
            // (1) Initialize the experiment client
            client = Experiment.initializeWithAmplitudeAnalytics(
                apiKey: experimentApiKey,
                config: experimentConfig
            )
        }
    }
    
    @objc(logUserId:)
    func logUserId(arguments: Array<Any>?) {
    
        guard let arguments = arguments, let options = arguments[0] as? [String: Any] else { return }
        let userId = options["userId"] as? String ?? ""
        self.fireEvent("app:amplitude_log", with: ["method": "setUserId", "userId": userId])
        amplitude?.setUserId(userId: userId )
        
        // we don't need the user as we're integrating with analytics
        let user = ExperimentUserBuilder()
            .userId(userId )
            .build()

        // (2) Fetch variants for a user
        client!.fetch(user: nil, completion: nil)
        client?.all().forEach({ v in
            self.fireEvent("app:amplitude_log", with: ["method": "setUserId", "variant": v.key, "value": v.value])
        })
        
//        client!.fetch(user: user) { experiment, error in
//
//            // (3) Lookup a flag's variant
//            let variant = experiment.variant("a-a-test")
//            self.fireEvent("app:amplitude_log", with: ["method": "setUserId", "fetchedVariant": variant.value!])
//
//        }
    }
    
    @objc(lookUpVariant:)
    func lookUpVariant(arguments: Array<Any>?) -> Any {
        guard let arguments = arguments, let options = arguments[0] as? [String: Any] else { return ""}
        let flag = options["flag"] as? String ?? ""
        
        self.fireEvent("app:amplitude_log", with: ["method": "lookUpVariant", "flag": flag])
        
        let variant = client!.variant(flag)
        self.fireEvent("app:amplitude_log", with: ["method": "lookUpVariant", "value": variant.value ?? ""])
        
        client!.exposure(key: flag)
        
        return variant.value ?? ""
    }
    
    @objc(logDeviceId:)
    func logDeviceId(arguments: Array<Any>?) {
        guard let arguments = arguments, let options = arguments[0] as? [String: Any] else { return }
        let deviceId = options["deviceId"] as? String ?? ""
        self.fireEvent("app:amplitude_log", with: ["method": "setDeviceId", "deviceId": deviceId])
        amplitude?.setDeviceId(deviceId: deviceId)
    }
    
    @objc(logSessionId:)
    func logSessionId(arguments: Array<Any>?) {
        //let timestamp = Int64(NSDate().timeIntervalSince1970 * 1000)
        //amplitude?.setSessionId(sessionId: timestamp)
    }

    @objc(logUserProperties:)
    func logUserProperties(arguments: Array<Any>?) {
        guard let arguments = arguments, let options = arguments[0] as? [String: Any] else { return }
        let props = options["props"] as? [String: Any] ?? [:]

        let identify = Identify()
        for (key, value) in props {
            identify.set(property: key, value: value)
        }
        amplitude?.identify(identify: identify)
    }
    
    @objc(clearUserProperties:)
    func clearUserProperties(arguments: Array<Any>?) {
        let identify = Identify()
        identify.clearAll()
        amplitude?.identify(identify: identify)
    }
    
    @objc(logEvent:)
    func logEvent(arguments: Array<Any>?) {
        guard let arguments = arguments, let options = arguments[0] as? [String: Any] else { return }
        let eventType = options["eventType"] as? String ?? ""
        let props = options["props"] as? [String: Any] ?? nil

        let event = BaseEvent(
          eventType: eventType,
          eventProperties: props
        )
        amplitude?.track(event: event)
    }

    @objc(logRevenue:)
    func logRevenue(args: Array<Any>?) {
        guard let args = args, let options = args[0] as? [String: Any] else { return }
        let productId = options["productId"] as? String ?? ""
        let price = options["price"] as? Double ?? 0
        let quantity = options["quantity"] as? Int ?? 0

        let revenue = Revenue()
        revenue.productId = productId
        revenue.quantity = quantity
        revenue.price = price

        amplitude?.revenue(revenue: revenue)

    }
    
    @objc(reset:)
    func reset(arguments: Array<Any>?) {
        amplitude?.reset()
    }
    
    @objc(clearExperiment:)
    func clearExperiment(arguments: Array<Any>?) {
        client?.clear()
    }
}
