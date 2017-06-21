//
//  UseExisting_MetaInfo_ViewController.swift
//  MyMonero
//
//  Created by Paul Shapiro on 6/18/17.
//  Copyright © 2017 MyMonero. All rights reserved.
//

import UIKit

class UseExisting_MetaInfo_ViewController: AddWalletWizardScreen_MetaInfo_BaseViewController
{
	//
	// Types/Constants
	enum LoginWith_Mode
	{
		case mnemonicSeed
		case addrAndPrivKeys
		//
		var titleForModeToggleButtonInModeSelf: String
		{
			switch self {
				case .mnemonicSeed:
					return NSLocalizedString("Address and Private Keys", comment: "")
				case .addrAndPrivKeys:
					return NSLocalizedString("Secret Mnemonic", comment: "")
			}
		}
		var otherMode: LoginWith_Mode
		{
			switch self {
				case .mnemonicSeed:
					return .addrAndPrivKeys
				case .addrAndPrivKeys:
					return .mnemonicSeed
			}
		}
	}
	//
	// Properties - Model/state
	var loginWith_mode: LoginWith_Mode = .mnemonicSeed // initial state
	// Properties - Subviews
	var walletMnemonic_label: UICommonComponents.FormLabel!
	var walletMnemonic_inputView: UICommonComponents.FormTextViewContainerView!
	//
	var addr_label: UICommonComponents.FormLabel!
	var addr_inputView: UICommonComponents.FormTextViewContainerView!
	var viewKey_label: UICommonComponents.FormLabel!
	var viewKey_inputView: UICommonComponents.FormTextViewContainerView!
	var spendKey_label: UICommonComponents.FormLabel!
	var spendKey_inputView: UICommonComponents.FormTextViewContainerView!
	//
	var orUse_label: UICommonComponents.FormFieldAccessoryMessageLabel!
	var orUse_button: UICommonComponents.LinkButtonView!
	//
	// Lifecycle - Init
	override func setup()
	{
		super.setup()
		self.configureWith_loginWithMode() // b/c this touches the nav bar btn items
	}
	override func setup_views()
	{
		super.setup_views()
		//
		do { // .mnemonicSeed
			do {
				let view = UICommonComponents.FormLabel(
					title: NSLocalizedString("SECRET MNEMONIC", comment: ""),
					sizeToFit: true
				)
				self.walletMnemonic_label = view
				self.view.addSubview(view)
			}
			do {
				let view = UICommonComponents.FormTextViewContainerView(
					placeholder: NSLocalizedString("From your existing wallet", comment: "")
				)
				view.textView.autocorrectionType = .no
				view.textView.autocapitalizationType = .none
				view.textView.spellCheckingType = .no
				view.textView.returnKeyType = .next
//				view.addTarget(self, action: #selector(aPasswordField_editingChanged), for: .editingChanged)
//				view.delegate = self
				self.walletMnemonic_inputView = view
				self.view.addSubview(view)
			}
		}
		do { // .addrAndPrivKeys
			do {
				let view = UICommonComponents.FormLabel(
					title: NSLocalizedString("ADDRESS", comment: ""),
					sizeToFit: true
				)
				self.addr_label = view
				self.view.addSubview(view)
			}
			do {
				let view = UICommonComponents.FormTextViewContainerView(
					placeholder: nil
				)
				view.textView.autocorrectionType = .no
				view.textView.autocapitalizationType = .none
				view.textView.spellCheckingType = .no
				view.textView.returnKeyType = .next
//				view.addTarget(self, action: #selector(aPasswordField_editingChanged), for: .editingChanged)
//				view.delegate = self
				self.addr_inputView = view
				self.view.addSubview(view)
			}
			//
			do {
				let view = UICommonComponents.FormLabel(
					title: NSLocalizedString("VIEW KEY", comment: ""),
					sizeToFit: true
				)
				self.viewKey_label = view
				self.view.addSubview(view)
			}
			do {
				let view = UICommonComponents.FormTextViewContainerView(
					placeholder: nil
				)
				view.textView.autocorrectionType = .no
				view.textView.autocapitalizationType = .none
				view.textView.spellCheckingType = .no
				view.textView.returnKeyType = .next
//				view.addTarget(self, action: #selector(aPasswordField_editingChanged), for: .editingChanged)
//				view.delegate = self
				self.viewKey_inputView = view
				self.view.addSubview(view)
			}
			//
			do {
				let view = UICommonComponents.FormLabel(
					title: NSLocalizedString("SPEND KEY", comment: ""),
					sizeToFit: true
				)
				self.spendKey_label = view
				self.view.addSubview(view)
			}
			do {
				let view = UICommonComponents.FormTextViewContainerView(
					placeholder: nil
				)
				view.textView.autocorrectionType = .no
				view.textView.autocapitalizationType = .none
				view.textView.spellCheckingType = .no
				view.textView.returnKeyType = .next
//				view.addTarget(self, action: #selector(aPasswordField_editingChanged), for: .editingChanged)
//				view.delegate = self
				self.spendKey_inputView = view
				self.view.addSubview(view)
			}
		}
		do {
			let view = UICommonComponents.FormFieldAccessoryMessageLabel(
				text: NSLocalizedString("Or, use ", comment: "")
			)
			self.orUse_label = view
			self.view.addSubview(view)
		}
		do {
			let view = UICommonComponents.LinkButtonView(mode: .mono_default, title: "") // title will be set in configureWith_loginWithMode()
			view.addTarget(self, action: #selector(orUse_button_tapped), for: .touchUpInside)
			self.orUse_button = view
			self.view.addSubview(view)
		}
		//
//		self.view.borderSubviews()
	}
	override func setup_navigation()
	{
		super.setup_navigation()
		self.navigationItem.title = "Log Into Your Wallet"
		if self.wizardController.current_wizardTaskMode == .firstTime_useExisting { // only if it is, add cancel btn
			self.navigationItem.leftBarButtonItem = UICommonComponents.NavigationBarButtonItem(
				type: .cancel,
				target: self,
				action: #selector(tapped_barButtonItem_cancel)
			)
		}
	}
	//
	// Accessors - Overrides
	override func new_isFormSubmittable() -> Bool
	{
		guard let walletLabel = self.walletLabel_inputView.text, walletLabel != "" else {
			return false
		}
		switch self.loginWith_mode {
			case .mnemonicSeed:
				guard let walletMnemonic = self.walletMnemonic_inputView.textView.text, walletMnemonic != "" else {
					return false
				}
				break
			case .addrAndPrivKeys:
				guard let addr = self.addr_inputView.textView.text, addr != "" else {
					return false
				}
				guard let viewKey = self.viewKey_inputView.textView.text, viewKey != "" else {
					return false
				}
				guard let spendKey = self.spendKey_inputView.textView.text, spendKey != "" else {
					return false
				}
				break
		}
		return true
	}
	//
	// Imperatives
	func toggle_loginWithMode()
	{
		self.loginWith_mode = self.loginWith_mode.otherMode // toggle
		self.configureWith_loginWithMode()
	}
	func configureWith_loginWithMode()
	{
		self.orUse_button.setTitleText(to: self.loginWith_mode.titleForModeToggleButtonInModeSelf)
		//
		switch self.loginWith_mode {
			case .mnemonicSeed:
				self.walletMnemonic_label.isHidden = false
				self.walletMnemonic_inputView.textView.text = ""
				self.walletMnemonic_inputView.isHidden = false
				//
				self.addr_label.isHidden = true
				self.addr_inputView.isHidden = true
				self.viewKey_label.isHidden = true
				self.viewKey_inputView.isHidden = true
				self.spendKey_label.isHidden = true
				self.spendKey_inputView.isHidden = true
				//
				DispatchQueue.main.async { // dispatching on next tick so as to simulate same effect as viewDidAppear
					self.walletMnemonic_inputView.textView.becomeFirstResponder()
				}
				break
			case .addrAndPrivKeys:
				self.walletMnemonic_label.isHidden = true
				self.walletMnemonic_inputView.isHidden = true
				//
				self.addr_inputView.textView.text = ""
				self.addr_label.isHidden = false
				self.addr_inputView.isHidden = false
				self.addr_inputView.setNeedsDisplay() // necessary so view calls draw(rect:) with correct frame
				self.viewKey_inputView.textView.text = ""
				self.viewKey_label.isHidden = false
				self.viewKey_inputView.isHidden = false
				self.viewKey_inputView.setNeedsDisplay() // necessary so view calls draw(rect:) with correct frame
				self.spendKey_inputView.textView.text = ""
				self.spendKey_label.isHidden = false
				self.spendKey_inputView.isHidden = false
				self.spendKey_inputView.setNeedsDisplay() // necessary so view calls draw(rect:) with correct frame
				//
				DispatchQueue.main.async {
					self.addr_inputView.textView.becomeFirstResponder()
				}
				break
		}
		do {
			self.set_isFormSubmittable_needsUpdate()
			self.view.setNeedsLayout() // to lay out again
		}
	}
	//
	// Delegation - Interactions
	func tapped_barButtonItem_cancel()
	{
		self.wizardController._fromScreen_userPickedCancel()
	}
	@objc func orUse_button_tapped()
	{
		self.toggle_loginWithMode()
	}
	//
	// Delegation - Internal - Overrides
	override func _viewControllerIsBeingPoppedFrom()
	{ // this could only get popped from when it's not the first in the nav stack, i.e. not adding first wallet,
		// so we'll need to get back into .pickCreateOrUseExisting
		self.wizardController.patchToDifferentWizardTaskMode_withoutPushingScreen( // to maintain the correct state
			patchTo_wizardTaskMode: .pickCreateOrUseExisting,
			atIndex: 0 // back to 0 from 1
		)
	}
	//
	// Delegation - View
	override func viewDidLayoutSubviews()
	{
		super.viewDidLayoutSubviews()
		//
		let topPadding: CGFloat = 13
		let textField_w = self.new__textField_w
		//
		var viewAbove_orUse_label: UIView!
		switch self.loginWith_mode {
			case .mnemonicSeed:
				viewAbove_orUse_label = self.walletMnemonic_inputView
				//
				self.walletMnemonic_label.frame = CGRect(
					x: CGFloat.form_label_margin_x,
					y: topPadding,
					width: textField_w,
					height: self.walletMnemonic_label.frame.size.height
				).integral
				self.walletMnemonic_inputView.frame = CGRect(
					x: CGFloat.form_input_margin_x,
					y: self.walletMnemonic_label.frame.origin.y + self.walletMnemonic_label.frame.size.height + UICommonComponents.FormLabel.marginBelowLabelAboveTextInputView,
					width: textField_w,
					height: self.walletMnemonic_inputView.frame.size.height
				).integral
				break
			case .addrAndPrivKeys:
				viewAbove_orUse_label = self.spendKey_inputView
				//
				self.addr_label.frame = CGRect(
					x: CGFloat.form_label_margin_x,
					y: topPadding,
					width: textField_w,
					height: self.addr_label.frame.size.height
				).integral
				self.addr_inputView.frame = CGRect(
					x: CGFloat.form_input_margin_x,
					y: self.addr_label.frame.origin.y + self.addr_label.frame.size.height + UICommonComponents.FormLabel.marginBelowLabelAboveTextInputView,
					width: textField_w,
					height: self.addr_inputView.frame.size.height
				).integral
				//
				self.viewKey_label.frame = CGRect(
					x: CGFloat.form_label_margin_x,
					y: self.addr_inputView.frame.origin.y + self.addr_inputView.frame.size.height + UICommonComponents.FormLabel.marginAboveLabelForUnderneathField_textInputView,
					width: textField_w,
					height: self.viewKey_label.frame.size.height
				).integral
				self.viewKey_inputView.frame = CGRect(
					x: CGFloat.form_input_margin_x,
					y: self.viewKey_label.frame.origin.y + self.viewKey_label.frame.size.height + UICommonComponents.FormLabel.marginBelowLabelAboveTextInputView,
					width: textField_w,
					height: self.viewKey_inputView.frame.size.height
				).integral
				//
				self.spendKey_label.frame = CGRect(
					x: CGFloat.form_label_margin_x,
					y: self.viewKey_inputView.frame.origin.y + self.viewKey_inputView.frame.size.height + UICommonComponents.FormLabel.marginAboveLabelForUnderneathField_textInputView,
					width: textField_w,
					height: self.spendKey_label.frame.size.height
				).integral
				self.spendKey_inputView.frame = CGRect(
					x: CGFloat.form_input_margin_x,
					y: self.spendKey_label.frame.origin.y + self.spendKey_label.frame.size.height + UICommonComponents.FormLabel.marginBelowLabelAboveTextInputView,
					width: textField_w,
					height: self.spendKey_inputView.frame.size.height
				).integral
				break
		}
		do {
			self.orUse_label.frame = CGRect(
				x: CGFloat.form_label_margin_x,
				y: viewAbove_orUse_label.frame.origin.y + viewAbove_orUse_label.frame.size.height - 1, // -1 cause we set height to 24
				width: 46,
				height: 24
			).integral
			self.orUse_button.frame = CGRect(
				x: self.orUse_label.frame.origin.x + self.orUse_label.frame.size.width + 6,
				y: self.orUse_label.frame.origin.y,
				width: 0,
				height: 24
			)
			self.orUse_button.sizeToFit()
		}
		self.layOut_walletLabelAndSwatchFields(atYOffset: self.orUse_label.frame.origin.y + self.orUse_label.frame.size.height)
		//
		self.formContentSizeDidChange(withBottomView: self.walletColorPicker_inputView, bottomPadding: topPadding)
	}
}
