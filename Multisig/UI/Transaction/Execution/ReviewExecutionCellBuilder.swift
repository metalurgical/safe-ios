//
//  ReviewExecutionCellBuilder.swift
//  Multisig
//
//  Created by Dmitry Bespalov on 11.01.22.
//  Copyright © 2022 Gnosis Ltd. All rights reserved.
//

import Foundation
import UIKit
import SwiftCryptoTokenFormatter

class ReviewExecutionCellBuilder: TransactionDetailCellBuilder {

    var onTapAccount: () -> Void = {}
    var onTapFee: () -> Void = {}
    var onTapAdvanced: () -> Void = {}

    private var safe: Safe!

    init(vc: UIViewController, tableView: UITableView, chain: Chain, safe: Safe) {
        super.init(vc: vc, tableView: tableView, chain: chain)
        self.safe = safe

        tableView.registerCell(BorderedInnerTableCell.self)
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "Spacer")
    }

    func build(_ model: ExecutionReviewUIModel) -> [UITableViewCell] {
        result = []
        // nothing to do for creation transaction
        if case let SCGModels.TxInfo.creation(_) = model.transaction.txInfo {
            return result
        }
        buildHeader(model.transaction)
        buildAssetContract(model.transaction)
        buildSpacing()
        buildExecutionOptions(model.executionOptions)
        return result
    }

    func buildSpacing() {
        let cell = newCell(UITableViewCell.self, reuseId: "Spacer")
        result.append(cell)
    }

    func buildExecutionOptions(_ model: ExecutionOptionsUIModel) {
        // create a table inner cell with other cells
        let tableCell = newCell(BorderedInnerTableCell.self)

        tableCell.tableView.registerCell(DisclosureWithContentCell.self)
        tableCell.tableView.registerCell(SecondaryDetailDisclosureCell.self)

        let disclosureCell1 = buildExecutedWithAccount(model.accountState, tableView: tableCell.tableView)
        let estimatedFeeCell = buildEstimatedGasFee(model.feeState, tableView: tableCell.tableView)
        let advancedCell = buildAdvancedParameters(tableView: tableCell.tableView)

        tableCell.setCells([disclosureCell1, estimatedFeeCell, advancedCell])

        // handle cell taps
        let (executeWithIndex, feeIndex, advancedIndex) = (0, 1, 2)
        tableCell.onCellTap = { [weak self] index in
            guard let self = self else { return }
            switch index {
            case executeWithIndex:
                self.onTapAccount()
            case feeIndex:
                self.onTapFee()
            case advancedIndex:
                self.onTapAdvanced()
            default:
                assertionFailure("Tapped cell at index out of bounds: \(index)")
            }
        }

        result.append(tableCell)
    }

    func buildExecutedWithAccount(_ model: ExecuteWithAccountCellState, tableView: UITableView) -> UITableViewCell {
        // 'loading' status for automatic selection process
            // skeleton loading view
        // 'empty' with call to action to select something
            // label
        // 'filled' state for the account and balance
            // account and balance piece

        let cell = tableView.dequeueCell(DisclosureWithContentCell.self)
        cell.setText("Execute with")
        switch model {
        case .loading:
            let skeleton = UILabel()
            skeleton.textAlignment = .right
            skeleton.isSkeletonable = true
            skeleton.skeletonTextLineHeight = .fixed(25)
            skeleton.showSkeleton(delay: 0.2)
            cell.setContent(skeleton)
            
        case .empty:
            let label = UILabel()
            label.textAlignment = .right
            label.setStyle(.secondary)
            label.text = "Not selected"
            cell.setContent(label)

        case .filled(let accountModel):
            let content = MiniAccountAndBalancePiece()
            content.setModel(accountModel)
            cell.setContent(content)
        }
        return cell
    }

    func buildEstimatedGasFee(_ model: EstimatedFeeCellState, tableView: UITableView) -> UITableViewCell {
        // 'loading'
            // skeleton / loading view
        // 'loaded'
            // amount and value piece

        let estimatedFeeCell = tableView.dequeueCell(DisclosureWithContentCell.self)
        estimatedFeeCell.setText("Estimated gas fee")

        let amountPiece = AmountAndValuePiece()
        amountPiece.setAmount("Some amount")
        amountPiece.setFiatAmount("some fiat")

        estimatedFeeCell.setContent(amountPiece)

        return estimatedFeeCell
    }

    func buildAdvancedParameters(tableView: UITableView) -> UITableViewCell {
        let advancedCell = tableView.dequeueCell(SecondaryDetailDisclosureCell.self)
        advancedCell.setText("Advanced parameters")
        return advancedCell
    }

    // MARK: New Transfer Header

    override func buildHeader(_ tx: SCGModels.TransactionDetails) {
        // multi-level enums
        guard case SCGModels.TxInfo.transfer(let transferTx) = tx.txInfo else {
            super.buildHeader(tx)
            return
        }

        // amount
        let amountModel = tokenAmount(from: transferTx.transferInfo)
        buildAmount(amountModel: amountModel)

        // from
        let (senderLabel, senderLogo) = NamingPolicy.name(for: transferTx.sender, chainId: chain.id!)
        let senderUrl = chain.browserURL(address: transferTx.sender.value.address.checksummed)

        // to
        let (recipientLabel, recipientLogo) = NamingPolicy.name(for: transferTx.recipient, chainId: chain.id!)
        let recipientUrl = chain.browserURL(address: transferTx.sender.value.address.checksummed)

        self.addresses([
            (address: transferTx.sender.value.address, label: senderLabel,
             imageUri: senderLogo, title: "From", browseURL: senderUrl, prefix: chain.shortName),

            (address: transferTx.recipient.value.address, label: recipientLabel,
             imageUri: recipientLogo, title: "To", browseURL: recipientUrl, prefix: chain.shortName)
        ])
    }

    func buildAmount(amountModel: TokenAmountUIModel) {
        let cell = newCell(DetailMultiAccountsCell.self)
        let tokenView = TokenInfoView()
        tokenView.setTitle("Amount")
        tokenView.setImage(amountModel.tokenLogoURL, placeholder: amountModel.placeholder)
        tokenView.setText(amountModel.formattedAmount)
        tokenView.setDetail(amountModel.formattedFiatValue, style: .caption1.weight(.medium))
        cell.setViews([tokenView])
        result.append(cell)
    }

    func tokenAmount(from transferInfo: SCGModels.TxInfo.Transfer.TransferInfo) -> TokenAmountUIModel {
        var result = TokenAmountUIModel()

        switch transferInfo {
        case .erc20(let erc20):
            result.value = erc20.value.value
            result.decimals = erc20.decimals
            result.symbol = erc20.tokenSymbol ?? "ERC20"
            result.tokenLogoUri = erc20.logoUri

        case .nativeCoin(let native):
            let coin = Chain.nativeCoin!
            result.value = native.value.value
            result.decimals = UInt64(coin.decimals)
            result.symbol = coin.symbol!
            result.tokenLogoUri = coin.logoUrl?.absoluteString

        case .erc721(let erc721):
            result.value = 1
            result.decimals = 0
            result.symbol = erc721.tokenSymbol ?? "NFT"
            result.tokenLogoUri = erc721.logoUri
            result.placeholder = UIImage(named: "ico-nft-placeholder")
            result.detail = erc721.tokenId.description

        case .unknown:
            break
        }
        return result
    }
}

