//
//  MultiPeerConnectionManager.swift
//  OSFeaturesDay
//
//  Created by Jatin Arora on 18/06/16.
//  Copyright © 2016 JatinArora. All rights reserved.
//

import Foundation
import MultipeerConnectivity

class MultiPeerConnectionManager: NSObject {
    
    // Instantiate the Singleton
    static let sharedManager = MultiPeerConnectionManager()
    
    let serviceType = "xx-service"
    var browser : MCNearbyServiceBrowser? = nil
    let localPeerID = MCPeerID(displayName: UIDevice.current().name)
    var currentSession : MCSession? = nil
    var advertiser : MCNearbyServiceAdvertiser? = nil
    
    var messagesToSend = [String]()
    
    
    static let kMultiPeerMessageReceived_NotificationName = "multi.peer.message.received.notification"
    

    private override init() {
        super.init()
        
        self.automaticallyStartAdvertising()
        self.automaticallyStartBrowsing()
        
        NotificationCenter.default().addObserver(self, selector: #selector(MultiPeerConnectionManager.messageReceived(_:)), name: WatchSessionManager.kMessageReceivedNotification_Name, object: nil)
    }

    
    func automaticallyStartAdvertising() {
        
        advertiser = MCNearbyServiceAdvertiser(peer: localPeerID, discoveryInfo: nil, serviceType: serviceType)
        advertiser?.delegate = self
        
        advertiser?.startAdvertisingPeer()
        
    }
    
    func automaticallyStartBrowsing() {
        
        browser = MCNearbyServiceBrowser(peer: localPeerID, serviceType: serviceType)
        browser?.delegate = self
        
        let session = MCSession(peer: localPeerID, securityIdentity: nil, encryptionPreference: .none)
        session.delegate = self
        browser?.startBrowsingForPeers()
        
        
        
//        let browserVC = MCBrowserViewController(browser: browser!, session: session)
//        browserVC.delegate = self
//        
//        present(browserVC, animated: true) {
//            self.browser?.startBrowsingForPeers()
//        }
        
    }
    
    
    func checkIfMessageFromSelfPeer(peerID : MCPeerID) -> Bool {
        
        if peerID.displayName == localPeerID.displayName {
            return true
        }
        
        return false
    }
    
    //Message received from watch session manager
    //This recevies a Dictionary so handle it carefully
    
     func messageReceived(_ notification : Notification) {
        
        let obj = notification.object
        
        if let obj = obj as? [String : AnyObject?] {
            messagesToSend.append((obj.first?.value as? String)!)
        }
        
    }
}


//extension MultiPeerConnectionManager : MCBrowserViewControllerDelegate {
//    
//    func browserViewControllerDidFinish(_ browserViewController: MCBrowserViewController) {
//        
//        dismiss(animated: true, completion: nil)
//        
//    }
//    
//    func browserViewControllerWasCancelled(_ browserViewController: MCBrowserViewController) {
//        
//        dismiss(animated: true, completion: nil)
//        
//    }
//    
//}

extension MultiPeerConnectionManager : MCSessionDelegate {
    
    
    func session(_ session: MCSession, didReceive data: Data, fromPeer peerID: MCPeerID) {
        
        if self.checkIfMessageFromSelfPeer(peerID: peerID) == true {
            return
        }
        
        let dataString = NSKeyedUnarchiver.unarchiveObject(with: data) as? String
        
        if let str = dataString {
            
            DispatchQueue.main.async(execute: {
                NotificationCenter.default().post(name: Notification.Name(rawValue : MultiPeerConnectionManager.kMultiPeerMessageReceived_NotificationName),
                                                  object: str,
                                                  userInfo: nil)
            })
            
        }
        
    }
    
    
    
    func session(_ session: MCSession, peer peerID: MCPeerID, didChange state: MCSessionState) {
        
        //If in some corner case we get message from self, ignore it
        
        if self.checkIfMessageFromSelfPeer(peerID: peerID) == true {
            return
        }
        
        
        var messagesToRemove = [String]()
        
        if state == .connected {
            

            //Send messages in a loop
            
            for message in messagesToSend {
                
                print("Sending data to peer \(message)")
                
                let archivedObject = NSKeyedArchiver.archivedData(withRootObject: messagesToSend)
                
                do {
                    try session.send(archivedObject, toPeers: [peerID], with: .reliable)
                    messagesToRemove.append(message)
                    
                } catch {
                    print("Data send failed")
                }

                
            }
            

            
            
        } else {
            
            print("ERROR :: For some reason the state is disconnected")
            
        }
        
        
        //Remove the messages already sent
        
        for message in messagesToRemove {
            
            let index = messagesToSend.index(where: { (obj) -> Bool in
                return obj == message
            })
            
            if let index = index {
                messagesToSend.remove(at: index)
            }
            
        }
    }
    
    func session(_ session: MCSession, didReceive stream: InputStream, withName streamName: String, fromPeer peerID: MCPeerID) {
        
    }
    
    func session(_ session: MCSession, didStartReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, with progress: Progress) {
        
    }
    
    func session(_ session: MCSession, didFinishReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, at localURL: URL, withError error: NSError?) {
        
        
        
    }
    
    
}

extension MultiPeerConnectionManager : MCNearbyServiceBrowserDelegate {
    
    func browser(_ browser: MCNearbyServiceBrowser, foundPeer peerID: MCPeerID, withDiscoveryInfo info: [String : String]?) {
        
        if self.checkIfMessageFromSelfPeer(peerID: peerID) == true {
            return
        }

        
        if let session = currentSession {
            browser.invitePeer(peerID, to: session, withContext: nil, timeout: 30)
        }
    }
    
    func browser(_ browser: MCNearbyServiceBrowser, lostPeer peerID: MCPeerID) {
        
        
    }
    
}

extension MultiPeerConnectionManager : MCNearbyServiceAdvertiserDelegate {
    
    func advertiser(_ advertiser: MCNearbyServiceAdvertiser,
                    didReceiveInvitationFromPeer peerID: MCPeerID,
                    withContext context: Data?,
                    invitationHandler: (Bool, MCSession?) -> Void) {
        
        
        if self.checkIfMessageFromSelfPeer(peerID: peerID) == true {
            return
        }

        
        invitationHandler(true, currentSession)
        
    }
    
    func advertiser(_ advertiser: MCNearbyServiceAdvertiser, didNotStartAdvertisingPeer error: NSError) {
        print("ERROR :: Was not able to advertise due to some error")
    }
    
    
}
