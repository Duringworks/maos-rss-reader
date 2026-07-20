//
//  AppTheme.swift
//  Maos
//
//  Created by Ivan on 17/07/26.
//


import SwiftUI

enum AppTheme: String, CaseIterable, Identifiable {
    case system = "System"
    case light = "🌝"
    case dark = "🌚"
    
    var id: String { self.rawValue }
    
    // Konversi enum ke ColorScheme SwiftUI
    var colorScheme: ColorScheme? {
        switch self {
        case .system: return nil
        case .light: return .light
        case .dark: return .dark
        }
    }
}
