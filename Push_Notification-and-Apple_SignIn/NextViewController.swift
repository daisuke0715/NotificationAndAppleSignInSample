//
//  NextViewController.swift
//  Push_Notification-and-Apple_SignIn
//
//  Created by 河村大介 on 2021/03/30.
//

import UIKit
import Firebase
import FirebaseAuth


class NextViewController: UIViewController {

    @IBOutlet weak var pushButton: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // sign with Apple から取得したデータを表示
        // idを取ってこれるので、ユーザを識別できる
         print(Auth.auth().currentUser?.uid)
         print(Auth.auth().currentUser?.displayName)
         print(Auth.auth().currentUser?.email)
        
    }

        
    @IBAction func push(_ sender: Any) {
        let content = UNMutableNotificationContent()
            
            content.title = "【打倒】Cippo"
            content.subtitle = "ベトナムのエンジニアには負けません"
            content.body = "Cippoと横山を殺す"
            content.sound = .default
            
            // 通知を表示(triggerでプッシュ通知を通知するタイミングを設定できる)
            let request = UNNotificationRequest(identifier: "localPush", content: content, trigger: nil)
            UNUserNotificationCenter.current().add(request, withCompletionHandler: nil)
    }
   
    
}
