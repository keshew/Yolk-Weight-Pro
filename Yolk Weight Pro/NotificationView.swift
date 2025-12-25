import SwiftUI

struct NotificationView: View {
    
    @Environment(\.verticalSizeClass) var verticalSizeClass
    @Environment(\.horizontalSizeClass) var horizontalSizeClass
    @Environment(\.presentationMode) var presentationMode
    
    private let lastDeniedKey = "lastNotificationDeniedDate"
    
    var isPortrait: Bool {
        verticalSizeClass == .regular && horizontalSizeClass == .compact
    }
    
    var isLandscape: Bool {
        verticalSizeClass == .compact && horizontalSizeClass == .regular
    }
    
    var body: some View {
        VStack {
            if isPortrait {
                ZStack {
                    Color.clear
                        .overlay {
                            Image("notifPor")
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                        }
                        .ignoresSafeArea()
                    
                    
                    VStack(spacing: 30) {
                        Spacer()
                        
                        VStack(spacing: 20) {
                            Text("ALLOW NOTIFICATIONS ABOUT BONUSES AND PROMOS")
                                .font(.custom("Bounded-Black", size: 18))
                                .multilineTextAlignment(.center)
                                .outlineText(color: .red, width: 0.3)
                                .foregroundStyle(.white)
                            
                            Text("Stay tuned with best offers from\nour casino")
                                .font(.custom("Bounded-Black", size: 15))
                                .multilineTextAlignment(.center)
                                .outlineText(color: .red, width: 0.1)
                                .foregroundStyle(Color.white)
                                .opacity(0.5)
                        }
                        .padding(.horizontal, 40)
                        
                        VStack(spacing: 10) {
                            Button(action: {
                                requestNotificationPermission()
                            }) {
                                Image("bonuses")
                                    .resizable()
                                    .aspectRatio(contentMode: .fit)
                                    .frame(width: 350, height: 70)
                            }
                            
                            Button(action:{
                                saveDeniedDate()
                                presentationMode.wrappedValue.dismiss()
                                NotificationCenter.default.post(name: .notificationPermissionResult, object: nil, userInfo: ["granted": true])
                            }) {
                                Image("skip")
                                    .resizable()
                                    .aspectRatio(contentMode: .fit)
                                    .frame(width: 320, height: 40)
                            }
                        }
                    }
                    .padding(.vertical, 20)
                }
            } else {
                ZStack {
                    Image("notifHol")
                        .resizable()
                        .ignoresSafeArea()
                    
                    VStack {
                        Spacer()
                        
                        HStack {
                            
                            VStack(alignment: .leading, spacing: 15) {
                                Text("ALLOW NOTIFICATIONS ABOUT\nBONUSES AND PROMOS")
                                    .font(.custom("Bounded-Black", size: 18))
                                    .outlineText(color: .red, width: 0.3)
                                    .foregroundStyle(.white)
                                    
                                Text("Stay tuned with best offers from our casino")
                                    .font(.custom("Bounded-Black", size: 16))
                                    .outlineText(color: .red, width: 0.1)
                                    .foregroundStyle(Color.white)
                                    .opacity(0.5)
                            }
                            
                            Spacer()
                            
                            VStack(spacing: 10) {
                                Button(action: {
                                    requestNotificationPermission()
                                }) {
                                    Image("bonuses")
                                        .resizable()
                                        .frame(width: 260, height: 50)
                                }
                                
                                Button(action:{
                                    saveDeniedDate()
                                    presentationMode.wrappedValue.dismiss()
                                    NotificationCenter.default.post(name: .notificationPermissionResult, object: nil, userInfo: ["granted": true])
                                }) {
                                    Image("skip")
                                        .resizable()
                                        .frame(width: 240, height: 30)
                                }
                            }
                        }
                        .padding(.bottom, 10)
                        .padding(.horizontal)
                    }
                }
            }
        }
    }
    
    private func requestNotificationPermission() {
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            switch settings.authorizationStatus {
            case .notDetermined:
                UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { granted, error in
                    if granted {
                        DispatchQueue.main.async {
                            NotificationCenter.default.post(name: .notificationPermissionResult, object: nil, userInfo: ["granted": true])
                            UIApplication.shared.registerForRemoteNotifications()
                        }
                        presentationMode.wrappedValue.dismiss()
                    } else {
                        saveDeniedDate()
                        DispatchQueue.main.async {
                            NotificationCenter.default.post(name: .notificationPermissionResult, object: nil, userInfo: ["granted": false])
                        }
                        presentationMode.wrappedValue.dismiss()
                    }
                }
            case .denied:
                presentationMode.wrappedValue.dismiss()
            case .authorized, .provisional, .ephemeral:
                print("razresheni")
            @unknown default:
                break
            }
        }
    }
    
    private func saveDeniedDate() {
        UserDefaults.standard.set(Date(), forKey: lastDeniedKey)
        print("Saved last denied date: \(Date())")
    }
}

#Preview {
    NotificationView()
}
