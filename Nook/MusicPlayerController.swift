import AppKit

class MusicPlayerController: ObservableObject {
    @Published var isPlaying = false
    @Published var songTitle: String = ""
    @Published var artist: String = ""
    @Published var albumArtwork: NSImage?
    @Published var playbackProgress: Double = 0.0
    @Published var duration: Double = 0.0
    @Published var elapsedTime: Double = 0.0
    
    var formattedMediaSource: String {
        switch currentApp {
        case "Music": return "Apple Music"
        case "Spotify", "SpotifyWeb": return "Spotify"
        case "Safari": return "YouTube Music"
        case "Chrome", "Brave": return "YouTube Music"
        default: return currentApp.isEmpty ? "Media Player" : currentApp
        }
    }
    
    private var updateTimer: Timer?
    private var progressTimer: Timer?
    private var currentApp: String = ""
    private var lastUpdateTime: Date?
    private var lastKnownPosition: Double = 0.0
    private var lastArtworkURL: URL?
    
    init() {
        startMonitoring()
    }
    
    private func startMonitoring() {
        // Poll for now playing info updates (track changes, app state)
        updateTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            self?.updateNowPlayingInfo()
        }
        
        // Update progress more frequently for smooth animation (60 FPS)
        progressTimer = Timer.scheduledTimer(withTimeInterval: 0.016, repeats: true) { [weak self] _ in
            self?.updateProgress()
        }
        
