//
//  ViewController.swift
//  Push_Notification-and-Apple_SignIn
//
//  Created by 河村大介 on 2021/03/30.
//

import UIKit
import AuthenticationServices
// 暗号化で使うもの
import CryptoKit
import Firebase
import FirebaseAuth
import PKHUD


class ViewController: UIViewController, ASAuthorizationControllerDelegate, ASAuthorizationControllerPresentationContextProviding {
    
    var currentNonce: String?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let authOption: UNAuthorizationOptions = [.alert, .badge, .sound]
        UNUserNotificationCenter.current().requestAuthorization(options: authOption) { (_, _) in
            
            print("プッシュ許可画面OK")
            
        }
        
        
        let appleButton = ASAuthorizationAppleIDButton(authorizationButtonType: .signIn, authorizationButtonStyle: .white)
        
        appleButton.frame = CGRect(x: 56, y: 395, width: 264, height: 50)
        appleButton.addTarget(self, action: #selector(tap), for: .touchUpInside)
        view.addSubview(appleButton)
        
        
        
    }
       
    // アップルサインインボタンクリック時の挙動
    @objc func tap(){
        // ナンス（ランダムな文字列の生成）
        let nonce = randomNonceString()
        
        currentNonce = nonce
        let request = ASAuthorizationAppleIDProvider().createRequest()
        
        request.nonce = sha256(nonce)
        
        let controller = ASAuthorizationController(authorizationRequests: [request])
        controller.delegate = self
        controller.presentationContextProvider = self
        controller.performRequests()
        
        
    }
    
    
    
    // Appleのサインインの時、ログインリクエストごとにランダムな文字列であるナンスを生成する
    // ナンスは、取得したIDトークンがアプリの認証リクエストのレスポンスとして封されたことを確認するために使用する
    // リプレイ攻撃の防止につながる
    // リプレイ攻撃 => ユーザがログインするときにネットワークを流れるデータがあって、それを盗聴してコピーしてコピーしたデータを認証サーバへ送ることでシステムに不正ログインをすること
    // このリプレイ攻撃の対策になるのが、任意の文字列ナンスを使った暗号化とこれらの文字列をハッシュ化するSHAを用いる
    // ランダムな文字列ナンスを作成して、それをSHA256関数を用いてハッシュ化しているだけ
    private func randomNonceString(length: Int = 32) -> String {
        precondition(length > 0)
        let charset: Array<Character> =
            Array("0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._")
        var result = ""
        var remainingLength = length
        
        while remainingLength > 0 {
            let randoms: [UInt8] = (0 ..< 16).map { _ in
                var random: UInt8 = 0
                let errorCode = SecRandomCopyBytes(kSecRandomDefault, 1, &random)
                if errorCode != errSecSuccess {
                    fatalError("Unable to generate nonce. SecRandomCopyBytes failed with OSStatus \(errorCode)")
                }
                return random
            }
            
            randoms.forEach { random in
                if remainingLength == 0 {
                    return
                }
                
                if random < charset.count {
                    result.append(charset[Int(random)])
                    remainingLength -= 1
                }
            }
        }
        
        return result
    }
    
    private func sha256(_ input: String) -> String {
        let inputData = Data(input.utf8)
        let hashedData = SHA256.hash(data: inputData)
        let hashString = hashedData.compactMap {
            return String(format: "%02x", $0)
        }.joined()
        
        return hashString
    }
    
    
    //
    func authorizationController(controller: ASAuthorizationController, didCompleteWithAuthorization authorization: ASAuthorization) {
        
        
            guard let appleIDCredential = authorization.credential as? ASAuthorizationAppleIDCredential else {
                  return
              }
        
            switch authorization.credential {
              
                case let credentials as ASAuthorizationAppleIDCredential:
                    
                    
                    break
                default:
                    break
                }
               
               guard let nonce = currentNonce else {
                 fatalError("Invalid state: A login callback was received, but no login request was sent.")
               }
               guard let appleIDToken = appleIDCredential.identityToken else {
                   print("Unable to fetch identity token")
                   return
               }
               
               guard let idTokenString = String(data: appleIDToken, encoding: .utf8) else {
                    print("Unable to serialize token string from data: \(appleIDToken.debugDescription)")
                   return
               }
              
               let credential = OAuthProvider.credential(
                   withProviderID: "apple.com",
                   idToken: idTokenString,
                   rawNonce: nonce
               )
               // Firebaseへのログインを
        Auth.auth().signIn(with: credential) { (authResult, error) in
                  if let error = error {
                      print(error)
                     HUD.flash(.labeledError(title: "予期せぬエラー", subtitle: "再度お試しください。"), delay: 0)
                      return
                  }
                  if let authResult = authResult {

                    HUD.flash(.labeledSuccess(title: "ログイン完了", subtitle: nil), onView: self.view, delay: 0) { _ in
                      
                        self.performSegue(withIdentifier: "next", sender: nil)
                        
               
                      }
                  }
               }

    }
    
    
    func authorizationController(controller: ASAuthorizationController, didCompleteWithError error: Error) {
        print("エラー",error)
    }
    
    func presentationAnchor(for controller: ASAuthorizationController) -> ASPresentationAnchor {
        return view.window!
    }
    
    
}

