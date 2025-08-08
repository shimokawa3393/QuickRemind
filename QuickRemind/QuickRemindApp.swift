//
//  QuickRemindApp.swift
//  QuickRemind
//
//  Created by Shouhei Shimokawa on 2025/08/03.
//

import SwiftUI // ビューを作成するために必要
import UserNotifications // 通知を送信するために必要

// MARK: - アプリのエントリーポイント
@main
struct QuickRemindApp: App {
    // MARK: - 初期化
    init() {
            // 通知の許可をリクエスト
            UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
                if granted {
                    print("✅ 通知許可OK")
                } else {
                    print("❌ 通知許可エラー: \(error?.localizedDescription ?? "不明")")
                }
            }
        }
    
    // MARK: - ビュー
    var body: some Scene {
        WindowGroup { // ウィンドウグループを表示する
            ContentView() // コンテンツを表示する
        }
    }
}

