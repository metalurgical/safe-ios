//
//  TransactionListTableViewCell.swift
//  Multisig
//
//  Created by Dmitry Bespalov on 18.11.20.
//  Copyright © 2020 Gnosis Ltd. All rights reserved.
//

import UIKit
import SwiftUI

class TransactionListTableViewCell: SwiftUITableViewCell {
    @IBOutlet private weak var conflictTypeButtonBarView: UIView!
    @IBOutlet private weak var conflictTypeView: UIView!
    @IBOutlet private weak var typeImageView: UIImageView!
    @IBOutlet private weak var titleLabel: UILabel!
    @IBOutlet private weak var nonceLabel: UILabel!
    @IBOutlet private weak var dateLabel: UILabel!
    @IBOutlet private weak var infoLabel: UILabel!
    @IBOutlet private weak var appendixLabel: UILabel!
    @IBOutlet private weak var statusIconImageView: UIImageView!
    @IBOutlet private weak var statusLabel: UILabel!
    @IBOutlet private weak var bottomStackView: UIStackView!
    @IBOutlet private weak var confirmationsCountLabel: UILabel!
    @IBOutlet private weak var confirmationsCountImageView: UIImageView!

    override func awakeFromNib() {
        super.awakeFromNib()
        titleLabel.setStyle(.primary)
        nonceLabel.setStyle(.footnote2)
        dateLabel.setStyle(.footnote2)
        infoLabel.setStyle(.primary)
        appendixLabel.setStyle(.footnote2)
        statusLabel.setStyle(.footnote2)
        confirmationsCountLabel.setStyle(.footnote2)
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        typeImageView.contentMode = .center
    }

    func set (title: String) {
        titleLabel.text = title
    }

    func set(image: UIImage) {
        typeImageView.image = image
    }

    func set(contractImageUrl: URL?, contractAddress: AddressString) {
        guard let contractImageUrl = contractImageUrl else {
            set(contractAddress: contractAddress)
            return
        }

        let placeholder = BlockiesImageProvider(seed: contractAddress.address.hexadecimal).roundImage()!
        typeImageView.contentMode = .scaleAspectFit
        typeImageView.kf.setImage(with: contractImageUrl, placeholder: placeholder)
    }

    func set(contractAddress: AddressString) {
        typeImageView.setAddress(contractAddress.address.hexadecimal, width: 16, height: 16)
    }

    func set(conflictType: SCGModels.ConflictType) {
        conflictTypeView.isHidden = conflictType == .none
        conflictTypeButtonBarView.isHidden = conflictType == .end
        nonceLabel.isHidden = conflictType != .none
    }

    func set(nonce: String) {
        nonceLabel.text = "\(nonce)"
    }

    func set(date: String) {
        dateLabel.text = date
    }

    func set(info: String, color: UIColor = .primaryLabel) {
        infoLabel.text = info
        infoLabel.textColor = color
    }

    func set(confirmationsSubmitted: UInt64, confirmationsRequired: UInt64) {
        let color = confirmationColor(confirmationsSubmitted, confirmationsRequired)
        confirmationsCountLabel.text = "\(confirmationsSubmitted) out of \(confirmationsRequired)"
        confirmationsCountLabel.textColor = color
        confirmationsCountImageView.tintColor = color
    }

    func set(status: SCGModels.TxStatus) {
        statusLabel.text = status.title
        appendixLabel.text = status.title
        appendixLabel.isHidden = status.isWaiting
        bottomStackView.isHidden = !status.isWaiting
        statusLabel.textColor = statusColor(status: status)
        appendixLabel.textColor = statusLabel.textColor
        self.contentView.alpha = containerViewAlpha(status: status)
    }

    private func statusColor(status: SCGModels.TxStatus) -> UIColor {
        switch status {
        case .awaitingExecution, .awaitingConfirmations, .awaitingYourConfirmation, .pending:
            return .pending
        case .failed:
            return .error
        case .cancelled:
            return .secondaryLabel
        case .success:
            return .button
        }
    }

    private func containerViewAlpha(status: SCGModels.TxStatus) -> CGFloat {
        status.isFailed ? 0.5 : 1
    }

    private func confirmationColor(_ confirmationsSubmitted: UInt64 = 0, _ confirmationsRequired: UInt64 = 0) -> UIColor {
        let reminingConfirmations = confirmationsSubmitted > confirmationsRequired ? 0 : confirmationsRequired - confirmationsSubmitted
        return reminingConfirmations > 0 ? .tertiaryLabel : .button
    }
}
