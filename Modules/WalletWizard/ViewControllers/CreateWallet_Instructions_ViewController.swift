//
//  CreateWallet_Instructions_ViewController.swift
//  MyMonero
//
//  Created by Paul Shapiro on 6/18/17.
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

class CreateWallet_Instructions_ViewController: AddWalletWizardScreen_BaseViewController
{
	//
	// Constants/Types
	struct TitleAndDescription
	{
		var title: String
		var description: String
	}
	struct LabelDuo
	{
		var titleLabel: UICommonComponents.ReadableInfoHeaderLabel
		var descriptionLabel: UICommonComponents.ReadableInfoDescriptionLabel
	}
	//
	// Properties
	var labelDuos: [LabelDuo] = []
	var horizontalRuleView = UIView()
	var agreeCheckboxButton = UICommonComponents.PushButton(pushButtonType: .utility)
	//
	// Lifecycle - Init
	override func setup_views()
	{
		super.setup_views()
		do {
			let titlesAndDescriptions = self._new_messages_titlesAndDescriptions
			for (_, titleAndDescription) in titlesAndDescriptions.enumerated() {
				let labelDuo = LabelDuo(
					titleLabel: self._new_titleLabel(with: titleAndDescription.title),
					descriptionLabel: self._new_descriptionLabel(with: titleAndDescription.description)
				)
				self.labelDuos.append(labelDuo)
				//
				let titleLabel = labelDuo.titleLabel
				let descriptionLabel = labelDuo.descriptionLabel
				self.scrollView.addSubview(titleLabel)
				self.scrollView.addSubview(descriptionLabel)
			}
		}
		do {
			let view = self.horizontalRuleView
			view.backgroundColor = UIColor(rgb: 0x383638)
			self.scrollView.addSubview(view)
		}
		do {
			let view = self.agreeCheckboxButton
			let checkbox_image = UIImage(named: "terms_checkbox")!
			let checkbox_checked_image = UIImage(named: "terms_checkbox_checked")!
			view.setImage(checkbox_image, for: .normal)
			view.setImage(checkbox_checked_image, for: .selected)
			view.adjustsImageWhenHighlighted = true
			view.contentHorizontalAlignment = .left
			let inset_h: CGFloat = 8
			let inset_v: CGFloat = 8
			view.imageEdgeInsets = UIEdgeInsets.init(
				top: inset_v,
				left: inset_h + UICommonComponents.FormInputCells.imagePadding_x,
				bottom: inset_v,
				right: 0
			)
			view.addTarget(self, action: #selector(agreeCheckboxButton_tapped), for: .touchUpInside)
			view.setTitle(NSLocalizedString("GOT IT!", comment: ""), for: .normal)
			view.titleLabel!.font = UIFont.middlingRegularMonospace
			view.setTitleColor(UIColor(rgb: 0xF8F7F8), for: .normal)
			view.titleEdgeInsets = UIEdgeInsets.init(
				top: inset_v - 1,
				left: UICommonComponents.FormInputCells.imagePadding_x + checkbox_image.size.width + 2,
				bottom: inset_v,
				right: 0
			)
			self.scrollView.addSubview(view)
		}
	}
	override func setup_navigation()
	{
		super.setup_navigation()
		//
		self.navigationItem.title = NSLocalizedString("New Wallet", comment: "")
	}
	override var overridable_wantsBackButton: Bool { return true }
	//
	// Accessors
	var _new_messages_titlesAndDescriptions: [TitleAndDescription]
	{
		var list: [TitleAndDescription] = []
		list.append(TitleAndDescription(
			title: NSLocalizedString("Creating a wallet", comment: ""),
			description: NSLocalizedString("Each X-CASH wallet gets a unique word-sequence called a mnemonic.", comment: "") // NOTE: non break space
		))
		list.append(TitleAndDescription(
			title: NSLocalizedString("Write down your mnemonic", comment: ""),
			description: NSLocalizedString("It's the only way to regain access to your funds if you delete the app.", comment: "") // NOTE: non break space
		))
		list.append(TitleAndDescription(
			title: NSLocalizedString("Keep it secret and safe", comment: ""),
			description: NSLocalizedString("If you save it to an insecure location, it may be viewable by other apps.", comment: "") // NOTE: non break space
		))
		list.append(TitleAndDescription(
			title: NSLocalizedString("Use it like an actual wallet", comment: ""),
			description: NSLocalizedString("For keeping large amounts long-term, make a cold-storage wallet instead.", comment: "") // NOTE: non break space
		))
		//
		return list
	}
	func _new_titleLabel(with text: String) -> UICommonComponents.ReadableInfoHeaderLabel
	{
		let label = UICommonComponents.ReadableInfoHeaderLabel()
		label.text = text
		//
		return label
	}
	func _new_descriptionLabel(with text: String) -> UICommonComponents.ReadableInfoDescriptionLabel
	{
		let label = UICommonComponents.ReadableInfoDescriptionLabel()
		label.textAlignment = .left
		label.set(text: text)
		//
		return label
	}
	//
	// Accessors - Overrides
	override func new_wantsInlineMessageViewForValidationMessages() -> Bool { return false }
	override func new_isFormSubmittable() -> Bool
	{
		guard self.agreeCheckboxButton.isSelected else {
			return false
		}
		return true
	}
	//
	// Imperatives - Overrides
	override func _tryToSubmitForm()
	{
		self.wizardController.createWalletInstanceAndProceedToNextStep()
	}
	//
	// Delegation - Interactions
	@objc func agreeCheckboxButton_tapped()
	{
		let generator = UISelectionFeedbackGenerator()
		generator.prepare()
		do {
			self.agreeCheckboxButton.isSelected = !self.agreeCheckboxButton.isSelected
			self.set_isFormSubmittable_needsUpdate()
		}
		generator.selectionChanged()
	}
	//
	// Delegation - Overrides - Layout
	override func viewDidLayoutSubviews()
	{
		super.viewDidLayoutSubviews()
		let topMargin: CGFloat = UIFont.shouldStepDownLargerFontSizes ? 24 : 40
		let content_w: CGFloat = 240
		let content_x = (self.scrollView.frame.size.width - content_w) / 2
		do {
			let marginBelowDescriptionLabel: CGFloat = UIFont.shouldStepDownLargerFontSizes ? 24 : 28
			var lastYOffset = topMargin
			for (_, labelDuo) in self.labelDuos.enumerated() {
				labelDuo.titleLabel.frame = CGRect(x: 0, y: 0, width: content_w, height: 0)
				labelDuo.descriptionLabel.frame = CGRect(x: 0, y: 0, width: content_w, height: 0)
				labelDuo.titleLabel.sizeToFit()
				labelDuo.descriptionLabel.sizeToFit()
				labelDuo.titleLabel.frame = CGRect(
					x: content_x,
					y: lastYOffset,
					width: labelDuo.titleLabel.frame.size.width,
					height: labelDuo.titleLabel.frame.size.height
				).integral
				labelDuo.descriptionLabel.frame = CGRect(
					x: content_x,
					y: labelDuo.titleLabel.frame.origin.y + labelDuo.titleLabel.frame.size.height + 4,
					width: labelDuo.descriptionLabel.frame.size.width,
					height: labelDuo.descriptionLabel.frame.size.height
				).integral
				//
				lastYOffset = labelDuo.descriptionLabel.frame.origin.y + labelDuo.descriptionLabel.frame.size.height + marginBelowDescriptionLabel
			}
		}
		let bottomMostLabel = self.labelDuos.last!.descriptionLabel
		let rule_margin_y: CGFloat = UIFont.shouldStepDownLargerFontSizes ? 16 : 24
		do {
			self.horizontalRuleView.frame = CGRect(
				x: content_x,
				y: bottomMostLabel.frame.origin.y + bottomMostLabel.frame.size.height + rule_margin_y,
				width: content_w,
				height: 1.0/UIScreen.main.scale
			)
		}
		do {
			let width = 105 + 2 * UICommonComponents.FormInputCells.imagePadding_x
			let y: CGFloat = self.horizontalRuleView.frame.origin.y + self.horizontalRuleView.frame.size.height + rule_margin_y
			let height = 34 + 2 * UICommonComponents.FormInputCells.imagePadding_y
			self.agreeCheckboxButton.frame = CGRect(x: content_x, y: y, width: width, height: height).integral
		}
		self.scrollableContentSizeDidChange(withBottomView: self.agreeCheckboxButton, bottomPadding: 18)
	}
	//
	// Delegation - Internal - Overrides
	override func _viewControllerIsBeingPoppedFrom()
	{ // must maintain correct state if popped
		self.wizardController.patchToDifferentWizardTaskMode_withoutPushingScreen(
			patchTo_wizardTaskMode: self.wizardController.current_wizardTaskMode,
			atIndex: self.wizardController.current_wizardTaskMode_stepIdx - 1
		)		
	}
}
