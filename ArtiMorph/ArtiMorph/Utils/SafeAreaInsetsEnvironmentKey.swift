////
////  SafeAreaInsetsEnvironmentKey.swift
////  ArtiMorph
////
////  Created by admin on 2025/7/6.
////
//
//import Foundation
//import SwiftUI
//
//private struct SafeAreaInsetsKey: EnvironmentKey {
//    static var defaultValue: EdgeInsets {
//        (UIApplication.shared.windows.first?.safeAreaInsets ?? .zero).insets
//    }
//}
//
//extension EnvironmentValues {
//    var safeAreaInsets: EdgeInsets {
//        self[SafeAreaInsetsKey.self]
//    }
//}
//
//extension UIEdgeInsets {
//    var insets: EdgeInsets {
//        EdgeInsets(top: top, leading: left, bottom: bottom, trailing: right)
//    }
//}