struct TokenAmountUIModel {
    var value: UInt256?
    var symbol: String = ""
    var decimals: UInt64?
    var detail: String?
    var tokenLogoUri: String?
    var placeholder = UIImage(named: "ico-token-placeholder")

    var formattedAmount: String {
        let tokenAmountText: String
        if let value = value {
            let decimalAmount = BigDecimal(Int256(value),
                                           decimals.flatMap { Int($0) } ?? 0)

            let amount = TokenFormatter().string(
                from: decimalAmount,
                decimalSeparator: Locale.autoupdatingCurrent.decimalSeparator ?? ".",
                thousandSeparator: Locale.autoupdatingCurrent.groupingSeparator ?? ",",
                forcePlusSign: false
            )

            tokenAmountText = "\(amount) \(symbol)"
        } else {
            tokenAmountText = "Unknown token"
        }
        return tokenAmountText
    }

    var formattedFiatValue: String {
        // TODO: Fetch fiat amount
        detail ?? "fiat amount"
    }

    var tokenLogoURL: URL? {
        tokenLogoUri.flatMap { URL(string: $0) }
    }
}

struct ExecutionReviewUIModel {
    var transaction: SCGModels.TransactionDetails
    var executionOptions: ExecutionOptionsUIModel
}

struct ExecutionOptionsUIModel {
    var accountState: ExecuteWithAccountCellState = .loading
    var feeState: EstimatedFeeCellState = .loading
}

enum ExecuteWithAccountCellState {
    case loading
    case empty
    case filled(MiniAccountInfoUIModel)
}

struct MiniAccountInfoUIModel {
    var prefix: String?
    var address: Address
    var label: String?
    var imageUri: URL?
    var badge: String?
    var balance: String?
}

enum EstimatedFeeCellState {
    case loading
    case loaded(EstimatedFeeUIModel)
}

struct EstimatedFeeUIModel {
    var tokenAmount: String
    var fiatAmount: String?
}
