//
//  InterfaceController.swift
//  OSFeaturesDay WatchKit Extension
//
//  Created by Jatin Arora on 18/06/16.
//  Copyright © 2016 JatinArora. All rights reserved.
//

import WatchKit
import Foundation


class InterfaceController: WKInterfaceController {

    @IBOutlet var messageLabel : WKInterfaceLabel!
    
    override func awake(withContext context: AnyObject?) {
        super.awake(withContext: context)
        
        NotificationCenter.default().addObserver(self, selector: #selector(InterfaceController.messageReceivedFromExtension(_:)), name: WatchExtensionSessionManager.kExtensionMessageReceivedNotification_Name, object: nil)
    }
    
    
    @IBAction func buttonTapped() {
        
        WatchExtensionSessionManager.sharedManager.sendMessage(message: ["message" : "1234"] )
        
    }
    
    
    func messageReceivedFromExtension(_ notification: Notification) {
        
        if let obj = notification.object as? [String : String] {
            messageLabel.setText(obj.first?.value)
        }
        
    }
}
