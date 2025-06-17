import UIKit
import Flutter
import Firebase
import FirebaseMessaging

@main
@objc class AppDelegate: FlutterAppDelegate, MessagingDelegate {
  
    let fcmTokenChannelName = "com.example.fcm/token"
    var cachedFcmToken: String?
    let methodChannelName = "com.example.app"
    override func application(
      _ application: UIApplication,
      didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {
      FirebaseApp.configure()
      Messaging.messaging().delegate = self



        // ...

        if let controller = window?.rootViewController as? FlutterViewController {
          let fcmTokenChannel = FlutterMethodChannel(name: fcmTokenChannelName, binaryMessenger: controller.binaryMessenger)
          fcmTokenChannel.setMethodCallHandler { [weak self] (call: FlutterMethodCall, result: @escaping FlutterResult) in
            if call.method == "requestToken" {
              // ЕСЛИ токен уже есть в кеше — сразу вернём его!
              if let cached = self?.cachedFcmToken, !cached.isEmpty {
                print("FCM токен возвращён из кеша: \(cached)")
                result(cached)
              } else {
                // Если нет — получаем у Firebase
                Messaging.messaging().token { token, error in
                  if let error = error {
                    print("Ошибка получения FCM токена: \(error.localizedDescription)")
                    result(FlutterError(code: "FCM_TOKEN_ERROR", message: "Ошибка получения FCM токена", details: error.localizedDescription))
                  } else if let token = token {
                    print("FCM токен получен по запросу: \(token)")
                    self?.cachedFcmToken = token
                    result(token)
                  } else {
                    result(FlutterError(code: "FCM_TOKEN_NULL", message: "FCM токен не получен", details: nil))
                  }
                }
              }
            } else {
              result(FlutterMethodNotImplemented)
            }
          }
        }

      GeneratedPluginRegistrant.register(with: self)
      return super.application(application, didFinishLaunchingWithOptions: launchOptions)
    }

    // Кэшируем токен при любом обновлении, но НЕ отправляем в Flutter!
    func messaging(_ messaging: Messaging, didReceiveRegistrationToken fcmToken: String?) {
      print("FCM токен обновлен: \(String(describing: fcmToken))")
      cachedFcmToken = fcmToken
    }

    override func application(
      _ application: UIApplication,
      didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data
    ) {
      Messaging.messaging().apnsToken = deviceToken
      super.application(application, didRegisterForRemoteNotificationsWithDeviceToken: deviceToken)
    }
  
  // Обработка foreground уведомлений
  override func userNotificationCenter(
    _ center: UNUserNotificationCenter,
    willPresent notification: UNNotification,
    withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
  ) {
    let userInfo = notification.request.content.userInfo
    print("Уведомление получено в foreground: \(userInfo)")
    
    if let controller = window?.rootViewController as? FlutterViewController {
      let notificationChannel = FlutterMethodChannel(name: "com.example.fcm/notification", binaryMessenger: controller.binaryMessenger)
      notificationChannel.invokeMethod("onMessage", arguments: userInfo)
    }
    
    completionHandler([[.alert, .sound, .badge]])
  }
  
  // Обработка нажатия на уведомление
  override func userNotificationCenter(
    _ center: UNUserNotificationCenter,
    didReceive response: UNNotificationResponse,
    withCompletionHandler completionHandler: @escaping () -> Void
  ) {
    let userInfo = response.notification.request.content.userInfo
    print("Пользователь взаимодействовал с уведомлением: \(userInfo)")

    // Извлечение title, body и URI
    let aps = userInfo["aps"] as? [String: Any]
    let alert = aps?["alert"] as? [String: Any]
    let title = alert?["title"] as? String ?? "Без заголовка"
    let body = alert?["body"] as? String ?? "Без текста"
    let uri = userInfo["url"] as? String ?? "Нет URI"

    // Создание структуры данных для передачи во Flutter
    let notificationData: [String: Any] = [
      "title": title,
      "body": body,
      "url": uri,
      "data": userInfo
    ]

    // Передача данных во Flutter через MethodChannel
    if let controller = window?.rootViewController as? FlutterViewController {
      let notificationChannel = FlutterMethodChannel(name: "com.example.fcm/notification", binaryMessenger: controller.binaryMessenger)
      notificationChannel.invokeMethod("onNotificationTap", arguments: notificationData)
    }

    completionHandler()
  }
  
  // Обработка уведомлений в background
  override func application(
    _ application: UIApplication,
    didReceiveRemoteNotification userInfo: [AnyHashable: Any],
    fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void
  ) {
    print("Уведомление получено в background: \(userInfo)")

    // Извлечение необходимых данных: title, body и uri
    let title = (userInfo["title"] as? String) ?? "No title"
    let body = (userInfo["body"] as? String) ?? "No body"
    let uri = (userInfo["url"] as? String) ?? "No URI"

    // Формируем данные для передачи в Flutter
    let notificationData: [String: Any] = [
      "title": title,
      "body": body,
      "url": uri
    ]

    // Проверяем наличие FlutterViewController
    if let controller = window?.rootViewController as? FlutterViewController {
      let methodChannel = FlutterMethodChannel(
        name: methodChannelName,
        binaryMessenger: controller.binaryMessenger
      )
      
      // Передаем данные в Flutter через MethodChannel
      methodChannel.invokeMethod("handleMessageBackground", arguments: notificationData) { _ in
        completionHandler(.newData)
      }
    } else {
      completionHandler(.noData)
    }
  }
}
