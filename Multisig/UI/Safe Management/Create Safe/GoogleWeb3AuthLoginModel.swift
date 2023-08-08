import Foundation
import CustomAuth
import UIKit
import tkey_pkg


class GoogleWeb3AuthLoginModel {
    let notificationCenter = NotificationCenter.default
    static let schemePostfix = "://"
    var authorizationComplete: (() -> Void)!
    var keyGenerationComplete: ((_ key: String?, _ email: String?, _ error: Error?) -> Void?)!

    init() {
        notificationCenter.addObserver(self, selector: #selector(handleAuthorizationComplete), name: NSNotification.Name("TSDSDKCallbackNotification"), object: nil)
    }

    func loginWithCustomAuth() {
        Task {
            //            let sub = SubVerifierDetails(loginType: .installed,
            //                                         loginProvider: .google,
            //                                         clientId: App.configuration.web3auth.googleClientId,
            //                                         verifier: App.configuration.web3auth.googleVerifierSub,
            //                                         redirectURL: App.configuration.web3auth.redirectScheme + GoogleWeb3AuthLoginModel.schemePostfix
            //            )
            //            let tdsdk = CustomAuth(aggregateVerifierType: .singleIdVerifier,
            //                                   aggregateVerifier: App.configuration.web3auth.googleVerifierAggregate,
            //                                   subVerifierDetails: [sub],
            //                                   network: .CYAN,
            //                                   enableOneKey: true
            //            )

            let sub = SubVerifierDetails(loginType: .installed,
                                         loginProvider: .google,
                                         clientId: "500572929132-57dbeqrtq84m5oibve186vfmdd6p5rmh.apps.googleusercontent.com",
                                         verifier: "google-sub-bttr-500572929132",
                                         redirectURL: "com.googleusercontent.apps.500572929132-57dbeqrtq84m5oibve186vfmdd6p5rmh://"

            )
            let tdsdk = CustomAuth(aggregateVerifierType: .singleIdVerifier,
                                   aggregateVerifier: "google-aggregate-bttr",
                                   subVerifierDetails: [sub],
                                   network: .CYAN,
                                   enableOneKey: true
            )

            do {
                let data = try await tdsdk.triggerLogin(browserType: .asWebAuthSession)
                
                await MainActor.run(body: {
                    let key = data["privateKey"] as? String
                    let userInfo = data["userInfo"] as? [String: Any] ?? [:]
                    let email = userInfo["email"] as? String ?? "email withheld"

                    dump(data, name: "---> data")

                    //TODO generate threshold key
                    Task {

                        guard let fetchKey = data["publicAddress"] as? String else {
                            App.shared.snackbar.show(message: "Failed to get public address from userinfo")
                            return
                        }

                        guard let storage_layer = try? StorageLayer(enable_logging: true, host_url: "https://metadata.tor.us", server_time_offset: 2) else {
                            App.shared.snackbar.show(message: "Failed to create storage layer")
                            return
                        }

                        guard let service_provider = try? ServiceProvider(enable_logging: true, postbox_key: key!) else {
                            App.shared.snackbar.show(message: "Failed to create service provider")
                            return
                        }


                        guard let thresholdKey = try? ThresholdKey(
                            storage_layer: storage_layer,
                            service_provider: service_provider,
                            enable_logging: true,
                            manual_sync: false) else {
                            App.shared.snackbar.show(message: "Failed to create threshold key")
                            return
                        }

                        guard let key_details = try? await thresholdKey.initialize(never_initialize_new_key: true, include_local_metadata_transitions: false) else {
                            App.shared.snackbar.show(message: "Failed to get key details")

                            return
                        }

                        var shares: [String] = ["c0b1964f56e68fd46e8af646fea56a45f134438ee26ed99a07b27d23f881d1a0"
                            // "f2bc1cd32962df4e3f5d5ebb52568acac46dd31a99790155f874485dc8bea088",
//                                                "d4711d433269d3e98bf3607b01bddfee9def715112e2e21c246f7a711768236e",
//                                                "4a240d7a5ebc1c563619c46fa41877bd9e33367d211429e8438f954fd953c52f", // Seems to be the postbox key share
//                                                "c0b1964f56e68fd46e8af646fea56a45f134438ee26ed99a07b27d23f881d1a0"
                        ] //bttr.tstr@google-aggregate-bttr
                        for item in shares {
                            LogService.shared.debug("---> Trying share: \(item)")
                            if let _ = try? await thresholdKey.input_share(share: item, shareType: nil)  {

                            } else {
                                //App.shared.snackbar.show(message: "Incorrect share was used (84)")
                                LogService.shared.debug("---> Incorrect share was used: \(item)")

                            }
                        }
                        dump (key_details, name: "---> key details")

                        //let final_key = thresholdKey.key

                        if let reconstructionDetails = try? await thresholdKey.reconstruct() {
                            // safe shares
                            let shareIndexes = try thresholdKey.get_shares_indexes()

                            // TODO: Save only one share, which is device share and not all shares.
                            for i in 0..<2 {
                                let saveId = fetchKey + ":" + String(i)

                                guard let share = try? thresholdKey.output_share(shareIndex: shareIndexes[Int(i)]) else {
                                    App.shared.snackbar.show(message: "Failed to output share")
                                    return
                                }

                                LogService.shared.debug("Saving share: \(share) at \(saveId)")

                                guard let _ = try? KeychainInterface.save(item: share, key: saveId) else {
                                    App.shared.snackbar.show(message: "Failed to save share")
                                    return
                                }
                            }

                            do {
                                let shareIndexes = try thresholdKey.get_shares_indexes()
                                for i in 0..<shareIndexes.count {
                                    //print("shareIndex: \(shareIndexes[Int(i)])")
                                    guard let share = try? thresholdKey.output_share(shareIndex: shareIndexes[Int(i)]) else {
                                        print("Failed to output share")
                                        return
                                    }
                                    print("---> Listing share: \(share) at \(i)")
                                }
                            } catch {
                                print("Export share failed: \(error.localizedDescription)")
                            }



                            keyGenerationComplete(reconstructionDetails.key, email + " (MFA)", nil)
                        } else {
                            let threshold = Int(key_details.threshold)
                            App.shared.snackbar.show(message: "Failed to reconstruct key. \(threshold) share(s) required. Trying again. With hardcoced shares")

                            var shares: [String] = ["f2bc1cd32962df4e3f5d5ebb52568acac46dd31a99790155f874485dc8bea088",
                                                    "d4711d433269d3e98bf3607b01bddfee9def715112e2e21c246f7a711768236e",
                                                    "4a240d7a5ebc1c563619c46fa41877bd9e33367d211429e8438f954fd953c52f",
                                                    "c0b1964f56e68fd46e8af646fea56a45f134438ee26ed99a07b27d23f881d1a0"
                            ] //bttr.tstr@google-aggregate-bttr

                            //                                var shares: [String] = ["69b2faad80ea516cf41474aa111aaa454617e8c823290443679415b7d3690530",
                            //                                                        "6190269874f8ff83abd793e31c6108896bb9ceef88562028ade5ebaa929b4234"] // ego.other@google-aggregate-bttr


                            for item in shares {
                                LogService.shared.debug("input_share: \(item)")
                                guard let _ = try? await thresholdKey.input_share(share: item, shareType: nil) else {
                                    App.shared.snackbar.show(message: "Incorrect share was used")
                                    return
                                }
                            }

                            guard let reconstructionDetails = try? await thresholdKey.reconstruct() else {
                                App.shared.snackbar.show(message: "Failed to reconstruct key with available shares.")
                                return
                            }

                            let shareIndexes = try thresholdKey.get_shares_indexes()

                            // TODO: Save only one share, which is device share and not all shares.
                            for i in 0..<2 {
                                let saveId = fetchKey + ":" + String(i)

                                guard let share = try? thresholdKey.output_share(shareIndex: shareIndexes[Int(i)]) else {
                                    App.shared.snackbar.show(message: "Failed to output share")
                                    return
                                }

                                LogService.shared.debug("Saving share: \(share) at \(saveId)")

                                guard let _ = try? KeychainInterface.save(item: share, key: saveId) else {
                                    App.shared.snackbar.show(message: "Failed to save share")
                                    return
                                }
                            }

                            dump(reconstructionDetails, name: "---> reconstructionDetails")
                            App.shared.snackbar.show(message: "key: \(reconstructionDetails.key)")

                            do {
                                let shareIndexes = try thresholdKey.get_shares_indexes()
                                for i in 0..<shareIndexes.count {
                                    //print("shareIndex: \(shareIndexes[Int(i)])")
                                    guard let share = try? thresholdKey.output_share(shareIndex: shareIndexes[Int(i)]) else {
                                        print("Failed to output share")
                                        return
                                    }
                                    print("---> Listing share: \(share) at \(i)")
                                }
                            } catch {
                                print("Export share failed: \(error.localizedDescription)")
                            }

                            keyGenerationComplete(reconstructionDetails.key, email + " (MFA)", nil)
                        }
                    }

                    // keyGenerationComplete(key, email + " (SFA)", nil)
                })
            } catch {
                await MainActor.run(body: {
                    keyGenerationComplete(nil, nil, error)
                })
            }
        }
    }

    @objc
    func handleAuthorizationComplete() {
        authorizationComplete()
        notificationCenter.removeObserver(self)
    }
}
