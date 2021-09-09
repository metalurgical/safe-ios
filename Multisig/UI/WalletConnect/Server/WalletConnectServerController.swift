//
//  WalletConnectServerController.swift
//  Multisig
//
//  Created by Andrey Scherbovich on 20.01.21.
//  Copyright © 2021 Gnosis Ltd. All rights reserved.
//

import Foundation
import WalletConnectSwift

enum SessionStatus: Int {
    case connecting = 0
    case connected = 1
}

class WalletConnectServerController: ServerDelegate {
    private(set) var server: Server!
    private let notificationCenter = NotificationCenter.default
    private var showedNotificationsSessionTopics = [String]()

    // Subclasses should override
    var connectingNotification: NSNotification.Name!
    var disconnectingNotification: NSNotification.Name!
    var didFailToConnectNotificatoin: NSNotification.Name!
    var didConnectNotificatoin: NSNotification.Name!
    var didDisconnectNotificatoin: NSNotification.Name!

    init() {
        server = Server(delegate: self)        
    }

    func connect(url: String) throws {
        guard let wcurl = WCURL(url) else { throw GSError.InvalidWalletConnectQRCode() }
        do {
            createSession(wcurl: wcurl)
            try server.connect(to: wcurl)
            notificationCenter.post(name: connectingNotification, object: wcurl)
        } catch {
            throw GSError.CouldNotStartWallectConnectSession()
        }
    }

    func createSession(wcurl: WCURL) {
        preconditionFailure("Subclass should override createSession method")
    }

    func disconnect(topic: String) {
        guard let session = getSession(topic: topic) else { return }
        do {
            try server.disconnect(from: session)
            notificationCenter.post(name: disconnectingNotification, object: nil)
        } catch {
            LogService.shared.error("Error while disconnecting session", error: error)
        }
    }

    func getSession(topic: String) -> Session? {
        preconditionFailure("Subclasses should override this method")
    }

    // MARK: - ServerDelegate

    func server(_ server: Server, didFailToConnect url: WCURL) {
        DispatchQueue.main.sync {
            deleteStoredSession(topic: url.topic)
        }
        notificationCenter.post(name: didFailToConnectNotificatoin, object: url)
    }

    func deleteStoredSession(topic: String) {
        preconditionFailure("Subclasses should override this method")
    }

    func server(_ server: Server, shouldStart session: Session, completion: @escaping (Session.WalletInfo) -> Void) {
        preconditionFailure("Subclass should override createSession method")
    }

    #warning("TODO: make snackbar message display business of view controllers")
    #warning("TODO: figure our why with sync update it crashes")
    func server(_ server: Server, didConnect session: Session) {
        DispatchQueue.main.async { [unowned self] in
            self.update(session: session, status: .connected)
            notificationCenter.post(name: didConnectNotificatoin, object: session)
        }

        // skip snackbar notification for reconnect cases
        if !showedNotificationsSessionTopics.contains(session.url.topic) {
            showedNotificationsSessionTopics.append(session.url.topic)
            DispatchQueue.main.async {
                App.shared.snackbar.show(message: "WalletConnect session created! Please return back to the browser.")
            }
        }
    }

    func update(session: Session, status: SessionStatus) {
        preconditionFailure("Subclass should override createSession method")
    }

    func server(_ server: Server, didDisconnect session: Session) {
        DispatchQueue.main.sync { [unowned self] in
            self.deleteStoredSession(topic: session.url.topic)
        }
        notificationCenter.post(name: didDisconnectNotificatoin, object: session)
    }

    func server(_ server: Server, didUpdate session: Session) {
        DispatchQueue.main.sync {
            update(session: session, status: .connected)
        }
    }

    func denySession(clientMeta: Session.ClientMeta,
                     displayMessage: String? ,
                     completion: (Session.WalletInfo) -> Void) {
        let walletInfo = Session.WalletInfo(
            approved: false,
            accounts: [],
            chainId: Int(Chain.ChainID.ethereumMainnet)!,
            peerId: UUID().uuidString,
            peerMeta: clientMeta)

        if let displayMessage = displayMessage {
            DispatchQueue.main.async {
                App.shared.snackbar.show(message: displayMessage)
            }
        }

        completion(walletInfo)
    }
}
