import Foundation
import SwiftUI
import Combine

enum AppThemeMode: String, CaseIterable, Identifiable {
    case light = "Light"
    case dark = "Dark"
    
    var id: String { rawValue }
}

enum AppAccentColor: String, CaseIterable, Identifiable {
    case classic = "Classic"
    case blue = "Electric Blue"
    case emerald = "Emerald Green"
    case sunset = "Sunset Amber"
    case purple = "Neon Purple"
    
    var id: String { rawValue }
    
    func primaryColor(isDark: Bool) -> Color {
        switch self {
        case .classic:
            return isDark ? Color.white : Color.black
        case .blue:
            return isDark ? Color(red: 0.35, green: 0.75, blue: 1.0) : Color(red: 0.05, green: 0.45, blue: 0.95)
        case .emerald:
            return isDark ? Color(red: 0.35, green: 0.9, blue: 0.6) : Color(red: 0.08, green: 0.65, blue: 0.35)
        case .sunset:
            return isDark ? Color(red: 1.0, green: 0.6, blue: 0.25) : Color(red: 0.95, green: 0.4, blue: 0.1)
        case .purple:
            return isDark ? Color(red: 0.82, green: 0.55, blue: 1.0) : Color(red: 0.6, green: 0.25, blue: 0.85)
        }
    }
    
    func secondaryColor(isDark: Bool) -> Color {
        return primaryColor(isDark: isDark).opacity(isDark ? 0.65 : 0.6)
    }
    
    func surfaceColor(isDark: Bool) -> Color {
        return isDark ? Color(red: 0.03, green: 0.03, blue: 0.035) : Color.white
    }
    
    func controlBackground(isDark: Bool) -> Color {
        return isDark ? Color(white: 0.15).opacity(0.85) : Color.black.opacity(0.08)
    }
    
    func outlineColor(isDark: Bool) -> Color {
        return isDark ? Color.white.opacity(0.12) : Color.black.opacity(0.12)
    }
}

/// Centralized settings and preference store for Nook/Alcove notch utility
class AppSettings: ObservableObject {
    static let shared = AppSettings()
    
    private let defaults = UserDefaults.standard
    
    // MARK: - General / Behaviour
    @Published var expandOnHover: Bool {
        didSet { defaults.set(expandOnHover, forKey: "expandOnHover") }
    }
    
    @Published var keepOpenWhenClicked: Bool {
        didSet { defaults.set(keepOpenWhenClicked, forKey: "keepOpenWhenClicked") }
    }
    
    @Published var closeWhenClickingOutside: Bool {
        didSet { defaults.set(closeWhenClickingOutside, forKey: "closeWhenClickingOutside") }
    }
    
    // MARK: - Interaction
    @Published var hoverSensitivity: Double {
        didSet { defaults.set(hoverSensitivity, forKey: "hoverSensitivity") }
    }
    
    @Published var animationSpeed: Double {
        didSet { defaults.set(animationSpeed, forKey: "animationSpeed") }
    }
    
    // MARK: - Appearance & Theming
    @Published var themeMode: AppThemeMode {
        didSet { defaults.set(themeMode.rawValue, forKey: "themeMode") }
    }
    
    @Published var accentColor: AppAccentColor {
        didSet { defaults.set(accentColor.rawValue, forKey: "accentColor") }
    }
    
    @Published var contrastOutline: Bool {
        didSet { defaults.set(contrastOutline, forKey: "contrastOutline") }
    }
    
    // MARK: - Tuning / Notch
    @Published var notchXOffset: Double {
        didSet { defaults.set(notchXOffset, forKey: "notchXOffset") }
    }
    
    @Published var notchWidthOffset: Double {
        didSet { defaults.set(notchWidthOffset, forKey: "notchWidthOffset") }
    }
    
    @Published var notchHeightOffset: Double {
        didSet { defaults.set(notchHeightOffset, forKey: "notchHeightOffset") }
    }
    
    // MARK: - Now Playing / Visualizer
    @Published var nowPlayingVisualizer: Bool {
        didSet { defaults.set(nowPlayingVisualizer, forKey: "nowPlayingVisualizer") }
    }
    
    // MARK: - Now Playing / Display
    @Published var showAlbumArtwork: Bool {
        didSet { defaults.set(showAlbumArtwork, forKey: "showAlbumArtwork") }
    }
    
    @Published var showSongTitle: Bool {
        didSet { defaults.set(showSongTitle, forKey: "showSongTitle") }
    }
    
    @Published var showArtistName: Bool {
        didSet { defaults.set(showArtistName, forKey: "showArtistName") }
    }
    
    @Published var showPlaybackProgress: Bool {
        didSet { defaults.set(showPlaybackProgress, forKey: "showPlaybackProgress") }
    }
    
    @Published var showMediaSource: Bool {
        didSet { defaults.set(showMediaSource, forKey: "showMediaSource") }
    }
    
    // MARK: - Now Playing / Controls
    @Published var showPlaybackControls: Bool {
        didSet { defaults.set(showPlaybackControls, forKey: "showPlaybackControls") }
    }
    
