//
//  PendingWCTransaction.swift
//  Multisig
//
//  Created by Andrey Scherbovich on 04.02.21.
//  Copyright © 2021 Gnosis Ltd. All rights reserved.
//

import Foundation
import CoreData

extension WCPendingTransaction {
    static func getAll() throws -> [WCPendingTransaction] {
        do {
            let context = App.shared.coreDataStack.viewContext
            let fr = WCPendingTransaction.fetchRequest().all()
            let transactions = try context.fetch(fr)
            return transactions
        } catch {
            throw GSError.DatabaseError(reason: error.localizedDescription)
        }
    }

    static func create(wcSession: WCSession, nonce: UInt256String) {
        dispatchPrecondition(condition: .onQueue(.main))
        let context = App.shared.coreDataStack.viewContext
        let pendingTransaction = WCPendingTransaction(context: context)
        pendingTransaction.session = wcSession
        pendingTransaction.nonce = nonce.description
        App.shared.coreDataStack.saveContext()
    }
}

extension NSFetchRequest where ResultType == WCPendingTransaction {
    func all() -> Self {
        sortDescriptors = []
        return self
    }
}
