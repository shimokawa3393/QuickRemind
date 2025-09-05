//
//  QuickRemindApp.swift
//  QuickRemind
//
//  Created by Shouhei Shimokawa on 2025/08/03.
//

import SwiftUI // ビューを作成するために必要
import UserNotifications // 通知を送信するために必要

// 初期化のハブ（将来：iCloud移行・DBマイグレーション等をここに集約）
final class AppInitializer {
    static let shared = AppInitializer()
    private init() {}
    
    func initialize() {
        // 例：iCloud初期同期、データ移行、設定のデフォルト登録など
        // setupICloudIfNeeded()
        // migrateIfNeeded()
    }
}


// MARK: - 通知の表示オプションを指定する
// 通知の見た目制御（前面表示でもバナー＆サウンド）
final class NotificationDelegate: NSObject, UNUserNotificationCenterDelegate {
    static let shared = NotificationDelegate() // ← 通知の表示オプションを指定する
    
    // アプリが前面にいるときの通知表示
    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                willPresent notification: UNNotification, // ← 通知が表示される前に呼ばれる
                                withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) { // ← 通知の表示オプションを指定する
        completionHandler([.banner, .sound]) // ← 通知の表示オプションを指定する
    }
}


// MARK: - （任意）APNsトークンを拾いたい場合だけ使う。
// Pushを使わないなら丸ごと削除してOK。
final class AppDelegate: NSObject, UIApplicationDelegate {
    @AppStorage("deviceToken") var deviceToken: String = ""
    
    func application(_ application: UIApplication,
                     didRegisterForRemoteNotificationsWithDeviceToken deviceTokenData: Data) {
        let token = deviceTokenData.map { String(format: "%02.2hhx", $0) }.joined()
        deviceToken = token
        print("📮 APNs token: \(token)")
    }
    
    func application(_ application: UIApplication,
                     didFailToRegisterForRemoteNotificationsWithError error: Error) {
        print("❌ APNs登録失敗: \(error.localizedDescription)")
    }
}


// MARK: - アプリのエントリーポイント
@main
struct QuickRemindApp: App {
    // （任意）APNsトークンを拾う場合だけ有効化
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    // MARK: - デバイストークン
    @AppStorage("deviceToken") var deviceToken: String = ""
    
    // MARK: - 初期化
    init() {
        AppInitializer.shared.initialize()
        
        let center = UNUserNotificationCenter.current() 
        center.delegate = NotificationDelegate.shared
        
        // 通知の許可をリクエスト
        center.requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            if granted {
                print("✅ 通知許可OK")
                // Pushを使う場合のみAPNs登録。ローカル通知だけなら削除してOK。
                DispatchQueue.main.async {
                    UIApplication.shared.registerForRemoteNotifications()
                }
            } else {
                print("❌ 通知許可エラー: \(error?.localizedDescription ?? "不明")")
            }
        }
    }
    
    // MARK: - ビュー
    var body: some Scene {
        WindowGroup { // ウィンドウグループを表示する
            ReminderView() // コンテンツを表示する
        }
    }
}