    @Published var showPreviousNext: Bool {
        didSet { defaults.set(showPreviousNext, forKey: "showPreviousNext") }
    }
    
    @Published var showPlayPause: Bool {
        didSet { defaults.set(showPlayPause, forKey: "showPlayPause") }
    }
    
    @Published var showHeadphoneBattery: Bool {
        didSet { defaults.set(showHeadphoneBattery, forKey: "showHeadphoneBattery") }
    }
    
    // MARK: - Computed Dynamic Theme Helpers
    var isDarkMode: Bool {
        return themeMode == .dark
    }
    
    var currentPrimaryColor: Color {
        accentColor.primaryColor(isDark: isDarkMode)
    }
    
    var currentSecondaryColor: Color {
        accentColor.secondaryColor(isDark: isDarkMode)
    }
    
    var currentSurfaceColor: Color {
        accentColor.surfaceColor(isDark: isDarkMode)
    }
    
    var currentControlBg: Color {
        accentColor.controlBackground(isDark: isDarkMode)
    }
    
    var currentOutlineColor: Color {
        accentColor.outlineColor(isDark: isDarkMode)
    }
    
    private init() {
        // Register default values
        defaults.register(defaults: [
            "expandOnHover": true,
            "keepOpenWhenClicked": true,
            "closeWhenClickingOutside": true,
            "hoverSensitivity": 2.0,
            "animationSpeed": 1.0,
            "themeMode": AppThemeMode.light.rawValue,
            "accentColor": AppAccentColor.classic.rawValue,
            "contrastOutline": true,
            "notchXOffset": 0.0,
            "notchWidthOffset": 0.0,
            "notchHeightOffset": 0.0,
            "nowPlayingVisualizer": true,
            "showAlbumArtwork": true,
            "showSongTitle": true,
            "showArtistName": true,
            "showPlaybackProgress": true,
            "showMediaSource": true,
            "showPlaybackControls": true,
            "showPreviousNext": true,
            "showPlayPause": true,
            "showHeadphoneBattery": true
        ])
        
        self.expandOnHover = defaults.object(forKey: "expandOnHover") != nil ? defaults.bool(forKey: "expandOnHover") : true
        self.keepOpenWhenClicked = defaults.object(forKey: "keepOpenWhenClicked") != nil ? defaults.bool(forKey: "keepOpenWhenClicked") : true
        self.closeWhenClickingOutside = defaults.object(forKey: "closeWhenClickingOutside") != nil ? defaults.bool(forKey: "closeWhenClickingOutside") : true
        
        self.hoverSensitivity = defaults.object(forKey: "hoverSensitivity") != nil ? defaults.double(forKey: "hoverSensitivity") : 2.0
        self.animationSpeed = defaults.object(forKey: "animationSpeed") != nil ? defaults.double(forKey: "animationSpeed") : 1.0
        
        let rawTheme = defaults.string(forKey: "themeMode") ?? AppThemeMode.light.rawValue
        self.themeMode = AppThemeMode(rawValue: rawTheme) ?? .light
        
        let rawAccent = defaults.string(forKey: "accentColor") ?? AppAccentColor.classic.rawValue
        self.accentColor = AppAccentColor(rawValue: rawAccent) ?? .classic
        
        self.contrastOutline = defaults.bool(forKey: "contrastOutline")
        self.notchXOffset = defaults.double(forKey: "notchXOffset")
        self.notchWidthOffset = defaults.double(forKey: "notchWidthOffset")
        self.notchHeightOffset = defaults.double(forKey: "notchHeightOffset")
        self.nowPlayingVisualizer = defaults.object(forKey: "nowPlayingVisualizer") != nil ? defaults.bool(forKey: "nowPlayingVisualizer") : true
        
        self.showAlbumArtwork = defaults.object(forKey: "showAlbumArtwork") != nil ? defaults.bool(forKey: "showAlbumArtwork") : true
        self.showSongTitle = defaults.object(forKey: "showSongTitle") != nil ? defaults.bool(forKey: "showSongTitle") : true
        self.showArtistName = defaults.object(forKey: "showArtistName") != nil ? defaults.bool(forKey: "showArtistName") : true
        self.showPlaybackProgress = defaults.object(forKey: "showPlaybackProgress") != nil ? defaults.bool(forKey: "showPlaybackProgress") : true
        self.showMediaSource = defaults.object(forKey: "showMediaSource") != nil ? defaults.bool(forKey: "showMediaSource") : true
        
        self.showPlaybackControls = defaults.object(forKey: "showPlaybackControls") != nil ? defaults.bool(forKey: "showPlaybackControls") : true
        self.showPreviousNext = defaults.object(forKey: "showPreviousNext") != nil ? defaults.bool(forKey: "showPreviousNext") : true
        self.showPlayPause = defaults.object(forKey: "showPlayPause") != nil ? defaults.bool(forKey: "showPlayPause") : true
        self.showHeadphoneBattery = defaults.object(forKey: "showHeadphoneBattery") != nil ? defaults.bool(forKey: "showHeadphoneBattery") : true
    }
}
