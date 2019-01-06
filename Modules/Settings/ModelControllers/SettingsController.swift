//
//  SettingsController.swift
//  MyMonero
//
//  Created by Paul Shapiro on 6/15/17.
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

class SettingsController: DeleteEverythingRegistrant, ChangePasswordRegistrant
{
	enum NotificationNames_Changed: String
	{
		case specificAPIAddressURLAuthority = "SettingsController_NotificationNames_Changed_specificAPIAddressURLAuthority"
		case appTimeoutAfterS_nilForDefault_orNeverValue = "SettingsController_NotificationNames_Changed_appTimeoutAfterS_nilForDefault_orNeverValue"
		case displayCurrencySymbol = "SettingsController_NotificationNames_Changed_displayCurrencySymbol"
		case authentication__requireWhenSending = "SettingsController_NotificationNames_Changed_authentication__requireWhenSending"
		case authentication__requireToShowWalletSecrets = "SettingsController_NotificationNames_Changed_authentication__requireToShowWalletSecrets"
		case authentication__tryBiometric = "SettingsController_NotificationNames_Changed_authentication__tryBiometric"
		//
		var notificationName: NSNotification.Name {
			return NSNotification.Name(self.rawValue)
		}
	}
	//
	static let appTimeoutAfterS_neverValue: TimeInterval = -1
	//
	// Constants/Types - Persistence
	let collectionName = "Settings"
	enum DictKey: String
	{
		case _id = "_id"
		case specificAPIAddressURLAuthority = "specificAPIAddressURLAuthority"
		case appTimeoutAfterS_nilForDefault_orNeverValue = "appTimeoutAfterS_nilForDefault_orNeverValue"
		case displayCurrencySymbol = "displayCurrencySymbol"
		case authentication__requireWhenSending = "authentication__requireWhenSending"
		case authentication__requireToShowWalletSecrets = "authentication__requireToShowWalletSecrets"
		case authentication__tryBiometric = "authentication__tryBiometric"
		//
		var changed_notificationName: NSNotification.Name?
		{
			switch self {
				case .specificAPIAddressURLAuthority:
					return NotificationNames_Changed.specificAPIAddressURLAuthority.notificationName
				case .appTimeoutAfterS_nilForDefault_orNeverValue:
					return NotificationNames_Changed.appTimeoutAfterS_nilForDefault_orNeverValue.notificationName
				case .displayCurrencySymbol:
					return NotificationNames_Changed.displayCurrencySymbol.notificationName
				case .authentication__requireWhenSending:
					return NotificationNames_Changed.authentication__requireWhenSending.notificationName
				case .authentication__requireToShowWalletSecrets:
					return NotificationNames_Changed.authentication__requireToShowWalletSecrets.notificationName
				case .authentication__tryBiometric:
					return NotificationNames_Changed.authentication__tryBiometric.notificationName
				case ._id:
					assert(false)
					// _id is not to be updated
					return nil
			}
		}
	}
	let setForbidden_DictKeys: [DictKey] = [ ._id ]
	//
	// Constants - Default values
	let default_appTimeoutAfterS: TimeInterval = 90 // s …… 30 was a bit short for new users
	var default_displayCurrencySymbol: CcyConversionRates.CurrencySymbol {
		return CcyConversionRates.Currency.XCASH.symbol // for now...? mayyyybe detect by locale and try to guess? but that could end up being too inaccurate. language es could appear in Venezualan users and i wouldn't think MXN would be super helpful there - but i have no data on it
	}
	let default_authentication__requireWhenSending = true
	let default_authentication__requireToShowWalletSecrets = true
	let default_authentication__tryBiometric = true
	//
	// Properties - Runtime - Transient
	var hasBooted = false
	var instanceUUID = UUID()
	func identifier() -> String { // satisfy DeleteEverythingRegistrant for isEqual
		return self.instanceUUID.uuidString
	}
	//
	// Properties - Runtime - Persisted
	var _id: DocumentPersister.DocumentId?
	var specificAPIAddressURLAuthority: String?
	var appTimeoutAfterS_nilForDefault_orNeverValue: TimeInterval?
	var authentication__requireWhenSending: Bool!
	var authentication__requireToShowWalletSecrets: Bool!
	var authentication__tryBiometric: Bool!
	var displayCurrencySymbol: CcyConversionRates.CurrencySymbol!
	var displayCurrency: CcyConversionRates.Currency {
		return CcyConversionRates.Currency(rawValue: self.displayCurrencySymbol)!
	}
	//
	// Lifecycle - Singleton Init
	static let shared = SettingsController()
	private init()
	{
		self.setup()
	}
	func setup()
	{
		PasswordController.shared.addRegistrantForDeleteEverything(self)
		PasswordController.shared.addRegistrantForChangePassword(self)
		//
		let (err_str, documentJSONs) = DocumentPersister.shared.AllDocuments(inCollectionNamed: self.collectionName)
		if err_str != nil {
			assert(false, "Error: \(err_str!.debugDescription)")
			return
		}
		let documentJSONs_count = documentJSONs!.count
		if documentJSONs_count > 1 {
			assert(false, "Invalid Settings data state - more than one document")
			return
		}
		if documentJSONs_count == 0 {
			self._setup_loadState(
				_id: nil,
				specificAPIAddressURLAuthority: nil,
				appTimeoutAfterS_nilForDefault_orNeverValue: self.default_appTimeoutAfterS,
				authentication__requireWhenSending: self.default_authentication__requireWhenSending,
				authentication__requireToShowWalletSecrets: self.default_authentication__requireToShowWalletSecrets,
				authentication__tryBiometric: self.default_authentication__tryBiometric,
				displayCurrencySymbol: self.default_displayCurrencySymbol
			)
			return
		}
		let jsonDict = documentJSONs![0]
		let _id = jsonDict[DictKey._id.rawValue] as! DocumentPersister.DocumentId
		let specificAPIAddressURLAuthority = jsonDict[DictKey.specificAPIAddressURLAuthority.rawValue] as? String
		let appTimeoutAfterS_nilForDefault_orNeverValue = jsonDict[DictKey.appTimeoutAfterS_nilForDefault_orNeverValue.rawValue] as! TimeInterval
		let authentication__requireWhenSending = jsonDict[DictKey.authentication__requireWhenSending.rawValue] as? Bool
		let authentication__requireToShowWalletSecrets = jsonDict[DictKey.authentication__requireToShowWalletSecrets.rawValue] as? Bool
		let authentication__tryBiometric = jsonDict[DictKey.authentication__tryBiometric.rawValue] as? Bool
		let displayCurrencySymbol = jsonDict[DictKey.displayCurrencySymbol.rawValue] as? CcyConversionRates.CurrencySymbol
		self._setup_loadState(
			_id: _id,
			specificAPIAddressURLAuthority: specificAPIAddressURLAuthority,
			appTimeoutAfterS_nilForDefault_orNeverValue: appTimeoutAfterS_nilForDefault_orNeverValue,
			authentication__requireWhenSending: authentication__requireWhenSending != nil ? authentication__requireWhenSending! : default_authentication__requireWhenSending,
			authentication__requireToShowWalletSecrets: authentication__requireToShowWalletSecrets != nil ? authentication__requireToShowWalletSecrets! : default_authentication__requireToShowWalletSecrets,
			authentication__tryBiometric: authentication__tryBiometric != nil ? authentication__tryBiometric! : default_authentication__tryBiometric,
			displayCurrencySymbol: displayCurrencySymbol ?? default_displayCurrencySymbol /*legacy/prerelease dict*/
		)
	}
	func _setup_loadState(
		_id: DocumentPersister.DocumentId?,
		specificAPIAddressURLAuthority: String?,
		appTimeoutAfterS_nilForDefault_orNeverValue: TimeInterval,
		authentication__requireWhenSending: Bool,
		authentication__requireToShowWalletSecrets: Bool,
		authentication__tryBiometric: Bool,
		displayCurrencySymbol: CcyConversionRates.CurrencySymbol
	) {
		self._id = _id
		self.specificAPIAddressURLAuthority = specificAPIAddressURLAuthority
		self.appTimeoutAfterS_nilForDefault_orNeverValue = appTimeoutAfterS_nilForDefault_orNeverValue
		self.authentication__requireWhenSending = authentication__requireWhenSending
		self.authentication__requireToShowWalletSecrets = authentication__requireToShowWalletSecrets
		self.authentication__tryBiometric = authentication__tryBiometric
		self.displayCurrencySymbol = displayCurrencySymbol
		//
		self.hasBooted = true
	}
	//
	// Lifecycle - Teardown
	deinit
	{
		self.teardown()
	}
	func teardown()
	{
		self.stopObserving()
	}
	func stopObserving()
	{
		PasswordController.shared.removeRegistrantForDeleteEverything(self)
		PasswordController.shared.removeRegistrantForChangePassword(self)
	}
	//
	// Imperatives - Setting values
	func set(valuesByDictKey: [DictKey: Any]) -> String? // err_str
	{
		// configure
		for (key, raw_value) in valuesByDictKey {
			if self.setForbidden_DictKeys.contains(key) == true {
				assert(false)
			}
			let/*var*/ value: Any? = raw_value
// TODO: this is commented b/c it might demonstrate a Swift bug.. or a lacking in my understanding?
//			do { // to finalize
//				switch key {
//					case .specificAPIAddressURLAuthority:
//						if value != nil {
//							if (value as! String) == "" { // this crashes when value is nil via user clearing text field
//								value = nil
//							}
//						}
//						break
//					default:
//						break // nothing to do
//				}
//			}
			self._set(value: value, forPropertyWithDictKey: key)
		}
		// save
		let err_str = self.saveToDisk()
		if err_str != nil {
			return err_str
		}
		// notify
		DispatchQueue.main.async
		{
			for (key, _) in valuesByDictKey {
				NotificationCenter.default.post(name: key.changed_notificationName!, object: nil)
			}
		}
		return nil
	}
	private func _set(value: Any?, forPropertyWithDictKey dictKey: DictKey)
	{
		switch dictKey {
			case ._id: // not used - but for exhaustiveness
				assert(false)
				break
			case .appTimeoutAfterS_nilForDefault_orNeverValue:
				self.appTimeoutAfterS_nilForDefault_orNeverValue = value as? TimeInterval // nil means 'use default idle time' and -1 means 'disable idle timer'; luckily TimeInterval can be negative
				break
			case .authentication__requireWhenSending:
				self.authentication__requireWhenSending = value as? Bool ?? self.default_authentication__requireWhenSending // nil will get default set
				break
			case .authentication__requireToShowWalletSecrets:
				self.authentication__requireToShowWalletSecrets = value as? Bool ?? self.default_authentication__requireToShowWalletSecrets // nil will get default set
				break
			case .authentication__tryBiometric:
				self.authentication__tryBiometric = value as? Bool ?? self.default_authentication__tryBiometric // nil gets default set
			case .displayCurrencySymbol:
				self.displayCurrencySymbol = value as? CcyConversionRates.CurrencySymbol // validate?
				break
			case .specificAPIAddressURLAuthority:
				self.specificAPIAddressURLAuthority = value as? String
				break
		}
	}
	//
	// Imperatives - Setters - Convenience - Single-property (for form)
	func set(specificAPIAddressURLAuthority value: String?) -> String? // err_str
	{
		return self.set(valuesByDictKey: [ DictKey.specificAPIAddressURLAuthority: value as Any ])
	}
	func set(appTimeoutAfterS_nilForDefault_orNeverValue value: TimeInterval?) -> String? // err_str; use nil for 'never', not for resetting to default
	{
		return self.set(valuesByDictKey: [ DictKey.appTimeoutAfterS_nilForDefault_orNeverValue: value as Any ])
	}
	func set(authentication__requireWhenSending value: Bool) -> String? // err_str
	{
		return self.set(valuesByDictKey: [ DictKey.authentication__requireWhenSending: value as Any ])
	}
	func set(authentication__requireToShowWalletSecrets value: Bool) -> String? // err_str
	{
		return self.set(valuesByDictKey: [ DictKey.authentication__requireToShowWalletSecrets: value as Any ])
	}
	func set(authentication__tryBiometric value: Bool) -> String? // err_str
	{
		return self.set(valuesByDictKey: [ DictKey.authentication__tryBiometric: value as Any ])
	}
	func set(displayCurrencySymbol_nilForDefault value: CcyConversionRates.CurrencySymbol?) -> String? // err_str; use nil for default
	{
		return self.set(valuesByDictKey: [ DictKey.displayCurrencySymbol: value as Any ])
	}
	//
	// Accessors - Persistence
	var shouldInsertNotUpdate: Bool
	{
		return self._id == nil
	}
	func new_dictRepresentation() -> DocumentPersister.DocumentJSON
	{
		var dict: [String: Any] = [:]
		dict[DictKey._id.rawValue] = self._id
		if let value = self.specificAPIAddressURLAuthority {
			dict[DictKey.specificAPIAddressURLAuthority.rawValue] = value
		}
		if let value = self.appTimeoutAfterS_nilForDefault_orNeverValue {
			dict[DictKey.appTimeoutAfterS_nilForDefault_orNeverValue.rawValue] = value
		}
		if let value = self.authentication__requireWhenSending {
			dict[DictKey.authentication__requireWhenSending.rawValue] = value
		}
		if let value = self.authentication__requireToShowWalletSecrets {
			dict[DictKey.authentication__requireToShowWalletSecrets.rawValue] = value
		}
		if let value = self.authentication__tryBiometric {
			dict[DictKey.authentication__tryBiometric.rawValue] = value
		}
		if let value = self.displayCurrencySymbol {
			dict[DictKey.displayCurrencySymbol.rawValue] = value
		}
		//
		// Note: Override this method and add data you would like encrypted – but call on super
		return dict as DocumentPersister.DocumentJSON
	}
	//
	// Imperatives - Saving
	func saveToDisk() -> String? // -> err_str?
	{
		if self.shouldInsertNotUpdate == true {
			return self._saveToDisk_insert()
		}
		return self._saveToDisk_update()
	}
	// For these, we presume consumers/parents/instantiators have only created this wallet if they have gotten the password
	func _saveToDisk_insert() -> String? // -> err_str?
	{
		assert(self._id == nil, "non-nil _id in \(#function)")
		// only generate _id here after checking shouldInsertNotUpdate since that relies on _id
		self._id = DocumentPersister.new_DocumentId() // generating a new UUID
		// Note: not encrypting server URL b/c based on flow of app, it needs to be able to be set before adding a wallet, which is where first pw entry happens.
		//
		return self.__saveToDisk_write()
	}
	func _saveToDisk_update() -> String?
	{
		assert(self._id != nil, "nil _id in \(#function)")
		//
		return self.__saveToDisk_write()
	}
	func __saveToDisk_write() -> String?
	{
		let dict = self.new_dictRepresentation() // plaintext
		do {
			let plaintextData =  try JSONSerialization.data(
				withJSONObject: dict,
				options: []
			)
			let err_str = DocumentPersister.shared.Write(
				documentFileWithData: plaintextData,
				withId: self._id!,
				toCollectionNamed: self.collectionName
			)
			if err_str != nil {
				DDLog.Error("Persistence", "Error while saving new object: \(err_str!)")
			} else {
				DDLog.Done("Persistence", "Saved \(self).")
			}
			return err_str
		} catch let e {
			return e.localizedDescription
		}
	}
	//
	// Protocol - DeleteEverythingRegistrant
	func passwordController_DeleteEverything() -> String?
	{
		let defaults_valuesByKey: [DictKey: Any] =
		[
			.specificAPIAddressURLAuthority: "",
			.appTimeoutAfterS_nilForDefault_orNeverValue: default_appTimeoutAfterS,
			.authentication__requireWhenSending: default_authentication__requireWhenSending,
			.authentication__requireToShowWalletSecrets: default_authentication__requireToShowWalletSecrets,
			.authentication__tryBiometric: default_authentication__tryBiometric,
			.displayCurrencySymbol: self.default_displayCurrencySymbol
		]
		let err_str = self.set(valuesByDictKey: defaults_valuesByKey)
		//
		return err_str
	}
	//
	// Delegation - ChangePasswordRegistrant
	func passwordController_ChangePassword() -> String?
	{
		if self.hasBooted != true {
			DDLog.Warn("Settings", "\(self) asked to change password but not yet booted.")
			return "Asked to change password but not yet booted" // not ready to get this
		}
		return self.saveToDisk()
	}
}
