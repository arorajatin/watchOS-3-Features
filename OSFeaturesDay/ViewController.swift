//
//  ViewController.swift
//  OSFeaturesDay
//
//  Created by Jatin Arora on 18/06/16.
//  Copyright © 2016 JatinArora. All rights reserved.
//

import UIKit
import MultipeerConnectivity
import WatchConnectivity


class ViewController: UIViewController {
    
    let serviceType = "xx-service"
    var browser : MCNearbyServiceBrowser? = nil
    let localPeerID = MCPeerID(displayName: UIDevice.current().name)
    var currentSession : MCSession? = nil
    var advertiser : MCNearbyServiceAdvertiser? = nil
    
    
    @IBOutlet weak var browseButton: UIButton!
    @IBOutlet weak var advertiseButton: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        currentSession = MCSession(peer: localPeerID, securityIdentity: nil, encryptionPreference: .none)
        currentSession?.delegate = self
        
    }
    
    
    @IBAction func advertiseButtonPressed(_ sender: AnyObject) {
        
        advertiser = MCNearbyServiceAdvertiser(peer: localPeerID, discoveryInfo: nil, serviceType: serviceType)
        advertiser?.delegate = self
        
        advertiser?.startAdvertisingPeer()
        
    }
    
    @IBAction func browseButtonPressed(_ sender: AnyObject) {
        
        browser = MCNearbyServiceBrowser(peer: localPeerID, serviceType: serviceType)
        browser?.delegate = self
        
        let session = MCSession(peer: localPeerID, securityIdentity: nil, encryptionPreference: .none)
        session.delegate = self
        
        
        let browserVC = MCBrowserViewController(browser: browser!, session: session)
        browserVC.delegate = self
        
        present(browserVC, animated: true) { 
            self.browser?.startBrowsingForPeers()
        }
    }
    
    @IBAction func sendMessageToWatch(_ sender: AnyObject) {
        
        WatchSessionManager.sharedManager.sendMessage(message: ["message" : "This is a message from app to extension"], replyHandler: nil, errorHandler: nil)
        
    }
}

extension ViewController : MCBrowserViewControllerDelegate {
    
    func browserViewControllerDidFinish(_ browserViewController: MCBrowserViewController) {
        
        dismiss(animated: true, completion: nil)
        
    }
    
    func browserViewControllerWasCancelled(_ browserViewController: MCBrowserViewController) {
        
        dismiss(animated: true, completion: nil)
        
    }
    
}

extension ViewController : MCSessionDelegate {
    
    
    func session(_ session: MCSession, didReceive data: Data, fromPeer peerID: MCPeerID) {
        
        let dataString = NSString(data: data, encoding: String.Encoding.utf8.rawValue)
        print("dataString = \(dataString!)")
        
        
    }

    
    
    func session(_ session: MCSession, peer peerID: MCPeerID, didChange state: MCSessionState) {
        
        if state == .connected {
            let str = "Hello brother"
            
            print("Sending data to peer \(str)")
            
            do {
                try session.send(str.data(using: String.Encoding.utf8)!, toPeers: [peerID], with: .reliable)
            } catch  {
                print("Data send failed")
            }
            
        } else {
            
            print("ERROR :: For some reason the state is disconnected")
            
        }
        
        
    }
    
    func session(_ session: MCSession, didReceive stream: InputStream, withName streamName: String, fromPeer peerID: MCPeerID) {
        
    }
    
    func session(_ session: MCSession, didStartReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, with progress: Progress) {
        
    }
    
    func session(_ session: MCSession, didFinishReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, at localURL: URL, withError error: NSError?) {
        
        
        
    }
    
    
}

extension ViewController : MCNearbyServiceAdvertiserDelegate, MCNearbyServiceBrowserDelegate {
    
    func advertiser(_ advertiser: MCNearbyServiceAdvertiser,
                    didReceiveInvitationFromPeer peerID: MCPeerID,
                    withContext context: Data?,
                    invitationHandler: (Bool, MCSession?) -> Void) {
        
        invitationHandler(true, currentSession)
        
    }
    
    func advertiser(_ advertiser: MCNearbyServiceAdvertiser, didNotStartAdvertisingPeer error: NSError) {
        print("ERROR :: Was not able to advertise due to some error")
    }
    
    func browser(_ browser: MCNearbyServiceBrowser, foundPeer peerID: MCPeerID, withDiscoveryInfo info: [String : String]?) {
        
        if let session = currentSession {
           browser.invitePeer(peerID, to: session, withContext: nil, timeout: 30)
        }
    }
    
    func browser(_ browser: MCNearbyServiceBrowser, lostPeer peerID: MCPeerID) {
        
        
        
    }
    
    
}



