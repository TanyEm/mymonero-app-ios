//
//  FundsRequestsCellContentView.swift
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
import UIKit
import CoreImage

class FundsRequestCellQRCodeMatteCells
{
	static let imagePaddingInset = 3
	static let capThickness = Int(FundsRequestCellQRCodeMatteCells.imagePaddingInset + 3)
	static let stretchableImage = UIImage(named: "qrCodeMatteBG_stretchable")!.stretchableImage(
		withLeftCapWidth: FundsRequestCellQRCodeMatteCells.capThickness,
		topCapHeight: FundsRequestCellQRCodeMatteCells.capThickness
	)
}

class FundsRequestsCellContentView: UIView
{
	//
	// Constants
	enum DisplayMode
	{
		case withQRCode
		case noQRCode
	}
	//
	// Properties
	let displayMode: DisplayMode
	//
	let iconView = UICommonComponents.WalletIconView(sizeClass: .large43)
	var qrCodeMatteView: UIImageView?
	var qrCodeImageView: UIImageView?
	//
	let amountLabel = UILabel()
	let memoLabel = UILabel()
	let senderLabel = UILabel()
	//
	var willBeDisplayedWithRightSideAccessoryChevron = true // configurable after init, else also call self.setNeedsLayout
	//
	var walletSwatchColorChanged_handler_token: Any?
	var walletLabelChanged_handler_token: Any?
	//
	// Lifecycle - Init
	init(displayMode: DisplayMode)
	{
		self.displayMode = displayMode
		super.init(frame: .zero)
		self.setup()
	}
	required init?(coder aDecoder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}
	func setup()
	{
		self.addSubview(self.iconView)
		if self.displayMode == .withQRCode {
			self.qrCodeMatteView = UIImageView(image: FundsRequestCellQRCodeMatteCells.stretchableImage)
			self.addSubview(self.qrCodeMatteView!)
			//
			self.qrCodeImageView = UIImageView()
			self.addSubview(self.qrCodeImageView!)
		}
		do {
			let view = self.amountLabel
			view.textColor = UIColor(rgb: 0xFCFBFC)
			view.font = UIFont.middlingSemiboldSansSerif
			view.numberOfLines = 1
			self.addSubview(view)
		}
		do {
			let view = self.memoLabel
			view.textColor = UIColor(rgb: 0x9E9C9E)
			view.font = UIFont.middlingRegularMonospace
			view.numberOfLines = 1
			self.addSubview(view)
		}
		do {
			let view = self.senderLabel
			view.textColor = UIColor(rgb: 0x9E9C9E)
			view.font = UIFont.middlingRegularMonospace
			view.numberOfLines = 1
			view.textAlignment = .right
			view.lineBreakMode = .byTruncatingTail
			self.addSubview(view)
		}
	}
	//
	// Lifecycle - Teardown/Reuse
	deinit
	{
		self.tearDown_object()
	}
	func tearDown_object()
	{
		if self.object != nil {
			self._stopObserving_object()
			self.object = nil
		}
	}
	func prepareForReuse()
	{
		self.tearDown_object()
	}
	func _stopObserving_object()
	{
		self._stopObserving_wallet_ifAnyTokens()
		assert(self.object != nil)
		self.__stopObserving(specificObject: self.object!)
	}
	func _stopObserving(objectBeingDeinitialized object: FundsRequest)
	{
		assert(self.object == nil) // special case - since it's a weak ref I expect self.object to actually be nil
		assert(self.hasStoppedObservingObject_forLastNonNilSetOfObject != true) // initial expectation at least - this might be able to be deleted
		//
		self.__stopObserving(specificObject: object)
	}
	func __stopObserving(specificObject object: FundsRequest)
	{
		if self.hasStoppedObservingObject_forLastNonNilSetOfObject == true {
			// then we've already handled this
			DDLog.Warn("FundsRequestCellContentView", "Not redundantly calling stopObserving")
			return
		}
		self.hasStoppedObservingObject_forLastNonNilSetOfObject = true // must set to true so we can set back to false when object is set back to non-nil
		//
		self._stopObserving_wallet_ifAnyTokens()
		//
		NotificationCenter.default.removeObserver(self, name: PersistableObject.NotificationNames.willBeDeinitialized.notificationName, object: object)
		NotificationCenter.default.removeObserver(self, name: PersistableObject.NotificationNames.willBeDeleted.notificationName, object: object)
	}
	func _stopObserving_wallet_ifAnyTokens()
	{
		if let t = self.walletSwatchColorChanged_handler_token {
			NotificationCenter.default.removeObserver(t)
			self.walletSwatchColorChanged_handler_token = nil
		}
		if let t = self.walletLabelChanged_handler_token {
			NotificationCenter.default.removeObserver(t)
			self.walletLabelChanged_handler_token = nil
		}
	}
	//
	// Accessors
	var givenRecordAndBootedWLC_toWallet_orNil: Wallet? {
		assert(self.object != nil, "Expected self.record != nil by fundsRequest cell givenBooted_toWallet_orNil()")
		if (!WalletsListController.shared.hasBooted) {
			return nil // this actually might happen when tearing down - WLC goes first... but we assume it means self is about to go too
		}
		for (_, o_w) in WalletsListController.shared.records.enumerated() {
			let w = o_w as! Wallet
			if w.public_address == self.object!.to_address {
				return w
			}
		}
		return nil
	}

