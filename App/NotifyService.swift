import Foundation
import UserNotifications

enum NotifyService {
    static func notify(title: String, body: String) {
        // 异步请求权限（首次会弹系统提示）
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound]) { _, _ in }

        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body

        let req = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: nil)
        UNUserNotificationCenter.current().add(req)
    }
}
