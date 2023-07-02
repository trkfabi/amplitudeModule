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
//    Amplitude(
//      configuration: Configuration(
//        apiKey: ""
//      )
//    )
    
    @objc(initialize:)
    func initialize(arguments: Array<Any>?) {
        guard let arguments = arguments, let options = arguments[0] as? [String: Any] else { return }
        let apiKey = options["apiKey"] as? String ?? ""
        doLog = options["doLog"] as? Bool ?? false
        self.fireEvent("app:amplitude_log", with: ["method": "initialize", "apiKey": apiKey])
        amplitude = Amplitude(
          configuration: Configuration(
            apiKey: apiKey,
            trackingSessionEvents: true
          )
        )
        if (doLog) {
            amplitude?.logger?.logLevel = LogLevelEnum.DEBUG.rawValue
        }
    }
    
    @objc(logUserId:)
    func logUserId(arguments: Array<Any>?) {
    
        guard let arguments = arguments, let options = arguments[0] as? [String: Any] else { return }
        let userId = options["userId"] as? String ?? ""
        self.fireEvent("app:amplitude_log", with: ["method": "setUserId", "userId": userId])
        amplitude?.setUserId(userId: userId)
    
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
}
