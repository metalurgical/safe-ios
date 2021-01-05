//
//  TransactionListHeaderTableViewCellTableViewCell.swift
//  Multisig
//
//  Created by Moaaz on 12/14/20.
//  Copyright © 2020 Gnosis Ltd. All rights reserved.
//

import UIKit

class TransactionListHeaderTableViewCell: UITableViewCell {
    @IBOutlet private weak var titleLabel: UILabel!

    override func awakeFromNib() {
        super.awakeFromNib()
        titleLabel.setStyle(.caption2)
    }

    func set(title: String) {
        titleLabel.text = title
    }
}
