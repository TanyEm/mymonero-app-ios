//
//  SettingsFormViewController.swift
//  MyMonero
//
//  Created by Paul Shapiro on 8/3/17.
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
//
class SettingsFormViewController: UICommonComponents.FormViewController, SettingsAppTimeoutAfterSecondsSliderInteractionsDelegate, DeleteEverythingRegistrant
{
	//
	// Static - Shared
	static let shared = SettingsFormViewController()
	//
	// Properties/Protocols - DeleteEverythingRegistrant
	var instanceUUID = UUID()
	func identifier() -> String { // satisfy DeleteEverythingRegistrant for isEqual
		return self.instanceUUID.uuidString
	}
	//
	// Properties - Views
	var changePasswordButton = UICommonComponents.InlineButton(inlineButtonType: .utility)
	//
	var appTimeoutAfterS_label: UICommonComponents.Form.FieldLabel!
	var appTimeoutAfterS_inputView: SettingsAppTimeoutAfterSecondsSliderInputView!
	var appTimeoutAfterS_fieldAccessoryMessageLabel: UICommonComponents.FormFieldAccessoryMessageLabel!
	//
	var displayCurrency_label: UICommonComponents.Form.FieldLabel!
	var displayCurrency_inputView: UICommonComponents.Form.StringPicker.PickerButtonFieldView!
	//
	var authentication_label: UICommonComponents.Form.FieldLabel!
	var authentication_tooltipSpawn_buttonView: UICommonComponents.TooltipSpawningLinkButtonView!
	var whenSendingMoney_inputView: UICommonComponents.Form.Switches.TitleAndControlField!
	var toShowWalletSecrets_inputView: UICommonComponents.Form.Switches.TitleAndControlField!
	var tryBiometric_inputView: UICommonComponents.Form.Switches.TitleAndControlField!
	//
	var address_label: UICommonComponents.Form.FieldLabel!
	var address_inputView: UICommonComponents.FormInputField!
	var resolving_activityIndicator: UICommonComponents.GraphicAndLabelActivityIndicatorView!
	//
	var deleteButton: UICommonComponents.LinkButtonView!
	//
	// Lifecycle - Init
	override init()
	{
		super.init()
	}
	required init?(coder aDecoder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}
	override func startObserving()
	{
		super.startObserving()
		PasswordController.shared.addRegistrantForDeleteEverything(self)
	}
	override func setup_views()
	{
		super.setup_views()
		//
		do {
			let view = self.changePasswordButton
			view.addTarget(self, action: #selector(changePasswordButton_tapped), for: .touchUpInside)
			self.scrollView.addSubview(view)
		}
		//
		do {
			let view = UICommonComponents.Form.FieldLabel(
				title: NSLocalizedString("APP TIMEOUT", comment: "")
			)
			self.appTimeoutAfterS_label = view
			self.scrollView.addSubview(view)
		}
		do {
			let view = SettingsAppTimeoutAfterSecondsSliderInputView()
			view.slider.interactionsDelegate = self
			self.appTimeoutAfterS_inputView = view
			self.scrollView.addSubview(view)
		}
		do {
			let view = UICommonComponents.FormFieldAccessoryMessageLabel(
				text: "" // this will be set on viewWillAppear
			)
			self.appTimeoutAfterS_fieldAccessoryMessageLabel = view
			self.scrollView.addSubview(view)
		}
		//
		do {
			let view = UICommonComponents.Form.FieldLabel(
				title: NSLocalizedString("AUTHENTICATE", comment: ""),
				sizeToFit: true
			)
			self.authentication_label = view
			self.scrollView.addSubview(view)
		}
		do {
			let view = UICommonComponents.TooltipSpawningLinkButtonView(
				tooltipText: String(
					format: NSLocalizedString(
						"An extra layer of security\nfor approving certain\nactions after you've\nunlocked the app",
						comment: ""
					)
				)
			)
			view.tooltipDirectionFromOrigin = .right
			view.willPresentTipView_fn =
			{ [unowned self] in
				self.view.resignCurrentFirstResponder() // if any
			}
			self.authentication_tooltipSpawn_buttonView = view
			self.scrollView.addSubview(view)
		}
		do {
			let view = UICommonComponents.Form.Switches.TitleAndControlField(
				frame: .zero,
				title: NSLocalizedString("When sending", comment: ""),
				isSelected: false // for now - will update on VDA
			)
			view.toggled_fn =
			{ [weak self] in
				guard let thisSelf = self else {
					return
				}
				let err_str = SettingsController.shared.set(
					authentication__requireWhenSending: thisSelf.whenSendingMoney_inputView.isSelected
				)
				if err_str != nil {
					assert(false, "error while setting authentication__requireWhenSending")
				}
			}
			view.set(
				shouldToggle_fn: { (to_isSelected, async_fn) in
					if to_isSelected == false { // if it's being turned OFF
						// then they need to authenticate
						PasswordController.shared.initiate_verifyUserAuthenticationForAction(
							customNavigationBarTitle: NSLocalizedString("Authenticate", comment: ""),
							canceled_fn: {
								async_fn(false) // disallowed
							},
							entryAttempt_succeeded_fn: {
								DispatchQueue.main.asyncAfter(deadline: .now() + 0.4, execute:
								{ // this delay is purely for visual effect, waiting for pw entry to dismiss
									async_fn(true) // allowed
								})
							}
						)
					} else {
						async_fn(true) // no auth needed
					}
				}
			)
			assert(view.switchControl.shouldToggle_fn != nil) // maybe this needs to be redesigned so the switch doesn't have the control on whether to unlock, but the SettingsController does, and so the UI must update accordingly?
			self.whenSendingMoney_inputView = view
			self.scrollView.addSubview(view)
		}
		do {
			let view = UICommonComponents.Form.Switches.TitleAndControlField(
				frame: .zero,
				title: NSLocalizedString("To show wallet secrets", comment: ""),
				isSelected: false // for now - will update on VDA
			)
			view.toggled_fn =
			{ [weak self] in
				guard let thisSelf = self else {
					return
				}
				let err_str = SettingsController.shared.set(
					authentication__requireToShowWalletSecrets: thisSelf.toShowWalletSecrets_inputView.isSelected
				)
				if err_str != nil {
					assert(false, "error while setting authentication__requireToShowWalletSecrets")
				}
			}
			view.set(
				shouldToggle_fn: { (to_isSelected, async_fn) in
					if to_isSelected == false { // if it's being turned OFF
						// then they need to authenticate
						PasswordController.shared.initiate_verifyUserAuthenticationForAction(
							customNavigationBarTitle: NSLocalizedString("Authenticate", comment: ""),
							canceled_fn: {
								async_fn(false) // disallowed
							},
							entryAttempt_succeeded_fn: {
								DispatchQueue.main.asyncAfter(deadline: .now() + 0.4, execute:
								{ // this delay is purely for visual effect, waiting for pw entry to dismiss
									async_fn(true) // allowed
								})
							}
						)
					} else {
						async_fn(true) // no auth needed
					}
				}
			)
			assert(view.switchControl.shouldToggle_fn != nil) // maybe this needs to be redesigned so the switch doesn't have the control on whether to unlock, but the SettingsController does, and so the UI must update accordingly?
			self.toShowWalletSecrets_inputView = view
			self.scrollView.addSubview(view)
		}
		do {
			let view = UICommonComponents.Form.Switches.TitleAndControlField(
				frame: .zero,
				title: NSLocalizedString("Use Touch/Face ID", comment: ""),
				isSelected: false // for now - will update on VDA
			)
			view.toggled_fn =
			{ [weak self] in
				guard let thisSelf = self else {
					return
				}
				let err_str = SettingsController.shared.set(
					authentication__tryBiometric: thisSelf.tryBiometric_inputView.isSelected
				)
				if err_str != nil {
					assert(false, "error while setting authentication__tryBiometric")
				}
			}
			view.set(
				shouldToggle_fn: { (to_isSelected, async_fn) in
					if to_isSelected == true { // if it's being turned ON
						// then they need to authenticate b/c this is a loosening of security
						PasswordController.shared.initiate_verifyUserAuthenticationForAction(
							customNavigationBarTitle: NSLocalizedString("Authenticate", comment: ""),
							canceled_fn: {
								async_fn(false) // disallowed
							},
							entryAttempt_succeeded_fn: {
								DispatchQueue.main.asyncAfter(deadline: .now() + 0.4, execute:
								{ // this delay is purely for visual effect, waiting for pw entry to dismiss
									async_fn(true) // allowed
								})
							}
						)
					} else {
						async_fn(true) // no auth needed
					}
				}
			)
			assert(view.switchControl.shouldToggle_fn != nil) // maybe this needs to be redesigned so the switch doesn't have the control on whether to unlock, but the SettingsController does, and so the UI must update accordingly?
			self.tryBiometric_inputView = view
			self.scrollView.addSubview(view)
		}
		//
		do {
			let view = UICommonComponents.Form.FieldLabel(
				title: NSLocalizedString("DISPLAY", comment: "")
			)
			self.displayCurrency_label = view
			self.scrollView.addSubview(view)
		}
		do {
			let view = UICommonComponents.Form.StringPicker.PickerButtonFieldView(
				title: NSLocalizedString("Currency", comment: ""),
				selectedValue: SettingsController.shared.displayCurrencySymbol,
				allValues: CcyConversionRates.Currency.lazy_allCurrencySymbols
			)
			view.picker_inputField_didBeginEditing =
			{ [weak self] (inputField) in
				DispatchQueue.main.asyncAfter( // slightly janky
					deadline: .now() + UICommonComponents.FormViewController.fieldScrollDuration + 0.1
				) { [weak self] in
					guard let thisSelf = self else {
						return
					}
					if inputField.isFirstResponder { // jic
						thisSelf.scrollInputViewToVisible(thisSelf.displayCurrency_inputView)
					}
				}
			}
			view.selectedValue_fn =
			{ [weak self] in
				guard let thisSelf = self else {
					return
				}
				let final_value = thisSelf.displayCurrency_inputView.selectedValue!
				let err_str = SettingsController.shared.set(
					displayCurrencySymbol_nilForDefault: final_value
				)
				if err_str != nil {
					assert(false, "error while setting display currency")
				}
			}
			self.displayCurrency_inputView = view
			self.scrollView.addSubview(view)
		}
		//
		do {
			let view = UICommonComponents.LinkButtonView(mode: .mono_destructive, size: .larger, title: "DELETE EVERYTHING")
			view.addTarget(self, action: #selector(deleteButton_tapped), for: .touchUpInside)
			self.deleteButton = view
			self.scrollView.addSubview(view)
		}
		//
	}
	override func setup_navigation()
	{
		super.setup_navigation()
		self.navigationItem.title = NSLocalizedString("Preferences", comment: "")
		self.navigationItem.rightBarButtonItem = UICommonComponents.NavigationBarButtonItem(
			type: .openModal,
			target: self,
			action: #selector(tapped_barButtonItem_about),
			title_orNilForDefault: NSLocalizedString("About", comment: "")
		)
	}
	//
	// Lifecycle - Teardown
	override func tearDown()
	{
		super.tearDown()
		self.tearDown_timerToSave_durationUpdated()
	}
	override func stopObserving()
	{ // not that it will ever get called..
		super.stopObserving()
		PasswordController.shared.removeRegistrantForDeleteEverything(self)
	}
	//
	// Accessors - Overrides
	override func new_isFormSubmittable() -> Bool
	{
		return true // this is actually for the interactivity of the 'About' button in this case
	}
	//
	// Accessors - Overrides
	override func nextInputFieldViewAfter(inputView: UIView) -> UIView?
	{
		if inputView == self.address_inputView {
			return nil
		}
		assert(false, "Unexpected")
		return nil
	}
	//
	// Imperatives - Resolving indicator
	func set(resolvingIndicatorIsVisible: Bool)
	{
		if resolvingIndicatorIsVisible {
			self.resolving_activityIndicator.show()
		} else {
			self.resolving_activityIndicator.hide()
		}
		self.view.setNeedsLayout()
	}
	//
	// Runtime - Imperatives - Overrides
	override func disableForm()
	{
		super.disableForm()
		//
		self.scrollView.isScrollEnabled = false
		//
		self.address_inputView.isEnabled = false
	}
	override func reEnableForm()
	{
		super.reEnableForm()
		//
		self.scrollView.isScrollEnabled = true
		//
		self.address_inputView.isEnabled = true
	}
	override func _tryToSubmitForm()
	{
		assert(false) // no such thing - the 'About' button target is overridden
	}
	//
	// Delegation - View
	override func viewDidLayoutSubviews()
	{
		super.viewDidLayoutSubviews()
		//
		let top_yOffset: CGFloat = self.yOffsetForViewsBelowValidationMessageView
		//
		let spacingBetweenFieldsets: CGFloat = UICommonComponents.Form.FieldLabel.marginAboveLabelForUnderneathField_textInputView + 4
		//
		let label_x = self.new__label_x
		let input_x = self.new__input_x
//		let edgeFlushInput_x = input_x + UICommonComponents.FormInputCells.imagePadding_x // re-compensate to arrive at value that causes element to actually be visually aligned with inputs and design metrics
		let textField_w = self.new__textField_w // already has customInsets subtracted
//		let edgeFlushInput_w = textField_w - 2*UICommonComponents.FormInputCells.imagePadding_x // re-compensate to arrive at value that causes element to actually be visually aligned with inputs and design metrics
		let fullWidth_label_w = self.new__fieldLabel_w // already has customInsets subtracted
		//
		self.changePasswordButton.frame = CGRect(
			x: input_x,
			y: top_yOffset,
			width: textField_w,
			height: UICommonComponents.InlineButton.fixedHeight
		).integral
		//
		do {
			self.appTimeoutAfterS_label!.frame = CGRect(
				x: label_x,
				y: self.changePasswordButton.frame.origin.y + self.changePasswordButton.frame.size.height + spacingBetweenFieldsets,
				width: fullWidth_label_w,
				height: self.appTimeoutAfterS_label!.frame.size.height
			).integral
			self.appTimeoutAfterS_inputView!.frame = CGRect(
				x: label_x, // not input_x
				y: self.appTimeoutAfterS_label!.frame.origin.y + self.appTimeoutAfterS_label!.frame.size.height + UICommonComponents.Form.FieldLabel.marginBelowLabelAboveTextInputView,
				width: fullWidth_label_w, // not input_x
				height: SettingsAppTimeoutAfterSecondsSliderInputView.h
			).integral
			self.appTimeoutAfterS_fieldAccessoryMessageLabel!.frame = CGRect(
				x: label_x,
				y: self.appTimeoutAfterS_inputView!.frame.origin.y + self.appTimeoutAfterS_inputView!.frame.size.height + UICommonComponents.FormFieldAccessoryMessageLabel.marginAboveLabelBelowTextInputView,
				width: fullWidth_label_w,
				height: 0
			)
			self.appTimeoutAfterS_fieldAccessoryMessageLabel!.sizeToFit()
		}
		let authorization_switchesToLayOut: [UICommonComponents.Form.Switches.TitleAndControlField] =
		[
			self.whenSendingMoney_inputView,
			self.toShowWalletSecrets_inputView,
			self.tryBiometric_inputView
		]
		do {
			let switchesToLayOut = authorization_switchesToLayOut
			let previousSectionBottomView: UIView = self.appTimeoutAfterS_fieldAccessoryMessageLabel!
			let marginUnderSwitchesFieldsetTitleAboveFirstField: CGFloat = 7
			self.authentication_label.frame = CGRect(
				x: label_x,
				y: previousSectionBottomView.frame.origin.y + previousSectionBottomView.frame.size.height + spacingBetweenFieldsets + (UIFont.shouldStepDownLargerFontSizes ? 16 : 21) /* this k is a special case because we're just under the appTimeoutAfterS_fieldAccessoryMessageLabel */,
				width: self.authentication_label.frame.size.width,
				height: self.authentication_label.frame.size.height
			)
			do {
				let tooltipSpawn_buttonView_w: CGFloat = UICommonComponents.TooltipSpawningLinkButtonView.usabilityExpanded_w
				let tooltipSpawn_buttonView_h: CGFloat = UICommonComponents.TooltipSpawningLinkButtonView.usabilityExpanded_h
				self.authentication_tooltipSpawn_buttonView.frame = CGRect(
					x: self.authentication_label.frame.origin.x + self.authentication_label.frame.size.width - UICommonComponents.TooltipSpawningLinkButtonView.tooltipLabelSqueezingVisualMarginReductionConstant_x,
					y: self.authentication_label.frame.origin.y - (tooltipSpawn_buttonView_h - self.authentication_label.frame.size.height)/2,
					width: tooltipSpawn_buttonView_w,
					height: tooltipSpawn_buttonView_h
				).integral
			}
			for (idx, switchView) in switchesToLayOut.enumerated() {
				let mostPreviousView = (idx == 0 ? self.authentication_label : switchesToLayOut[idx - 1])!
				switchView.frame = CGRect(
					x: input_x,
					y: mostPreviousView.frame.origin.y + mostPreviousView.frame.size.height
						+ (idx == 0 ? marginUnderSwitchesFieldsetTitleAboveFirstField : 0)
					,
					width: textField_w,
					height: switchView.fixedHeight
				).integral
			}
		}
		do {
			let previousSectionBottomView: UIView = authorization_switchesToLayOut.last!
			self.displayCurrency_label.frame = CGRect(
				x: label_x,
				y: previousSectionBottomView.frame.origin.y + previousSectionBottomView.frame.size.height + spacingBetweenFieldsets,
				width: fullWidth_label_w,
				height: self.displayCurrency_label.frame.size.height
			)
			self.displayCurrency_inputView.frame = CGRect(
				x: input_x,
				y: self.displayCurrency_label.frame.origin.y + self.displayCurrency_label.frame.size.height + UICommonComponents.Form.FieldLabel.marginBelowLabelAboveTextInputView,
				width: textField_w,
				height: self.displayCurrency_inputView.fixedHeight
			)
		}
		//
		do {
			self.deleteButton!.frame = CGRect(
				x: label_x,
				y: self.displayCurrency_inputView.frame.origin.y + spacingBetweenFieldsets + spacingBetweenFieldsets,
				width: self.deleteButton!.frame.size.width,
				height: self.deleteButton!.frame.size.height
			)
		}
		//
		let bottomMostView = self.deleteButton
		let bottomPadding: CGFloat = spacingBetweenFieldsets
		self.scrollableContentSizeDidChange(
			withBottomView: bottomMostView!,
			bottomPadding: bottomPadding
		)
	}
	override func viewDidAppear(_ animated: Bool)
	{
//		let isFirstAppearance = self.hasAppearedBefore == false
		super.viewDidAppear(animated)
	}
	override func viewWillAppear(_ animated: Bool)
	{
		super.viewWillAppear(animated)
		//
		// TODO: This configuration is not the optimal place to do this - change to upon a notification from PasswordController
		do { // config change pw btn text
			self.changePasswordButton.setTitle(
				NSLocalizedString("Change \(PasswordController.shared.passwordType.capitalized_humanReadableString)", comment: ""),
				for: .normal
			)
			self.appTimeoutAfterS_fieldAccessoryMessageLabel!.text = String(
				format: NSLocalizedString(
					"Idle time before your %@ is required",
					comment: ""
				),
				PasswordController.shared.passwordType.humanReadableString
			)
			self.view.setNeedsLayout()
		}
		do {
			self.appTimeoutAfterS_inputView.slider.setValueFromSettings()
			//
			self.whenSendingMoney_inputView.switchControl.isSelected = SettingsController.shared.authentication__requireWhenSending
			self.toShowWalletSecrets_inputView.switchControl.isSelected = SettingsController.shared.authentication__requireToShowWalletSecrets
			self.tryBiometric_inputView.switchControl.isSelected = SettingsController.shared.authentication__tryBiometric
		}
		do {
			if PasswordController.shared.hasUserSavedAPassword == false {
				self.changePasswordButton.isEnabled = false // can't change til entered
				// self.serverURLInputLayer.disabled = false // enable - user may want to change URL before they add their first wallet
				self.appTimeoutAfterS_inputView.set(isEnabled: false)
				self.whenSendingMoney_inputView.set(isEnabled: false)
				self.toShowWalletSecrets_inputView.set(isEnabled: false)
				self.tryBiometric_inputView.set(isEnabled: false)
				self.deleteButton.isEnabled = false
			} else if PasswordController.shared.hasUserEnteredValidPasswordYet == false { // has data but not unlocked app - prevent tampering
				// however, user should never be able to see the settings view in this state
				self.changePasswordButton.isEnabled = false // not going to enable this b/c changing the pw before the app objects are in memory would mean they passwordController record would get out of step with the password used to save records to disk
				// self.serverURLInputLayer.disabled = true
				self.appTimeoutAfterS_inputView.set(isEnabled: false)
				self.whenSendingMoney_inputView.set(isEnabled: false)
				self.toShowWalletSecrets_inputView.set(isEnabled: false)
				self.tryBiometric_inputView.set(isEnabled: false)
				self.deleteButton.isEnabled = false
			} else { // has entered PW - unlock
				self.changePasswordButton.isEnabled = true
				// self.serverURLInputLayer.disabled = false
				self.appTimeoutAfterS_inputView.set(isEnabled: true)
				self.whenSendingMoney_inputView.set(isEnabled: true)
				self.toShowWalletSecrets_inputView.set(isEnabled: true)
				self.tryBiometric_inputView.set(isEnabled: true)
				self.deleteButton.isEnabled = true
			}
		}
	}
	//
	// Delegation - Interactions
	func tapped_rightBarButtonItem()
	{
		self.aFormSubmissionButtonWasPressed()
	}
	@objc func tapped_barButtonItem_about()
	{
		let viewController = AboutMyMoneroViewController()
		let navigationController = UICommonComponents.NavigationControllers.SwipeableNavigationController(rootViewController: viewController)
		navigationController.modalPresentationStyle = .formSheet
		self.navigationController!.present(navigationController, animated: true, completion: nil)
	} 
	//
	@objc func changePasswordButton_tapped()
	{
		PasswordController.shared.initiate_changePassword()
	}
	@objc func deleteButton_tapped()
	{
		let generator = UINotificationFeedbackGenerator()
		generator.prepare()
		generator.notificationOccurred(.warning)
		//
		let alertController = UIAlertController(
			title: NSLocalizedString("Delete everything?", comment: ""),
			message: NSLocalizedString(
				"Are you sure you want to delete all of your local data?\n\nAny wallets will remain permanently on the X-CASH blockchain but local data such as contacts will not be recoverable at present.",
				comment: ""
			),
			preferredStyle: .alert
		)
		alertController.addAction(
			UIAlertAction(
				title: NSLocalizedString("Delete Everything", comment: ""),
				style: .destructive
			) { (result: UIAlertAction) -> Void in
				PasswordController.shared.initiateDeleteEverything()
			}
		)
		alertController.addAction(
			UIAlertAction(
				title: NSLocalizedString("Cancel", comment: ""),
				style: .default
			) { (result: UIAlertAction) -> Void in
			}
		)
		self.navigationController!.present(alertController, animated: true, completion: nil)
	}
	//
	// Delegation - Protocols - SettingsAppTimeoutAfterSecondsSliderInteractionsDelegate
	var _timerToSave_durationUpdated: Timer?
	func tearDown_timerToSave_durationUpdated()
	{
		if self._timerToSave_durationUpdated != nil {
			self._timerToSave_durationUpdated!.invalidate()
			self._timerToSave_durationUpdated = nil
		}
	}
	func durationUpdated(_ durationInSeconds_orNeverValue: TimeInterval)
	{
		// debounce to prevent/optimize spam/unnecessary saves
		self.tearDown_timerToSave_durationUpdated()
		self._timerToSave_durationUpdated = Timer.scheduledTimer(
			withTimeInterval: 0.3,
			repeats: false,
			block:
			{ [unowned self] (timer) in
				self.tearDown_timerToSave_durationUpdated()
				let err_str = SettingsController.shared.set(
					appTimeoutAfterS_nilForDefault_orNeverValue: self.appTimeoutAfterS_inputView.slider.valueAsWholeNumberOfSeconds_orNeverValue
				)
				if err_str != nil {
					assert(false, "error while setting app timeout")
				}
			}
		)
	}
	//
	// Protocol - DeleteEverythingRegistrant
	func passwordController_DeleteEverything() -> String?
	{
		DispatchQueue.main.async
		{ [unowned self] in
			self.scrollView.setContentOffset(.zero, animated: false)
		}
		//
		return nil // no error
	}
}
