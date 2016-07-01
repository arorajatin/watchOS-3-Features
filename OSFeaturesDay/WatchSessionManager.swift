//
//  WatchSessionManager.swift
//  OSFeaturesDay
//
//  Created by Jatin Arora on 18/06/16.
//  Copyright © 2016 JatinArora. All rights reserved.
//

import WatchConnectivity

// Note that the WCSessionDelegate must be an NSObject
// So no, you cannot use the nice Swift struct here!
class WatchSessionManager: NSObject {
    
    // Instantiate the Singleton
    static let sharedManager = WatchSessionManager()
    
    //Main application specific (framework) notification
    static let kMessageReceivedNotification_Name = "message.received.notification.name"
    static let kReceivedMessageProcessedByApp = "kReceivedMessageProcessedByApp"
    
    private override init() {
        super.init()
        
        NotificationCenter.default().addObserver(self, selector: #selector(WatchSessionManager.messageReceivedFromMultiPeer(_:)), name: MultiPeerConnectionManager.kMultiPeerMessageReceived_NotificationName, object: nil)

    }
    
    // Keep a reference for the session,
    // which will be used later for sending / receiving data
    
    private let session : WCSession? = WCSession.isSupported() ? WCSession.default() : nil
    
    
    private var validSession: WCSession? {
        
        // paired - the user has to have their device paired to the watch
        // watchAppInstalled - the user must have your watch app installed
        
        // Note: if the device is paired, but your watch app is not installed
        // consider prompting the user to install it for a better experience
        
        if let session = session where session.isPaired && session.isWatchAppInstalled {
            return session
        }
        return nil
    }
    
    // Live messaging! App has to be reachable
    private var validReachableSession: WCSession? {
        
        if let session = validSession where session.isReachable {
            return session
        }
        
        return nil
        
    }
    
    
    // Activate Session
    // This needs to be called to activate the session before first use!
    func startSession() {
        session?.delegate = self
        session?.activate()
    }
    
    
    func messageReceivedFromMultiPeer(_ notification : Notification) {
        
        if let str = notification.object as? String {
            
            //Send message to watch
            self.sendMessage(message: [str : str])
            
            //Post a notification if required
            DispatchQueue.main.async {
                NotificationCenter.default().post(Notification(name: Notification.Name(rawValue : WatchSessionManager.kReceivedMessageProcessedByApp), object: str, userInfo: nil))
            }
            
        }
        
    }
}

extension WatchSessionManager {
    
    func sendMessage(message: [String : AnyObject],
                     replyHandler: (([String : AnyObject]) -> Void)? = nil,
                     errorHandler: ((NSError) -> Void)? = nil)
    {
        validReachableSession?.activate()
        validReachableSession?.sendMessage(message, replyHandler: replyHandler, errorHandler: { (error) in
            print("ERROR in sending message:: \(error)")
        })
    }
    
    func sendMessageData(data: NSData,
                         replyHandler: ((Data) -> Void)? = nil,
                         errorHandler: ((NSError) -> Void)? = nil)
    {
        validReachableSession?.sendMessageData(data as Data, replyHandler: replyHandler, errorHandler: errorHandler)
    }

    
}



extension WatchSessionManager : WCSessionDelegate {
    
    
    func session(_ session: WCSession, didReceiveMessage message: [String : AnyObject], replyHandler: ([String : AnyObject]) -> Void) {
        
        print("Message received inside application = \(message)")
        
        DispatchQueue.main.async {
            NotificationCenter.default().post(Notification(name: Notification.Name(rawValue : WatchSessionManager.kMessageReceivedNotification_Name), object: message, userInfo: nil))
        }

        
    }
    
    func session(_ session: WCSession, didReceiveMessage message: [String : AnyObject]) {
        
        print("Message received inside application = \(message)")
        
        DispatchQueue.main.async {
            NotificationCenter.default().post(Notification(name: Notification.Name(rawValue : WatchSessionManager.kMessageReceivedNotification_Name), object: message, userInfo: nil))
        }

        
    }
    
    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: NSError?) {
        
    }
    
    
    func sessionDidBecomeInactive(_ session: WCSession) {
        
    }
    
    
    func sessionWatchStateDidChange(_ session: WCSession) {
        
    }
    
    func sessionDidDeactivate(_ session: WCSession) {
        
    }
}