        updateNowPlayingInfo()
    }
    
    private func updateProgress() {
        guard isPlaying, duration > 0, let lastUpdate = lastUpdateTime else { return }
        
        // Interpolate elapsed time based on real time passage
        let timeSinceUpdate = Date().timeIntervalSince(lastUpdate)
        let interpolatedTime = lastKnownPosition + timeSinceUpdate
        
        // Don't exceed duration
        if interpolatedTime <= duration {
            DispatchQueue.main.async { [weak self] in
                guard let self = self else { return }
                self.elapsedTime = interpolatedTime
                self.playbackProgress = interpolatedTime / self.duration
            }
        }
    }
    
    private struct MediaCandidate {
        let app: String
        let songTitle: String
        let artist: String
        let isPlaying: Bool
        let elapsed: Double
        let duration: Double
        let artworkURL: String?
        let artworkImage: NSImage?
    }
    
    private func updateNowPlayingInfo() {
        var candidates: [MediaCandidate] = []
        
        // 1. Check native Spotify Desktop
        if let cand = checkSpotifyCandidate() {
            candidates.append(cand)
        }
        
        // 2. Check native Apple Music
        if let cand = checkMusicCandidate() {
            candidates.append(cand)
        }
        
        // 3. Check Spotify Web in Chrome/Brave
        if let cand = checkSpotifyWebCandidate() {
            candidates.append(cand)
        }
        
        // 4. Check YouTube / YouTube Music in Chrome/Brave
        if let cand = checkYouTubeCandidate() {
            candidates.append(cand)
        }
        
        // 5. Check other browser tabs in Safari, Chrome, Brave
        if let cand = checkBrowserTabsCandidate() {
            candidates.append(cand)
        }
        
        // Prioritize whichever candidate is ACTUALLY PLAYING right now!
        if let activePlaying = candidates.first(where: { $0.isPlaying }) {
            applyCandidate(activePlaying)
        } else if let firstPaused = candidates.first(where: { !$0.songTitle.isEmpty }) {
            // If all are paused, display the most recent or first available media in paused state
            applyCandidate(firstPaused)
        } else {
            DispatchQueue.main.async { [weak self] in
                self?.isPlaying = false
            }
        }
    }
    
    private func applyCandidate(_ cand: MediaCandidate) {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            self.currentApp = cand.app
            self.songTitle = cand.songTitle
            self.artist = cand.artist.isEmpty ? "Unknown Artist" : cand.artist
            self.isPlaying = cand.isPlaying
            
            if cand.duration > 0 {
                self.duration = cand.duration
                self.elapsedTime = cand.elapsed
                self.lastKnownPosition = cand.elapsed
                self.lastUpdateTime = Date()
                self.playbackProgress = min(1.0, max(0.0, cand.elapsed / cand.duration))
            } else {
                self.duration = 0
                self.elapsedTime = 0
                self.playbackProgress = 0
            }
            
            if let img = cand.artworkImage {
                self.albumArtwork = img
            } else if let artStr = cand.artworkURL, !artStr.isEmpty, let artUrl = URL(string: artStr) {
                self.downloadArtwork(from: artUrl)
            } else if cand.app != "Music" && cand.artworkURL == nil {
                // Try iTunes search fallback if no direct artwork
                if let videoID = self.extractYouTubeVideoID(from: cand.artist) {
                    if let thumbURL = URL(string: "https://i.ytimg.com/vi/\(videoID)/mqdefault.jpg") {
                        self.downloadArtwork(from: thumbURL)
                    }
                }
            }
        }
    }
    
    // MARK: - Candidate Checkers
    private func checkSpotifyCandidate() -> MediaCandidate? {
        let script = """
        tell application "System Events"
            set spotifyRunning to (name of processes) contains "Spotify"
        end tell
        
        if spotifyRunning then
            tell application "Spotify"
                if player state is playing or player state is paused then
                    set trackName to name of current track
                    set artistName to artist of current track
                    set isPlaying to (player state is playing)
                    set trackDuration to duration of current track
                    set trackPosition to player position
                    return trackName & "|||" & artistName & "|||" & (isPlaying as text) & "|||" & trackDuration & "|||" & trackPosition & "|||SPOTIFY"
                end if
            end tell
        end if
        return "NOT_PLAYING"
        """
        
        guard let appleScript = NSAppleScript(source: script) else { return nil }
        var error: NSDictionary?
        let result = appleScript.executeAndReturnError(&error)
        guard error == nil, let str = result.stringValue, str != "NOT_PLAYING" else { return nil }
        
        let parts = str.components(separatedBy: "|||")
        guard parts.count >= 5, !parts[0].isEmpty else { return nil }
        
        let dur = (Double(parts[3]) ?? 0) / 1000.0
        let pos = Double(parts[4]) ?? 0
        let isPlaying = parts[2] == "true"
        
        return MediaCandidate(
            app: "Spotify",
            songTitle: parts[0],
            artist: parts[1],
            isPlaying: isPlaying,
            elapsed: pos,
            duration: dur,
            artworkURL: nil,
            artworkImage: nil
        )
    }
    
    private func checkMusicCandidate() -> MediaCandidate? {
        let script = """
        tell application "System Events"
            set musicRunning to (name of processes) contains "Music"
        end tell
        
        if musicRunning then
            tell application "Music"
                if player state is playing or player state is paused then
                    set trackName to name of current track
                    set artistName to artist of current track
                    set isPlaying to (player state is playing)
                    set trackDuration to duration of current track
                    set trackPosition to player position
                    return trackName & "|||" & artistName & "|||" & (isPlaying as text) & "|||" & trackDuration & "|||" & trackPosition & "|||MUSIC"
                end if
            end tell
        end if
        return "NOT_PLAYING"
        """
        
        guard let appleScript = NSAppleScript(source: script) else { return nil }
        var error: NSDictionary?
        let result = appleScript.executeAndReturnError(&error)
        guard error == nil, let str = result.stringValue, str != "NOT_PLAYING" else { return nil }
        
        let parts = str.components(separatedBy: "|||")
        guard parts.count >= 5, !parts[0].isEmpty else { return nil }
        
        let dur = Double(parts[3]) ?? 0
        let pos = Double(parts[4]) ?? 0
        let isPlaying = parts[2] == "true"
        
        return MediaCandidate(
            app: "Music",
            songTitle: parts[0],
            artist: parts[1],
            isPlaying: isPlaying,
            elapsed: pos,
            duration: dur,
            artworkURL: nil,
            artworkImage: getArtworkImageFromMusic()
        )
    }
    
    private func checkSpotifyWebCandidate() -> MediaCandidate? {
        let jsScript = """
        (function() {
            const text = (element) => (element && element.textContent || '').trim();
            const first = (selectors, root = document) => {
                for (const selector of selectors) {
                    const match = root.querySelector(selector);
                    if (match) return match;
                }
                return null;
            };
            const all = (selectors, root = document) =>
                selectors.flatMap((selector) => Array.from(root.querySelectorAll(selector)));

            function timeToSeconds(timeStr) {
                if (!timeStr) return 0;
                const parts = timeStr.split(':').map(Number);
                if (parts.length === 2) return parts[0] * 60 + parts[1];
                if (parts.length === 3) return parts[0] * 3600 + parts[1] * 60 + parts[2];
                return 0;
            }

            const widget = first([
                '[data-testid="now-playing-widget"]',
                '[data-testid="now-playing-bar"]',
                'footer'
            ]) || document;

            const playButton = first([
                '[data-testid="control-button-playpause"]',
                'button[aria-label*="Pause"]',
                'button[aria-label*="Play"]',
                'button[aria-label*="Resume"]'
            ]);
            const playLabel = (playButton && playButton.getAttribute('aria-label') || '').toLowerCase();
            const isPlaying = playLabel.includes('pause');

            const titleElement = first([
                '[data-testid="context-item-link"]',
                'a[href*="/track/"]',
                '[data-testid="now-playing-widget"] a[href*="/track/"]'
            ], widget);
            const songTitle = text(titleElement);
            if (!songTitle) return 'NOT_PLAYING';

            const artistElements = all([
                '[data-testid="context-item-info-subtitle"] a',
                'a[href*="/artist/"]'
            ], widget).filter((element) => !element.href || !element.href.includes('/track/'));
            const artistName = [...new Set(artistElements.map(text).filter(Boolean))].join(', ');

            const elapsedText = text(first(['[data-testid="playback-position"]']));
            const durationText = text(first(['[data-testid="playback-duration"]']));
            let elapsed = timeToSeconds(elapsedText);
            let duration = timeToSeconds(durationText);

            const slider = first([
                '[data-testid="playback-progressbar"] [role="slider"]',
                '[role="slider"][aria-valuenow][aria-valuemax]'
            ]);
            if ((!elapsed || !duration) && slider) {
                const valueNow = Number(slider.getAttribute('aria-valuenow'));
                const valueMax = Number(slider.getAttribute('aria-valuemax'));
                if (Number.isFinite(valueNow) && valueNow > 0) elapsed = valueNow;
                if (Number.isFinite(valueMax) && valueMax > 0) duration = valueMax;
            }

            const artworkImg = first([
                '[data-testid="now-playing-widget"] img[src]',
                '[data-testid="cover-art-image"] img[src]',
                'img[src*="i.scdn.co/image"]'
            ], widget) || first(['img[src*="i.scdn.co/image"]']);
            const artworkURL = artworkImg ? artworkImg.src : '';
            
            return JSON.stringify({
                isPlaying: isPlaying,
                songTitle: songTitle,
                artist: artistName,
                elapsed: elapsed,
                duration: duration,
                artworkURL: artworkURL
            });
        })();
        """

        guard let jsonString = executeJavaScriptOnSpotifyTab(jsScript),
              jsonString != "ERROR",
              jsonString != "NOT_PLAYING",
              let jsonData = jsonString.data(using: .utf8),
              let json = try? JSONSerialization.jsonObject(with: jsonData) as? [String: Any],
              let title = json["songTitle"] as? String, !title.isEmpty else {
            return nil
        }
        
        return MediaCandidate(
            app: "SpotifyWeb",
            songTitle: title,
            artist: (json["artist"] as? String) ?? "Spotify",
            isPlaying: (json["isPlaying"] as? Bool) ?? false,
            elapsed: (json["elapsed"] as? Double) ?? 0,
            duration: (json["duration"] as? Double) ?? 0,
            artworkURL: json["artworkURL"] as? String,
            artworkImage: nil
        )
    }
    
    private func checkYouTubeCandidate() -> MediaCandidate? {
        let jsScript = """
        (function() {
            var v = document.querySelector('video');
            if (!v) return 'NOT_PLAYING';
            
            var isPlaying = !v.paused && !v.ended && v.readyState > 2 && v.currentTime > 0;
            
            var titleElem = document.querySelector('.ytmusic-player-bar .title, yt-formatted-string.title, h1.ytd-watch-metadata, #title h1, h1.title');
            var artistElem = document.querySelector('.ytmusic-player-bar .byline, ytd-channel-name #text, #channel-name #text, #owner-name a, #text.ytd-channel-name');
            
            var title = titleElem ? titleElem.textContent.trim() : document.title.replace(' - YouTube Music', '').replace(' - YouTube', '').trim();
            var artist = artistElem ? artistElem.textContent.trim() : 'YouTube Music';
            
            var artworkImg = document.querySelector('.ytmusic-player-bar img[src], ytd-watch-flexy img[src*="ytimg.com"], img[src*="ggpht.com"], img[src*="googleusercontent.com"]');
            var artworkURL = artworkImg ? artworkImg.src : '';
            
            return JSON.stringify({
                isPlaying: isPlaying,
                songTitle: title,
                artist: artist,
                elapsed: v.currentTime || 0,
                duration: isFinite(v.duration) ? v.duration : 0,
                artworkURL: artworkURL
            });
        })();
        """

        guard let jsonString = executeJavaScriptOnYouTubeTab(jsScript),
              jsonString != "ERROR",
              jsonString != "NOT_PLAYING",
              let jsonData = jsonString.data(using: .utf8),
              let json = try? JSONSerialization.jsonObject(with: jsonData) as? [String: Any],
              let title = json["songTitle"] as? String, !title.isEmpty else {
            return nil
        }
        
        return MediaCandidate(
            app: "YouTubeMusic",
            songTitle: title,
            artist: (json["artist"] as? String) ?? "YouTube",
            isPlaying: (json["isPlaying"] as? Bool) ?? false,
            elapsed: (json["elapsed"] as? Double) ?? 0,
            duration: (json["duration"] as? Double) ?? 0,
            artworkURL: json["artworkURL"] as? String,
            artworkImage: nil
        )
    }
    
    private func checkBrowserTabsCandidate() -> MediaCandidate? {
        let script = """
        tell application "System Events"
            set chromeRunning to (name of processes) contains "Google Chrome"
            set braveRunning to (name of processes) contains "Brave Browser"
            set safariRunning to (name of processes) contains "Safari"
        end tell
        
        if chromeRunning then
            tell application "Google Chrome"
                try
                    repeat with w in windows
                        repeat with t in tabs of w
                            set tabURL to URL of t
                            if tabURL contains "music.youtube.com" or tabURL contains "youtube.com" or tabURL contains "soundcloud.com" or tabURL contains "music.apple.com" or tabURL contains "spotify.com" then
                                set tabTitle to title of t
                                set isAud to false
                                try
                                    set isAud to audible of t
                                end try
                                set audText to "false"
                                if isAud then set audText to "true"
                                if tabTitle is not "" and tabTitle is not "YouTube Music" and tabTitle is not "YouTube" and tabTitle is not "Spotify" then
                                    return tabTitle & "|||BROWSER|||Chrome|||" & tabURL & "|||" & audText
                                end if
                            end if
                        end repeat
                    end repeat
                end try
            end tell
        end if
        
        if braveRunning then
            tell application "Brave Browser"
                try
                    repeat with w in windows
                        repeat with t in tabs of w
                            set tabURL to URL of t
                            if tabURL contains "music.youtube.com" or tabURL contains "youtube.com" or tabURL contains "spotify.com" or tabURL contains "soundcloud.com" or tabURL contains "music.apple.com" then
                                set tabTitle to title of t
                                set isAud to false
                                try
                                    set isAud to audible of t
                                end try
                                set audText to "false"
                                if isAud then set audText to "true"
                                if tabTitle is not "" and tabTitle is not "YouTube Music" and tabTitle is not "YouTube" and tabTitle is not "Spotify" then
                                    return tabTitle & "|||BROWSER|||Brave|||" & tabURL & "|||" & audText
                                end if
                            end if
                        end repeat
                    end repeat
                end try
            end tell
        end if
        
        if safariRunning then
            tell application "Safari"
                try
                    repeat with w in windows
                        repeat with t in tabs of w
                            set tabURL to URL of t
                            if tabURL contains "music.youtube.com" or tabURL contains "youtube.com" or tabURL contains "spotify.com" or tabURL contains "soundcloud.com" or tabURL contains "music.apple.com" then
                                set tabTitle to name of t
                                if tabTitle is not "" and tabTitle is not "YouTube Music" and tabTitle is not "YouTube" and tabTitle is not "Spotify" then
                                    return tabTitle & "|||BROWSER|||Safari|||" & tabURL & "|||true"
                                end if
                            end if
                        end repeat
                    end repeat
                end try
            end tell
        end if
        
        return "NOT_PLAYING"
        """
        
        guard let appleScript = NSAppleScript(source: script) else { return nil }
        var error: NSDictionary?
        let result = appleScript.executeAndReturnError(&error)
        guard error == nil, let str = result.stringValue, str != "NOT_PLAYING" else { return nil }
        
        let parts = str.components(separatedBy: "|||")
        guard parts.count >= 2 else { return nil }
        
        var fullTitle = parts[0]
        let suffixes = [" - YouTube", " - YouTube Music", " - Spotify", " - SoundCloud", " - Apple Music", " - Music", " on Vimeo"]
        for suffix in suffixes {
            if fullTitle.hasSuffix(suffix) {
                fullTitle = String(fullTitle.dropLast(suffix.count)).trimmingCharacters(in: .whitespaces)
                break
            }
        }
        
        var title = fullTitle
        var artist = "Web Player"
        if fullTitle.contains(" - ") {
            let split = fullTitle.components(separatedBy: " - ")
            if split.count >= 2 {
                artist = split[0].trimmingCharacters(in: .whitespaces)
                title = split[1].trimmingCharacters(in: .whitespaces)
            }
        }
        
        let isAudible = parts.count >= 5 ? (parts[4].lowercased() == "true") : false
        let appName = parts.count >= 3 ? parts[2] : "Web Player"
        let tabURL = parts.count >= 4 ? parts[3] : ""
        
        var artURL: String? = nil
        if let videoID = extractYouTubeVideoID(from: tabURL) {
            artURL = "https://i.ytimg.com/vi/\(videoID)/mqdefault.jpg"
        }
        
        return MediaCandidate(
            app: appName,
            songTitle: title,
            artist: artist,
            isPlaying: isAudible,
            elapsed: 0,
            duration: 0,
            artworkURL: artURL,
            artworkImage: nil
        )
    }
    
    private func getArtworkImageFromMusic() -> NSImage? {
        let script = """
        tell application "Music"
            if player state is not stopped then
                try
                    set currentArtwork to data of artwork 1 of current track
                    return currentArtwork
                end try
            end if
        end tell
        """
        if let appleScript = NSAppleScript(source: script) {
            var error: NSDictionary?
            let result = appleScript.executeAndReturnError(&error)
            if error == nil, let descriptor = result.coerce(toDescriptorType: typeType) ?? Optional(result) {
                let data = descriptor.data
                if !data.isEmpty, let img = NSImage(data: data) {
                    return img
                }
            }
        }
        return nil
    }
    
    private func trySpotifyWeb() -> Bool {
        let jsScript = """
        (function() {
            const text = (element) => (element && element.textContent || '').trim();
            const first = (selectors, root = document) => {
                for (const selector of selectors) {
                    const match = root.querySelector(selector);
                    if (match) return match;
                }
                return null;
            };
            const all = (selectors, root = document) =>
                selectors.flatMap((selector) => Array.from(root.querySelectorAll(selector)));

            function timeToSeconds(timeStr) {
                if (!timeStr) return 0;
                const parts = timeStr.split(':').map(Number);
                if (parts.length === 2) return parts[0] * 60 + parts[1];
                if (parts.length === 3) return parts[0] * 3600 + parts[1] * 60 + parts[2];
                return 0;
            }

            const widget = first([
                '[data-testid="now-playing-widget"]',
                '[data-testid="now-playing-bar"]',
                'footer'
            ]) || document;

            const playButton = first([
                '[data-testid="control-button-playpause"]',
                'button[aria-label*="Pause"]',
                'button[aria-label*="Play"]',
                'button[aria-label*="Resume"]'
            ]);
            const playLabel = (playButton && playButton.getAttribute('aria-label') || '').toLowerCase();
            const isPlaying = playLabel.includes('pause');

            const titleElement = first([
                '[data-testid="context-item-link"]',
                'a[href*="/track/"]',
                '[data-testid="now-playing-widget"] a[href*="/track/"]'
            ], widget);
            const songTitle = text(titleElement);

            const artistElements = all([
                '[data-testid="context-item-info-subtitle"] a',
                'a[href*="/artist/"]'
            ], widget).filter((element) => !element.href || !element.href.includes('/track/'));
            const artistName = [...new Set(artistElements.map(text).filter(Boolean))].join(', ');

            const elapsedText = text(first(['[data-testid="playback-position"]']));
            const durationText = text(first(['[data-testid="playback-duration"]']));
            let elapsed = timeToSeconds(elapsedText);
            let duration = timeToSeconds(durationText);

            const slider = first([
                '[data-testid="playback-progressbar"] [role="slider"]',
                '[role="slider"][aria-valuenow][aria-valuemax]'
            ]);
            if ((!elapsed || !duration) && slider) {
                const valueNow = Number(slider.getAttribute('aria-valuenow'));
                const valueMax = Number(slider.getAttribute('aria-valuemax'));
                if (Number.isFinite(valueNow) && valueNow > 0) elapsed = valueNow;
                if (Number.isFinite(valueMax) && valueMax > 0) duration = valueMax;
            }

            const artworkImg = first([
                '[data-testid="now-playing-widget"] img[src]',
                '[data-testid="cover-art-image"] img[src]',
                'img[src*="i.scdn.co/image"]'
            ], widget) || first(['img[src*="i.scdn.co/image"]']);
            const artworkURL = artworkImg ? artworkImg.src : '';
            
            return JSON.stringify({
                isPlaying: isPlaying,
                songTitle: songTitle,
                artist: artistName,
                elapsed: elapsed,
                duration: duration,
                artworkURL: artworkURL
            });
        })();
        """

        guard let jsonString = executeJavaScriptOnSpotifyTab(jsScript),
              jsonString != "ERROR",
              jsonString != "NOT_PLAYING" else {
            return false
        }
        
        // Parse JSON result
        guard let jsonData = jsonString.data(using: .utf8),
              let json = try? JSONSerialization.jsonObject(with: jsonData) as? [String: Any] else {
            return false
        }
        
        DispatchQueue.main.async { [weak self] in
            self?.currentApp = "SpotifyWeb"
            self?.parseSpotifyWebInfo(json)
        }
        
        return true
    }
    
    private func tryYouTubeWebChrome() -> Bool {
        let jsScript = """
        (function() {
            var v = document.querySelector('video');
            if (!v) return 'NOT_PLAYING';
            
            var titleElem = document.querySelector('.ytmusic-player-bar .title, yt-formatted-string.title, h1.ytd-watch-metadata, #title h1');
            var artistElem = document.querySelector('.ytmusic-player-bar .byline, ytd-channel-name #text, #channel-name #text, #owner-name a');
            
            var title = titleElem ? titleElem.textContent.trim() : document.title.replace(' - YouTube Music', '').replace(' - YouTube', '').trim();
            var artist = artistElem ? artistElem.textContent.trim() : 'YouTube Music';
            
            var artworkImg = document.querySelector('.ytmusic-player-bar img[src], ytd-watch-flexy img[src*="ytimg.com"], img[src*="ggpht.com"], img[src*="googleusercontent.com"]');
            var artworkURL = artworkImg ? artworkImg.src : '';
            
            return JSON.stringify({
                isPlaying: !v.paused && !v.ended,
                songTitle: title,
                artist: artist,
                elapsed: v.currentTime,
                duration: isFinite(v.duration) ? v.duration : 0,
                artworkURL: artworkURL
            });
        })();
        """

        guard let jsonString = executeJavaScriptOnYouTubeTab(jsScript),
              jsonString != "ERROR",
              jsonString != "NOT_PLAYING" else {
            return false
        }
        
        guard let jsonData = jsonString.data(using: .utf8),
              let json = try? JSONSerialization.jsonObject(with: jsonData) as? [String: Any] else {
            return false
        }
        
        DispatchQueue.main.async { [weak self] in
            self?.currentApp = "YouTubeMusic"
            self?.parseSpotifyWebInfo(json)
        }
        
        return true
    }

    private func executeJavaScriptOnYouTubeTab(_ javascript: String) -> String? {
        let escapedJS = javascript
            .replacingOccurrences(of: "\\", with: "\\\\")
            .replacingOccurrences(of: "\"", with: "\\\"")
            .replacingOccurrences(of: "\n", with: " ")

        let script = """
        tell application "System Events"
            set chromeRunning to (name of processes) contains "Google Chrome"
        end tell

        if chromeRunning then
            tell application "/Applications/Google Chrome.app"
                try
                    repeat with windowIndex from 1 to count of windows
                        repeat with tabIndex from 1 to count of tabs of window windowIndex
                            set tabURL to URL of tab tabIndex of window windowIndex
                            if tabURL contains "music.youtube.com" or tabURL contains "youtube.com" then
                                set res to execute tab tabIndex of window windowIndex javascript "\(escapedJS)"
                                if res is not "NOT_PLAYING" and res is not "ERROR" and res is not missing value and res is not "" then
                                    return res
                                end if
                            end if
                        end repeat
                    end repeat
                end try
            end tell
        end if

        return "NOT_PLAYING"
        """

        guard let appleScript = NSAppleScript(source: script) else { return nil }
        var error: NSDictionary?
        let result = appleScript.executeAndReturnError(&error)
        if error != nil { return nil }
        return result.stringValue
    }
    
    private func tryBasicChrome() -> Bool {
        let script = """
        tell application "System Events"
            set chromeRunning to (name of processes) contains "Google Chrome"
        end tell
        
        if chromeRunning then
            tell application "/Applications/Google Chrome.app"
                try
                    repeat with w in windows
                        repeat with t in tabs of w
                            set tabURL to URL of t
                            if tabURL contains "music.youtube.com" or tabURL contains "youtube.com" or tabURL contains "soundcloud.com" or tabURL contains "music.apple.com" or tabURL contains "spotify.com" then
                                set tabTitle to title of t
                                set isAudible to audible of t
                                if tabTitle is not "" and tabTitle is not "YouTube Music" and tabTitle is not "YouTube" and tabTitle is not "Spotify" then
                                    return tabTitle & "|||BROWSER|||CHROME|||" & tabURL & "|||" & (isAudible as text)
                                end if
                            end if
                        end repeat
                    end repeat
                end try
            end tell
        end if
        return "NOT_PLAYING"
        """
        
        if let appleScript = NSAppleScript(source: script) {
            var error: NSDictionary?
            let result = appleScript.executeAndReturnError(&error)
            
            if error == nil, let resultString = result.stringValue, resultString != "NOT_PLAYING" {
                DispatchQueue.main.async { [weak self] in
                    self?.currentApp = "Chrome"
                    self?.parseBrowserInfo(resultString)
                }
                return true
            }
        }
        return false
    }
    
    private func tryBrave() -> Bool {
        let script = """
        tell application "System Events"
            set braveRunning to (name of processes) contains "Brave Browser"
        end tell
        
        if braveRunning then
            tell application "Brave Browser"
                try
                    repeat with w in windows
                        repeat with t in tabs of w
                            set tabURL to URL of t
                            if tabURL contains "music.youtube.com" or tabURL contains "youtube.com" or tabURL contains "spotify.com" or tabURL contains "soundcloud.com" or tabURL contains "music.apple.com" then
                                set tabTitle to title of t
                                set isAudible to audible of t
                                if tabTitle is not "" and tabTitle is not "YouTube Music" and tabTitle is not "YouTube" and tabTitle is not "Spotify" then
                                    return tabTitle & "|||BROWSER|||BRAVE|||" & tabURL & "|||" & (isAudible as text)
                                end if
                            end if
                        end repeat
                    end repeat
                end try
            end tell
        end if
        return "NOT_PLAYING"
        """
        
        if let appleScript = NSAppleScript(source: script) {
            var error: NSDictionary?
            let result = appleScript.executeAndReturnError(&error)
            
            if error == nil, let resultString = result.stringValue, resultString != "NOT_PLAYING" {
                DispatchQueue.main.async { [weak self] in
                    self?.currentApp = "Brave"
                    self?.parseBrowserInfo(resultString)
                }
                return true
            }
        }
        return false
    }
    
    // Fallback: Try to detect any tab with media-like title in Chrome
    private func tryAnyChrome() -> Bool {
        let script = """
        tell application "System Events"
            set chromeRunning to (name of processes) contains "Google Chrome"
        end tell
        
        if chromeRunning then
            tell application "/Applications/Google Chrome.app"
                try
                    set currentTab to active tab of front window
                    set tabURL to URL of currentTab
                    set tabTitle to title of currentTab
                    
                    -- Check if title contains common music patterns (contains dash or "by")
                    if (tabTitle contains " - " or tabTitle contains " by " or tabTitle contains " | ") and tabTitle is not "" then
                        -- Likely a media title
                        return tabTitle & "|||BROWSER|||CHROME|||" & tabURL
                    end if
                end try
            end tell
        end if
        return "NOT_PLAYING"
        """
        
        if let appleScript = NSAppleScript(source: script) {
            var error: NSDictionary?
            let result = appleScript.executeAndReturnError(&error)
            
            if let err = error {
                print("❌ Chrome fallback error: \(err)")
            }
            
            if error == nil, let resultString = result.stringValue {
                print("🔍 Chrome fallback result: \(resultString)")
                if resultString != "NOT_PLAYING" {
                    DispatchQueue.main.async { [weak self] in
                        self?.currentApp = "Chrome"
                        self?.parseBrowserInfo(resultString)
                    }
                    return true
                }
            }
        }
        return false
    }
    
    private func parseBrowserInfo(_ info: String) {
        let components = info.components(separatedBy: "|||")
        guard components.count >= 2 else {
            clearNowPlayingInfo()
            return
        }
        
        var fullTitle = components[0]
        
        // Remove common suffixes first
        let suffixes = [
            " - YouTube",
            " - YouTube Music", 
            " - Spotify",
            " - SoundCloud",
            " - Apple Music",
            " - Music",
            " on Vimeo"
        ]
        for suffix in suffixes {
            if fullTitle.hasSuffix(suffix) {
                fullTitle = String(fullTitle.dropLast(suffix.count)).trimmingCharacters(in: .whitespaces)
                break
            }
        }
        
        // Remove parenthetical content like (Official Video), (Audio), etc.
        if let range = fullTitle.range(of: #"\s*\([^)]*\)"#, options: .regularExpression) {
            fullTitle.removeSubrange(range)
            fullTitle = fullTitle.trimmingCharacters(in: .whitespaces)
        }
        
        var songTitle = fullTitle
        var artist = "Web Player"
        
        // Try to split by common separators
        // Format: "Artist - Song Title"
        if fullTitle.contains(" - ") {
            let parts = fullTitle.components(separatedBy: " - ")
            if parts.count >= 2 {
                artist = parts[0].trimmingCharacters(in: .whitespaces)
                songTitle = parts[1].trimmingCharacters(in: .whitespaces)
            }
        }
        // Format: "Song Title by Artist"
        else if fullTitle.contains(" by ") {
            let parts = fullTitle.components(separatedBy: " by ")
            if parts.count >= 2 {
                songTitle = parts[0].trimmingCharacters(in: .whitespaces)
                artist = parts[1].trimmingCharacters(in: .whitespaces)
            }
        }
        // Format: "Song Title | Artist"
        else if fullTitle.contains(" | ") {
            let parts = fullTitle.components(separatedBy: " | ")
            if parts.count >= 2 {
                songTitle = parts[0].trimmingCharacters(in: .whitespaces)
                artist = parts[1].trimmingCharacters(in: .whitespaces)
            }
        }
        // Format: "Artist: Song Title"
        else if fullTitle.contains(": ") {
            let parts = fullTitle.components(separatedBy: ": ")
            if parts.count >= 2 {
                artist = parts[0].trimmingCharacters(in: .whitespaces)
                songTitle = parts[1].trimmingCharacters(in: .whitespaces)
            }
        }
        
        let newTitle = songTitle.isEmpty ? "Unknown" : songTitle
        let newArtist = artist.isEmpty ? "Web Player" : artist
        
        self.songTitle = newTitle
        self.artist = newArtist
        
        if components.count >= 5 {
            let isAudible = components[4].trimmingCharacters(in: .whitespacesAndNewlines).lowercased() == "true"
            self.isPlaying = isAudible
        } else {
            self.isPlaying = false
        }
        
        // For browsers, we can't get accurate progress
        self.duration = 0.0
        self.elapsedTime = 0.0
        self.playbackProgress = 0.0
        
        // Fetch artwork for browser music
        fetchArtworkForBrowser(components: components, songTitle: self.songTitle, artist: self.artist)
    }
    
    private func fetchArtworkForBrowser(components: [String], songTitle: String, artist: String) {
        // 1. Check if tab URL has a YouTube video ID
        let tabURL = components.count >= 4 ? components[3] : ""
        if let videoID = extractYouTubeVideoID(from: tabURL) {
            if let thumbURL = URL(string: "https://i.ytimg.com/vi/\(videoID)/mqdefault.jpg") {
                downloadArtwork(from: thumbURL)
                return
            }
        }
        
        // 2. Fallback to iTunes Search API for album artwork
        searchiTunesArtwork(title: songTitle, artist: artist)
    }
    
    private func extractYouTubeVideoID(from urlString: String) -> String? {
        let pattern = #"(?:v=|\/embed\/|\/shorts\/|youtu\.be\/|\/watch\?v=)([a-zA-Z0-9_-]{11})"#
        guard let regex = try? NSRegularExpression(pattern: pattern) else { return nil }
        let nsString = urlString as NSString
        let results = regex.matches(in: urlString, range: NSRange(location: 0, length: nsString.length))
        if let match = results.first, match.numberOfRanges >= 2 {
            return nsString.substring(with: match.range(at: 1))
        }
        return nil
    }
    
    private func searchiTunesArtwork(title: String, artist: String) {
        let cleanArtist = (artist == "Web Player" || artist == "Unknown") ? "" : artist
        let query = "\(title) \(cleanArtist)".trimmingCharacters(in: .whitespaces)
        guard !query.isEmpty,
              let encodedQuery = query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
              let searchURL = URL(string: "https://itunes.apple.com/search?term=\(encodedQuery)&entity=song&limit=1") else {
            return
        }
        
        URLSession.shared.dataTask(with: searchURL) { [weak self] data, response, error in
            guard let data = data,
                  let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                  let results = json["results"] as? [[String: Any]],
                  let firstResult = results.first,
                  let artworkUrlString = (firstResult["artworkUrl100"] as? String) ?? (firstResult["artworkUrl60"] as? String),
                  let artworkURL = URL(string: artworkUrlString.replacingOccurrences(of: "100x100bb", with: "300x300bb")) else {
                return
            }
            
            self?.downloadArtwork(from: artworkURL)
        }.resume()
    }
    
    private func parseSpotifyWebInfo(_ json: [String: Any]) {
        guard let songTitle = json["songTitle"] as? String,
              let artist = json["artist"] as? String,
              !songTitle.isEmpty else {
            clearNowPlayingInfo()
            return
        }
        
        self.songTitle = songTitle
        self.artist = artist.isEmpty ? "Unknown Artist" : artist
        self.isPlaying = (json["isPlaying"] as? Bool) ?? false
        
        if let elapsed = json["elapsed"] as? Double {
            self.elapsedTime = elapsed
            self.lastKnownPosition = elapsed
            self.lastUpdateTime = Date()
        }
        
        if let duration = json["duration"] as? Double {
            self.duration = duration
            if duration > 0 {
                self.playbackProgress = self.elapsedTime / duration
            }
        }
        
        // Download artwork from URL
        if let artworkURL = json["artworkURL"] as? String,
           !artworkURL.isEmpty,
           let url = URL(string: artworkURL) {
            downloadArtwork(from: url)
        } else {
            self.albumArtwork = nil
            self.lastArtworkURL = nil
        }
    }
    
    private func downloadArtwork(from url: URL) {
        if lastArtworkURL == url, albumArtwork != nil { return }
        lastArtworkURL = url
        
        URLSession.shared.dataTask(with: url) { [weak self] data, response, error in
            guard let self = self else { return }
            if let data = data, let image = NSImage(data: data) {
                DispatchQueue.main.async {
                    guard self.lastArtworkURL == url else { return }
                    self.albumArtwork = image
                }
            }
        }.resume()
    }
    
    private func trySpotify() -> Bool {
        let script = """
        tell application "System Events"
            set spotifyRunning to (name of processes) contains "Spotify"
        end tell
        
        if spotifyRunning then
            tell application "Spotify"
                if player state is playing or player state is paused then
                    set trackName to name of current track
                    set artistName to artist of current track
                    set isPlaying to (player state is playing)
                    set trackDuration to duration of current track
                    set trackPosition to player position
                    return trackName & "|||" & artistName & "|||" & (isPlaying as text) & "|||" & trackDuration & "|||" & trackPosition & "|||SPOTIFY"
                end if
            end tell
        end if
        return "NOT_PLAYING"
        """
        
        if let appleScript = NSAppleScript(source: script) {
            var error: NSDictionary?
            let result = appleScript.executeAndReturnError(&error)
            
            if error == nil, let resultString = result.stringValue, resultString != "NOT_PLAYING" {
                DispatchQueue.main.async { [weak self] in
                    self?.currentApp = "Spotify"
                    self?.parseNowPlayingInfo(resultString)
                }
                return true
            }
        }
        return false
    }
    
    private func tryMusic() -> Bool {
        let script = """
        tell application "System Events"
            set musicRunning to (name of processes) contains "Music"
        end tell
        
        if musicRunning then
            tell application "Music"
                if player state is playing or player state is paused then
                    set trackName to name of current track
                    set artistName to artist of current track
                    set isPlaying to (player state is playing)
                    set trackDuration to duration of current track
                    set trackPosition to player position
                    return trackName & "|||" & artistName & "|||" & (isPlaying as text) & "|||" & trackDuration & "|||" & trackPosition & "|||MUSIC"
                end if
            end tell
        end if
        return "NOT_PLAYING"
        """
        
        if let appleScript = NSAppleScript(source: script) {
            var error: NSDictionary?
            let result = appleScript.executeAndReturnError(&error)
            
            if error == nil, let resultString = result.stringValue, resultString != "NOT_PLAYING" {
                DispatchQueue.main.async { [weak self] in
                    self?.currentApp = "Music"
                    self?.parseNowPlayingInfo(resultString)
                }
                return true
            }
        }
        return false
    }
    
    private func parseNowPlayingInfo(_ info: String) {
        if info == "NOT_PLAYING" {
            clearNowPlayingInfo()
            return
        }
        
        let components = info.components(separatedBy: "|||")
        guard components.count >= 5 else {
            clearNowPlayingInfo()
            return
        }
        
        self.songTitle = components[0]
        self.artist = components[1]
        self.isPlaying = components[2] == "true"
        
        if let dur = Double(components[3]) {
            // Spotify returns milliseconds, Music returns seconds
            if components.count > 5 && components[5] == "SPOTIFY" {
                self.duration = dur / 1000.0
            } else {
                self.duration = dur
            }
        }
        
        if let pos = Double(components[4]) {
            // Spotify returns seconds, Music returns seconds
            self.elapsedTime = pos
            self.lastKnownPosition = pos
            self.lastUpdateTime = Date()
            
            if self.duration > 0 {
                self.playbackProgress = self.elapsedTime / self.duration
            }
        }
        
        // Get artwork for Music.app only (Spotify artwork requires different approach)
        if components.count > 5 && components[5] == "MUSIC" {
            getArtworkFromMusic()
        } else {
            // For Spotify, try to get artwork URL
            getSpotifyArtwork()
        }
    }
    
    private func getArtworkFromMusic() {
        let script = """
        tell application "Music"
            if player state is not stopped then
                try
                    set currentArtwork to data of artwork 1 of current track
                    return currentArtwork
                end try
            end if
        end tell
        """
        
        if let appleScript = NSAppleScript(source: script) {
            var error: NSDictionary?
            let result = appleScript.executeAndReturnError(&error)
            
            if error == nil {
                let artworkData = result.data
                if let image = NSImage(data: artworkData) {
                    DispatchQueue.main.async { [weak self] in
                        self?.albumArtwork = image
                    }
                }
            }
        }
    }
    
    private func getSpotifyArtwork() {
        let script = """
        tell application "Spotify"
            if player state is not stopped then
                try
                    set artworkUrl to artwork url of current track
                    return artworkUrl
                end try
            end if
        end tell
        """
        
        if let appleScript = NSAppleScript(source: script) {
            var error: NSDictionary?
            let result = appleScript.executeAndReturnError(&error)
            
            if error == nil, let urlString = result.stringValue, let url = URL(string: urlString) {
                // Download artwork from URL
                URLSession.shared.dataTask(with: url) { [weak self] data, response, error in
                    if let data = data, let image = NSImage(data: data) {
                        DispatchQueue.main.async {
                            self?.albumArtwork = image
                        }
                    }
                }.resume()
            }
        }
    }
    
    private func clearNowPlayingInfo() {
        self.isPlaying = false
        self.songTitle = ""
        self.artist = ""
        self.albumArtwork = nil
        self.playbackProgress = 0.0
        self.duration = 0.0
        self.elapsedTime = 0.0
        self.currentApp = ""
        self.lastUpdateTime = nil
        self.lastKnownPosition = 0.0
        self.lastArtworkURL = nil
    }
    
    private enum MediaRemote {
        private typealias MRMediaRemoteSendCommandFunc = @convention(c) (UInt32, AnyObject?) -> Bool
        
        private static let sendCommandFunc: MRMediaRemoteSendCommandFunc? = {
            guard let bundle = Bundle(path: "/System/Library/PrivateFrameworks/MediaRemote.framework"),
                  bundle.load(),
                  let pointer = CFBundleGetFunctionPointerForName(
                      CFBundleGetBundleWithIdentifier("com.apple.MediaRemote" as CFString),
                      "MRMediaRemoteSendCommand" as CFString
                  ) else {
                return nil
            }
            return unsafeBitCast(pointer, to: MRMediaRemoteSendCommandFunc.self)
        }()
        
        static func play() {
            _ = sendCommandFunc?(0, nil)
        }
        
        static func pause() {
            _ = sendCommandFunc?(1, nil)
        }
        
        static func togglePlayPause() {
            _ = sendCommandFunc?(2, nil)
        }
        
        static func nextTrack() {
            _ = sendCommandFunc?(4, nil)
        }
        
        static func previousTrack() {
            _ = sendCommandFunc?(5, nil)
        }
    }
    
    private func sendMediaKey(_ key: Int32) {
        func doKey(down: Bool) {
            let flags = NSEvent.ModifierFlags(rawValue: down ? 0xa00 : 0xb00)
            let data1 = Int((key << 16) | (down ? 0xa00 : 0xb00))
            let ev = NSEvent.otherEvent(
                with: .systemDefined,
                location: .zero,
                modifierFlags: flags,
                timestamp: 0,
                windowNumber: 0,
                context: nil,
                subtype: 8,
                data1: data1,
                data2: -1
            )
            let cgEv = ev?.cgEvent
            cgEv?.post(tap: .cghidEventTap)
        }
        doKey(down: true)
        doKey(down: false)
    }
    
    func play() {
        DispatchQueue.main.async { [weak self] in
            self?.isPlaying = true
            self?.lastUpdateTime = Date()
        }
        MediaRemote.play()
        if currentApp == "Music" || currentApp == "Spotify" {
            executeCommand("play")
        } else if currentApp == "SpotifyWeb" {
            executeSpotifyWebCommand("play")
        } else {
            executeUniversalBrowserCommand("play")
        }
        sendMediaKey(16)
    }
    
    func pause() {
        DispatchQueue.main.async { [weak self] in
            self?.isPlaying = false
        }
        MediaRemote.pause()
        if currentApp == "Music" || currentApp == "Spotify" {
            executeCommand("pause")
        } else if currentApp == "SpotifyWeb" {
            executeSpotifyWebCommand("pause")
        } else {
            executeUniversalBrowserCommand("pause")
        }
        sendMediaKey(16)
    }
    
    func togglePlayPause() {
        let willBePlaying = !isPlaying
        DispatchQueue.main.async { [weak self] in
            self?.isPlaying = willBePlaying
            if willBePlaying {
                self?.lastUpdateTime = Date()
            }
        }
        MediaRemote.togglePlayPause()
        if currentApp == "Music" || currentApp == "Spotify" {
            executeCommand("playpause")
        } else if currentApp == "SpotifyWeb" {
            executeSpotifyWebCommand("playpause")
        } else {
            executeUniversalBrowserCommand("playpause")
        }
        sendMediaKey(16)
    }
    
    func nextTrack() {
        DispatchQueue.main.async { [weak self] in
            self?.albumArtwork = nil
        }
        MediaRemote.nextTrack()
        if currentApp == "Music" || currentApp == "Spotify" {
            executeCommand("next track")
        } else if currentApp == "SpotifyWeb" {
            executeSpotifyWebCommand("next")
        } else {
            executeUniversalBrowserCommand("next")
        }
        sendMediaKey(19)
        sendMediaKey(17)
    }
    
    func previousTrack() {
        DispatchQueue.main.async { [weak self] in
            self?.albumArtwork = nil
        }
        MediaRemote.previousTrack()
        if currentApp == "Music" {
            executeCommand("back track")
        } else if currentApp == "Spotify" {
            executeCommand("previous track")
        } else if currentApp == "SpotifyWeb" {
            executeSpotifyWebCommand("previous")
        } else {
            executeUniversalBrowserCommand("previous")
        }
        sendMediaKey(20)
        sendMediaKey(18)
    }
    
    private func executeUniversalBrowserCommand(_ command: String) {
        let js = """
        (function() {
            const cmd = '\(command)';
            // 1. YouTube Music
            if (window.location.hostname.includes('music.youtube.com')) {
                if (cmd === 'playpause' || cmd === 'play' || cmd === 'pause') {
                    const btn = document.querySelector('#play-pause-button') || document.querySelector('.play-pause-button');
                    if (btn) { btn.click(); return 'OK'; }
                } else if (cmd === 'next') {
                    const btn = document.querySelector('.next-button') || document.querySelector('#next-button');
                    if (btn) { btn.click(); return 'OK'; }
                } else if (cmd === 'previous') {
                    const btn = document.querySelector('.previous-button') || document.querySelector('#previous-button');
                    if (btn) { btn.click(); return 'OK'; }
                }
            }
            // 2. YouTube
            if (window.location.hostname.includes('youtube.com')) {
                const vid = document.querySelector('video');
                if (cmd === 'playpause') {
                    const btn = document.querySelector('.ytp-play-button');
                    if (btn) { btn.click(); return 'OK'; }
                    if (vid) { vid.paused ? vid.play() : vid.pause(); return 'OK'; }
                } else if (cmd === 'next') {
                    document.querySelector('.ytp-next-button')?.click();
                    return 'OK';
                } else if (cmd === 'previous') {
                    document.querySelector('.ytp-prev-button')?.click();
                    if (vid) vid.currentTime = 0;
                    return 'OK';
                }
            }
            // 3. Spotify Web
            if (window.location.hostname.includes('spotify.com')) {
                if (cmd === 'playpause' || cmd === 'play' || cmd === 'pause') {
                    (document.querySelector('[data-testid="control-button-playpause"]') || document.querySelector('button[aria-label*="Pause"]') || document.querySelector('button[aria-label*="Play"]'))?.click();
                    return 'OK';
                } else if (cmd === 'next') {
                    (document.querySelector('[data-testid="control-button-skip-forward"]') || document.querySelector('button[aria-label*="Next"]'))?.click();
                    return 'OK';
                } else if (cmd === 'previous') {
                    (document.querySelector('[data-testid="control-button-skip-back"]') || document.querySelector('button[aria-label*="Previous"]'))?.click();
                    return 'OK';
                }
            }
            // 4. SoundCloud
            if (window.location.hostname.includes('soundcloud.com')) {
                if (cmd === 'playpause') { document.querySelector('.playControl')?.click(); return 'OK'; }
                if (cmd === 'next') { document.querySelector('.skipControl__next')?.click(); return 'OK'; }
                if (cmd === 'previous') { document.querySelector('.skipControl__previous')?.click(); return 'OK'; }
            }
            // 5. Generic HTML5 Media
            const media = document.querySelector('video') || document.querySelector('audio');
            if (media) {
                if (cmd === 'playpause') { media.paused ? media.play() : media.pause(); return 'OK'; }
                if (cmd === 'play') { media.play(); return 'OK'; }
                if (cmd === 'pause') { media.pause(); return 'OK'; }
                if (cmd === 'next') { media.currentTime += 10; return 'OK'; }
                if (cmd === 'previous') { media.currentTime = Math.max(0, media.currentTime - 10); return 'OK'; }
            }
            return 'NOT_FOUND';
        })();
        """
        
        let escapedJS = js
            .replacingOccurrences(of: "\\", with: "\\\\")
            .replacingOccurrences(of: "\"", with: "\\\"")
            .replacingOccurrences(of: "\n", with: " ")
        
        let script = """
        tell application "System Events"
            set chromeRunning to (name of processes) contains "Google Chrome"
            set braveRunning to (name of processes) contains "Brave Browser"
            set safariRunning to (name of processes) contains "Safari"
        end tell
        
        if chromeRunning then
            tell application "Google Chrome"
                try
                    repeat with w in windows
                        repeat with t in tabs of w
                            set u to URL of t
                            if u contains "music.youtube.com" or u contains "youtube.com" or u contains "spotify.com" or u contains "soundcloud.com" or u contains "music.apple.com" then
                                execute t javascript "\(escapedJS)"
                                return "OK"
                            end if
                        end repeat
                    end repeat
                end try
            end tell
        end if
        
        if braveRunning then
            tell application "Brave Browser"
                try
                    repeat with w in windows
                        repeat with t in tabs of w
                            set u to URL of t
                            if u contains "music.youtube.com" or u contains "youtube.com" or u contains "spotify.com" or u contains "soundcloud.com" then
                                execute t javascript "\(escapedJS)"
                                return "OK"
                            end if
                        end repeat
                    end repeat
                end try
            end tell
        end if
        
        if safariRunning then
            tell application "Safari"
                try
                    repeat with w in windows
                        repeat with t in tabs of w
                            set u to URL of t
                            if u contains "music.youtube.com" or u contains "youtube.com" or u contains "spotify.com" or u contains "soundcloud.com" then
                                do JavaScript "\(escapedJS)" in t
                                return "OK"
                            end if
                        end repeat
                    end repeat
                end try
            end tell
        end if
        
        return "NONE"
        """
        
        if let appleScript = NSAppleScript(source: script) {
            var error: NSDictionary?
            appleScript.executeAndReturnError(&error)
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { [weak self] in
                self?.updateNowPlayingInfo()
            }
        }
    }
    
    private func executeSpotifyWebCommand(_ command: String) {
        let jsCommand = """
        (function() {
            const command = "\(command)";
            const first = (selectors) => {
                for (const selector of selectors) {
                    const match = document.querySelector(selector);
                    if (match) return match;
                }
                return null;
            };
            const playPause = first([
                '[data-testid="control-button-playpause"]',
                'button[aria-label*="Pause"]',
                'button[aria-label*="Play"]',
                'button[aria-label*="Resume"]'
            ]);
            const label = (playPause && playPause.getAttribute('aria-label') || '').toLowerCase();
            const isPlaying = label.includes('pause');

            if (command === 'next') {
                first(['[data-testid="control-button-skip-forward"]', 'button[aria-label*="Next"]'])?.click();
            } else if (command === 'previous') {
                first(['[data-testid="control-button-skip-back"]', 'button[aria-label*="Previous"]'])?.click();
            } else if (command === 'playpause') {
                playPause?.click();
            } else if (command === 'play' && !isPlaying) {
                playPause?.click();
            } else if (command === 'pause' && isPlaying) {
                playPause?.click();
            }
        })();
        """

        _ = executeJavaScriptOnSpotifyTab(jsCommand)

        // Force update after command
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { [weak self] in
            self?.updateNowPlayingInfo()
        }
    }

    private func executeJavaScriptOnSpotifyTab(_ javascript: String) -> String? {
        let escapedJS = javascript
            .replacingOccurrences(of: "\\", with: "\\\\")
            .replacingOccurrences(of: "\"", with: "\\\"")
            .replacingOccurrences(of: "\n", with: " ")

        let script = """
        tell application "System Events"
            set chromeRunning to (name of processes) contains "Google Chrome"
        end tell

        if chromeRunning then
            tell application "/Applications/Google Chrome.app"
                try
                    repeat with windowIndex from 1 to count of windows
                        repeat with tabIndex from 1 to count of tabs of window windowIndex
                            set tabURL to URL of tab tabIndex of window windowIndex
                            if tabURL contains "open.spotify.com" then
                                return execute tab tabIndex of window windowIndex javascript "\(escapedJS)"
                            end if
                        end repeat
                    end repeat
                end try
            end tell
        end if

        return "NOT_PLAYING"
        """

        guard let appleScript = NSAppleScript(source: script) else { return nil }
        var error: NSDictionary?
        let result = appleScript.executeAndReturnError(&error)

        if let err = error {
            print("Spotify Web AppleScript error: \(err)")
            return nil
        }

        return result.stringValue
    }
    
    private func isBrowser() -> Bool {
        return currentApp == "Safari" || currentApp == "Chrome" || currentApp == "Brave"
    }
    
    private func executeCommand(_ command: String) {
        let appName = currentApp.isEmpty ? "Music" : currentApp
        let script = "tell application \"\(appName)\" to \(command)"
        
        if let appleScript = NSAppleScript(source: script) {
            var error: NSDictionary?
            appleScript.executeAndReturnError(&error)
            
            // Force update after command
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { [weak self] in
                self?.updateNowPlayingInfo()
            }
        }
    }
    
    var hasMedia: Bool {
        return !songTitle.isEmpty
    }
    
    var isBrowserSource: Bool {
        return false
    }
    
    deinit {
        updateTimer?.invalidate()
        progressTimer?.invalidate()
    }
}
