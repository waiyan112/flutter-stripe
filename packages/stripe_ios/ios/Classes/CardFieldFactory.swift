//
//  CardFieldView.swift
//  stripe_ios
//
//  Created by Jaime Blasco on 7/3/21.
//

import Foundation
import UIKit
import Stripe

public class CardFieldViewFactory: NSObject, FlutterPlatformViewFactory {
    private var messenger: FlutterBinaryMessenger
    private var delegate: ViewManagerDelegate
    
    init(messenger: FlutterBinaryMessenger, delegate: ViewManagerDelegate) {
        self.messenger = messenger
        self.delegate = delegate
        super.init()
    }
    
    public func create(
        withFrame frame: CGRect,
        viewIdentifier viewId: Int64,
        arguments args: Any?
    ) -> FlutterPlatformView {
        let view = CardFieldPlatformView(
            frame: frame,
            viewIdentifier: viewId,
            arguments: args,
            binaryMessenger: messenger
        )
        delegate.cardFieldView = view.cardField
        return view
    }
    
    public func createArgsCodec() -> FlutterMessageCodec & NSObjectProtocol {
       return FlutterStandardMessageCodec.sharedInstance()
    }
}



class CardFieldPlatformView: NSObject, FlutterPlatformView, STPPaymentCardTextFieldDelegate {

   public let cardField = CardFieldView()
    
    private let channel: FlutterMethodChannel
    public var cardParams: STPPaymentMethodCardParams? = nil
    
    init(
        frame: CGRect,
        viewIdentifier viewId: Int64,
        arguments args: Any?,
        binaryMessenger messenger: FlutterBinaryMessenger
    ) {
       
        channel = FlutterMethodChannel(name: "flutter.stripe/card_field/\(viewId)",
                                           binaryMessenger: messenger)
      
    
        super.init()
        channel.setMethodCallHandler(handle)
        cardField.onCardChange = onCardChange
        cardField.onFocusChange = onFocusChange
        updateProps(args)
       
    }
    
    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        switch call.method {
      
        case "onStyleChanged",
             "onPostalCodeEnabledChanged",
             "onPlaceholderChanged",
             "dangerouslyGetFullCardDetails",
             "autofocus":
          updateProps(call.arguments as? [String : Any])
          result(nil)
        case "focus":
          cardField.focus()
          result(nil)
        case "blur":
          cardField.blur()
          result(nil)
        case "clear":
          cardField.clear()
          result(nil)
        default:
            result(FlutterMethodNotImplemented)
        }
    }

    func view() -> UIView {
        return cardField
    }
    
    func onFocusChange(_ arguments: Dictionary<AnyHashable, Any>?) {
        channel.invokeMethod("topFocusChange", arguments: arguments!)
    }
    
    func onCardChange(_ arguments: Dictionary<AnyHashable, Any>?) {
        channel.invokeMethod("onCardChange", arguments: arguments)
    }
    
    func updateProps (_ args : Any? ) {
        guard let arguments = args  as?  [String: Any]  else{
            return;
        }
       if let placeholder = arguments["placeholder"] as? NSDictionary {
        cardField.placeholder = placeholder
       }
       if  let cardStyle = arguments["cardStyle"] as? NSDictionary{
            if let fontFamily = cardStyle["fontFamily"] as? String {
                registerFont(fontFamily)
            }
            cardField.cardStyle = cardStyle
       }
        if let dangerouslyGetFullCardDetails = arguments["dangerouslyGetFullCardDetails"] as? Bool {
          cardField.dangerouslyGetFullCardDetails = dangerouslyGetFullCardDetails
        }
        
        if let autofocus = arguments["autofocus"] as? Bool {
         cardField.autofocus = autofocus
        }
        
       if let postalCodeEnabled = arguments["postalCodeEnabled"] as? Bool{
         cardField.postalCodeEnabled = postalCodeEnabled
       }
        
       if let cardDetails = arguments["cardDetails"] as? NSDictionary {
         cardField.dangerouslyUpdateCardDetails(params: cardDetails)
       }
      
       cardField.didSetProps([])
    }
    
}


extension CardFieldView {
    func dangerouslyUpdateCardDetails(params: NSDictionary ) {
        let cardParams = STPPaymentMethodCardParams()
        cardParams.cvc = params["cvc"] as? String
        cardParams.number = params["number"] as? String
        cardParams.expYear = params["expirationYear"] as? NSNumber ??  params["expiryYear"] as? NSNumber
        cardParams.expMonth = params["expirationMonth"] as? NSNumber ?? params["expiryMonth"] as? NSNumber
        self.cardField.cardParams = cardParams
        self.cardField.postalCode = params["postalCode"] as? String
        self.cardParams = cardParams
        self.cardPostalCode = params["postalCode"] as? String
    }
}