	//
	// Imperatives - Configuration
	weak var object: FundsRequest? // prevent self from preventing object from being freed so we still get .willBeDeinitialized
	var hasStoppedObservingObject_forLastNonNilSetOfObject = true // I'm using this addtl state var which is not weak b/c object will be niled purely by virtue of it being freed by strong reference holders (other objects)… and I still need to call stopObserving on that object - while also not doing so redundantly - therefore this variable must be set back to false after self.object is set back to non-nil or possibly more rigorously, in startObserving
	func configure(withObject object: FundsRequest)
	{
		if self.object != nil {
			self.prepareForReuse() // in case this is not being used in an actual UITableViewCell (which has a prepareForReuse)
		}
		assert(self.object == nil)
		self.object = object
		self._configureUI()
		self.startObserving_object()
	}
	func _configureUI()
	{
		assert(self.object != nil)
		let object = self.object!
		if self.object!.didFailToInitialize_flag == true || self.object!.didFailToBoot_flag == true { // unlikely but possible
			self.iconView.configure(withSwatchColor: .blue)
			if self.displayMode == .withQRCode {
				self.qrCodeImageView!.image = nil
			}
			self.amountLabel.text = NSLocalizedString("Error: Contact Support", comment: "")
			self.senderLabel.text = ""
			self.memoLabel.text = self.object!.didFailToBoot_errStr ?? ""
		} else {
			let is_displaying_local_wallet = object.is_displaying_local_wallet == true // handle false and nil
			var wallet_ifRecordForQRDisplay: Wallet?
			if is_displaying_local_wallet {
				assert(WalletsListController.shared.hasBooted, "Expected booted WLC")
				for (_, o_w) in WalletsListController.shared.records.enumerated() {
					let w = o_w as! Wallet
					if w.public_address == object.to_address {
						wallet_ifRecordForQRDisplay = w
						break
					}
				}
			}
			assert(
				!is_displaying_local_wallet || wallet_ifRecordForQRDisplay != nil,
				"Expected to find wallet_ifRecordForQRDisplay when is_displaying_local_wallet"
			)
			self.iconView.configure(
				withSwatchColor: is_displaying_local_wallet
					? wallet_ifRecordForQRDisplay!.swatchColor
					: object.to_walletSwatchColor!
			)
			if self.displayMode == .withQRCode {
				self.qrCodeImageView!.image = object.cached__qrCode_image_small
			}
			var amountLabel_text: String!
			if is_displaying_local_wallet {
				amountLabel_text = String(format:
					NSLocalizedString("To \"%@\"", comment: "To \"{wallet name}\""),
					wallet_ifRecordForQRDisplay!.walletLabel!
				)
			} else {
				if object.amount != nil {
					amountLabel_text = String(format:
						NSLocalizedString("%@ %@", comment: "{amount} {currency symbol}"),
						object.amount!,
						(object.amountCurrency ?? "XCASH")
					)
				} else {
					amountLabel_text = NSLocalizedString("Any amount", comment: "")
				}
			}
			self.amountLabel.text = amountLabel_text
			self.senderLabel.text = object.from_fullname ?? "" // appears to be better not to show 'N/A' in else case
			self.memoLabel.text = object.message ?? object.description ?? ""
		}
	}
	//
	func startObserving_object()
	{
		assert(self.object != nil)
		assert(self.hasStoppedObservingObject_forLastNonNilSetOfObject == true) // verify that it was reset back to false
		self.hasStoppedObservingObject_forLastNonNilSetOfObject = false // set to false so we make sure to stopObserving
		NotificationCenter.default.addObserver(self, selector: #selector(_willBeDeinitialized(_:)), name: PersistableObject.NotificationNames.willBeDeinitialized.notificationName, object: self.object!)
		NotificationCenter.default.addObserver(self, selector: #selector(_willBeDeleted), name: PersistableObject.NotificationNames.willBeDeleted.notificationName, object: self.object!)
		//
		if self.walletSwatchColorChanged_handler_token != nil || self.walletLabelChanged_handler_token != nil {
			self._stopObserving_wallet_ifAnyTokens()
		}
		if let w = self.givenRecordAndBootedWLC_toWallet_orNil {
			self.walletSwatchColorChanged_handler_token = NotificationCenter.default.addObserver(
				forName: Wallet.NotificationNames.swatchColorChanged.notificationName,
				object: w,
				queue: nil
			) { [weak self] (note) in
				guard let thisSelf = self else {
					return
				}
				thisSelf._configureUI()
			}
			self.walletLabelChanged_handler_token = NotificationCenter.default.addObserver(
				forName: Wallet.NotificationNames.labelChanged.notificationName,
				object: w,
				queue: nil
			) { [weak self] (note) in
				guard let thisSelf = self else {
					return
				}
				thisSelf._configureUI()
			}
		}
	}
	//
	// Imperatives - Overrides
	override func layoutSubviews()
	{
		super.layoutSubviews()
		self.iconView.frame = CGRect(
			x: 16,
			y: 16,
			width: self.iconView.frame.size.width,
			height: self.iconView.frame.size.height
		)
		if self.displayMode == .withQRCode {
			do {
				let visual__side = 24
				let side = visual__side + 2*FundsRequestCellQRCodeMatteCells.imagePaddingInset
				let visual__x = 36
				let visual__y = 36
				self.qrCodeMatteView!.frame = CGRect(
					x: visual__x - FundsRequestCellQRCodeMatteCells.imagePaddingInset,
					y: visual__y - FundsRequestCellQRCodeMatteCells.imagePaddingInset,
					width: side,
					height: side
				)
				//
				let qrCodeInset: CGFloat = 2
				self.qrCodeImageView!.frame = self.qrCodeMatteView!.frame.insetBy(
					dx: CGFloat(FundsRequestCellQRCodeMatteCells.imagePaddingInset) + qrCodeInset,
					dy: CGFloat(FundsRequestCellQRCodeMatteCells.imagePaddingInset) + qrCodeInset
				)
			}
		}
		let labels_x: CGFloat = self.iconView.frame.origin.x + self.iconView.frame.size.width + 20
		let labels_rightMargin: CGFloat = self.willBeDisplayedWithRightSideAccessoryChevron ? 40 : 16
		let labels_width = self.frame.size.width - labels_x - labels_rightMargin
		self.amountLabel.frame = CGRect(
			x: labels_x,
			y: 22,
			width: labels_width,
			height: 16
		).integral
		self.amountLabel.sizeToFit()
		self.amountLabel.frame = CGRect( // to constrain max width
			x: self.amountLabel.frame.origin.x,
			y: self.amountLabel.frame.origin.y,
			width: min(labels_width, self.amountLabel.frame.size.width),
			height: self.amountLabel.frame.size.height
		).integral
		do {
			let amountLabelAndMargin_portionOf_labels_width = self.amountLabel.frame.size.width + 12
			let senderLabel_x = self.amountLabel.frame.origin.x + amountLabelAndMargin_portionOf_labels_width
			self.senderLabel.frame = CGRect(
				x: senderLabel_x,
				y: 22,
				width: labels_width - amountLabelAndMargin_portionOf_labels_width,
				height: 16
			).integral
		}
		self.memoLabel.frame = CGRect(
			x: labels_x,
			y: self.amountLabel.frame.origin.y + self.amountLabel.frame.size.height + 2,
			width: labels_width,
			height: 20
		).integral
	}
	//
	// Delegation
	@objc func _willBeDeleted()
	{
		self.tearDown_object() // stopObserving/release
	}
	@objc func _willBeDeinitialized(_ note: Notification)
	{ // This obviously doesn't work for calling stopObserving on self.object --- because self.object is nil by the time we get here!!
		let objectBeingDeinitialized = note.userInfo![PersistableObject.NotificationUserInfoKeys.object.key] as! FundsRequest
		self._stopObserving( // stopObserving specific object - self.object will be nil by now - but also call specific method for this as it has addtl check
			objectBeingDeinitialized: objectBeingDeinitialized
		)
	}
}
