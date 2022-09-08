//
//  TokenDistributionViewController.swift
//  Multisig
//
//  Created by Mouaz on 9/5/22.
//  Copyright © 2022 Gnosis Ltd. All rights reserved.
//

import UIKit

class TokenDistributionViewController: UIViewController {

    @IBOutlet private weak var titleLabel: UILabel!
    @IBOutlet private weak var descriptionLabel: UILabel!
    @IBOutlet private weak var nextButton: UIButton!
    @IBOutlet weak var distributionView: BorderedCheveronButton!

    private var onNext: (() -> ())?

    convenience init(onNext: @escaping () -> ()) {
        self.init(namedClass: TokenDistributionViewController.self)
        self.onNext = onNext
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        Tracker.trackEvent(.screenClaimDistr)

        ViewControllerFactory.removeNavigationBarBorder(self)
        navigationItem.largeTitleDisplayMode = .never
        distributionView.set("Distribution details") { [unowned self] in
            let vc = ViewControllerFactory.detailedInfoViewController(title: "Distribution details",
                                                                      text: nil,
                                                                      attributedText: nil)
            Tracker.trackEvent(.userClaimDistrDetails)

        }
        titleLabel.setStyle(.Updated.title)
        descriptionLabel.setStyle(.secondary)
        nextButton.setText("Next", .filled)
    }

    @IBAction func didTapNext(_ sender: Any) {
        Tracker.trackEvent(.userClaimDistrNext)
        onNext?()
    }
}
