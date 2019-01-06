//
//  MoneroUtils_RequestsURIs.swift
//  MyMonero
//
//  Created by Paul Shapiro on 5/9/17.
//  Copyright (c) 2014-2018, MyMonero.com
//
//  All rights reserved.
//
//  Redistribution and use in source and binary forms, with or without modification, are
//  permitted provided that the following conditions are met:
//
//  1. Redistributions of source code must retain the above copyright notice, this list of
//	conditions and the following disclaimer.
//
//  2. Redistributions in binary form must reproduce the above copyright notice, this list
//	of conditions and the following disclaimer in the documentation and/or other
//	materials provided with the distribution.
//
//  3. Neither the name of the copyright holder nor the names of its contributors may be
//	used to endorse or promote products derived from this software without specific
//	prior written permission.
//
//  THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY
//  EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF
//  MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL
//  THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
//  SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO,
//  PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
//  INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT,
//  STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF
//  THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
//
//
import Foundation
//
extension MoneroUtils
{
	struct URIs
	{
		enum URIMode
		{
			case addressAsAuthority
			case addressAsFirstPathComponent
		}
	}
}
extension MoneroUtils.URIs
{
	struct Requests
	{
		enum URIQueryItemNames: String
		{
			case amount = "tx_amount"
			case description = "tx_description"
			case paymentID = "tx_payment_id"
			case message = "tx_message"
			case amountCurrency = "tx_amount_ccy"
		}
		struct ParsedRequest
		{
			let address: MoneroAddress
			let amount: String?
			let description: String?
			let paymentID: MoneroPaymentID?
			let message: String?
			let amountCurrency: MoneroConvertableCurrencySymbol?
		}
		//
		static func new_URL(
			address: MoneroAddress,
			amount: String?,
			description: String?,
			paymentId: MoneroPaymentID?,
			message: String?,
			amountCurrency: MoneroConvertableCurrencySymbol?,
			uriMode: URIMode
		) -> URL {
			var urlComponents = URLComponents()
			urlComponents.scheme = MoneroConstants.currency_requestURIPrefix_sansColon
			switch uriMode {
				case .addressAsAuthority:
					urlComponents.host = address
				case .addressAsFirstPathComponent:
					urlComponents.path = address
			}
			//
			var queryItems = [URLQueryItem]()
			if let value = amount, value != "" {
				queryItems.append(URLQueryItem(name: URIQueryItemNames.amount.rawValue, value: value))
			}
			if let value = description, value != "" {
				queryItems.append(URLQueryItem(name: URIQueryItemNames.description.rawValue, value: value))
			}
			if let value = paymentId, value != "" {
				queryItems.append(URLQueryItem(name: URIQueryItemNames.paymentID.rawValue, value: value))
			}
			if let value = message, value != "" {
				queryItems.append(URLQueryItem(name: URIQueryItemNames.message.rawValue, value: value))
			}
			if let value = amountCurrency,
				value != "",
				value != MoneroConvertableCurrencySymbol_for_XMR // b/c we don't want to include it in a monero:// URL… if the scheme changes, maybe
			{
				queryItems.append(URLQueryItem(name: URIQueryItemNames.amountCurrency.rawValue, value: value))
			}
			if queryItems.count > 0 {
				urlComponents.queryItems = queryItems // do not set empty or we get superfluous trailing '?'
			}
			let url = urlComponents.url
			//
			return url!
		}
		//
		static func new_parsedRequest(
			fromPossibleURIOrMoneroOrOAAddressString string: String
		) -> (
			err_str: String?,
			parsedRequest: ParsedRequest?
		) {
			// detect no-scheme moneroAddr and possible OA addr - if has no monero: prefix
			if string.hasPrefix(MoneroConstants.currency_requestURIPrefix_sansColon + ":") == false {
				if string.contains("?") { // fairly sure this is correct.. (just an extra failsafe/filter)
					return (NSLocalizedString("Unrecognized URI format", comment: ""), nil)
				}
				let couldBeOAAddress = OpenAlias.containsPeriod_excludingAsXMRAddress_qualifyingAsPossibleOAAddress(string)
				if couldBeOAAddress {
					return (nil, ParsedRequest(address: string, amount: nil, description: nil, paymentID: nil, message: nil, amountCurrency: nil))
				}
				let (err_str, _) = MyMoneroCore.shared_objCppBridge.decoded(address: string)
				if err_str == nil { // then it looks like a monero address
					return (nil, ParsedRequest(address: string, amount: nil, description: nil, paymentID: nil, message: nil, amountCurrency: nil))
				}
				return (NSLocalizedString("No Monero request info", comment: ""), nil)
			}
			guard let final_string = string.addingPercentEncoding( // harden against malformed URIs
				withAllowedCharacters: .urlQueryAllowed
			) else {
				return (err_str: NSLocalizedString("Unable to add percent encoding to QR URI", comment: ""), parsedRequest: nil)
			}
			guard let urlComponents = URLComponents(string: final_string) else {
				return (err_str: NSLocalizedString("Unrecognized URI format", comment: ""), parsedRequest: nil)
			}
			let scheme = urlComponents.scheme
			if scheme != MoneroConstants.currency_requestURIPrefix_sansColon {
				return (err_str: NSLocalizedString("Request URI has non-Monero protocol", comment: ""), parsedRequest: nil)
			}
			var target_address: MoneroAddress // var, as we have to finalize it
			// if the URL has '://' in it instead of ':', path may be empty, but host will contain the address instead
			if urlComponents.host != nil && urlComponents.host != "" {
				target_address = urlComponents.host!
			} else if urlComponents.path != "" {
				target_address = urlComponents.path
			} else {
				return (err_str: NSLocalizedString("Request URI had no target address", comment: ""), parsedRequest: nil)
			}
			var amount: String?
			var description: String?
			var paymentID: MoneroPaymentID?
			var message: String?
			var amountCurrency: MoneroConvertableCurrencySymbol?
			if let queryItems = urlComponents.queryItems { // needs to be parsed it seems
				for (_, queryItem) in queryItems.enumerated() {
					let queryItem_name = queryItem.name
					if let queryItem_value = queryItem.value {
						switch queryItem_name {
							case URIQueryItemNames.amount.rawValue:
								amount = queryItem_value
							case URIQueryItemNames.description.rawValue:
								description = queryItem_value
							case URIQueryItemNames.paymentID.rawValue:
								paymentID = queryItem_value
							case URIQueryItemNames.message.rawValue:
								message = queryItem_value
							case URIQueryItemNames.amountCurrency.rawValue:
								amountCurrency = queryItem_value
							default:
								break
						}
					}
				}
			}
			let parsedRequest = ParsedRequest(
				address: target_address,
				amount: amount,
				description: description,
				paymentID: paymentID,
				message: message,
				amountCurrency: amountCurrency
			)
			//
			return (err_str: nil, parsedRequest: parsedRequest)
		}
	}
}
