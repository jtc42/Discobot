/*
 WelcomeView.swift
 Discobot

 Created by Joel Collins on 19/03/2023.

 Copyright © 2021 Apple Inc.

 Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

 The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

 THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
 */

import MusicKit
import SwiftUI

extension UIColor {
    var lighterColor: UIColor {
        return lighterColor(removeSaturation: 0.5, resultAlpha: -1)
    }
    
    private func clamp(_ val: CGFloat) -> CGFloat {
        return min(max(val, 0.0), 1.0)
    }

    func lighterColor(removeSaturation val: CGFloat, resultAlpha alpha: CGFloat) -> UIColor {
        var h: CGFloat = 0, s: CGFloat = 0
        var b: CGFloat = 0, a: CGFloat = 0

        guard getHue(&h, saturation: &s, brightness: &b, alpha: &a)
        else { return self }
        
        return UIColor(hue: h,
                       saturation: max(s - val, 0.0),
                       brightness: b,
                       alpha: alpha == -1 ? a : alpha)
    }
    
    func shiftHSB(hueBy: CGFloat, saturationBy: CGFloat, brightnessBy: CGFloat) -> UIColor {
        var h: CGFloat = 0, s: CGFloat = 0
        var b: CGFloat = 0, a: CGFloat = 0

        guard getHue(&h, saturation: &s, brightness: &b, alpha: &a)
        else { return self }

        return UIColor(hue: clamp(h + hueBy),
                       saturation: clamp(s + saturationBy),
                       brightness: clamp(b + brightnessBy),
                       alpha: a)
    }
}

// MARK: - Welcome view

/// `WelcomeView` is a view that introduces to users the purpose of the MusicAlbums app,
/// and demonstrates best practices for requesting user consent for an app to get access to
/// Apple Music data.
///
/// Present this view as a sheet using the convenience `.welcomeSheet()` modifier.
struct WelcomeView: View {
    // MARK: - Properties
    
    /// The current authorization status of MusicKit.
    @Binding var musicAuthorizationStatus: MusicAuthorization.Status
    
    /// Opens a URL using the appropriate system service.
    @Environment(\.openURL) private var openURL
    
    // MARK: - View
    
    /// A declaration of the UI that this view presents.
    var body: some View {
        ZStack {
            gradient
            VStack {
                Text(LocalizedStringKey("title"))
                    .foregroundColor(.primary)
                    .font(.largeTitle.weight(.semibold))
                    .shadow(radius: 2)
                    .padding(.bottom, 1)
                explanatoryText
                    .foregroundColor(.primary)
                    .font(.body.weight(.medium))
                    .multilineTextAlignment(.center)
                    .shadow(radius: 1)
                    .padding([.leading, .trailing], 32)
                    .padding(.bottom, 16)
                if let secondaryExplanatoryText = self.secondaryExplanatoryText {
                    secondaryExplanatoryText
                        .foregroundColor(.primary)
                        .font(.body.weight(.medium))
                        .multilineTextAlignment(.center)
                        .shadow(radius: 1)
                        .padding([.leading, .trailing], 32)
                        .padding(.bottom, 16)
                }
                if musicAuthorizationStatus == .notDetermined || musicAuthorizationStatus == .denied {
                    Button(action: handleButtonPressed) {
                        buttonText
                            .font(.body.bold())
                            .padding([.leading, .trailing], 10)
                    }
                    .padding(15)
                    .background(Color(.white).cornerRadius(8))
                    .foregroundColor(.accentColor)
                }
            }
            .colorScheme(.dark)
        }
    }
    
    /// Constructs a gradient to use as the view background.
    private var gradient: some View {
        let primaryColor = CGColor(red: 130.0 / 255.0, green: 109.0 / 255.0, blue: 204.0 / 255.0, alpha: 1.0)
        
        let colors: [UIColor] = [
            UIColor(cgColor: primaryColor).shiftHSB(hueBy: 0.1, saturationBy: 0.0, brightnessBy: 0.0),
            UIColor(cgColor: primaryColor),
            UIColor(cgColor: primaryColor).shiftHSB(hueBy: -0.1, saturationBy: 0.2, brightnessBy: -0.3),
        ]
        
        let colorMap: [Color] = colors.map { uiColor in
            Color(cgColor: uiColor.cgColor)
        }
        
        return LinearGradient(
            gradient: Gradient(colors: colorMap),
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .flipsForRightToLeftLayoutDirection(false)
        .ignoresSafeArea()
    }
    
    /// Provides text that explains how to use the app according to the authorization status.
    private var explanatoryText: Text {
        let explanatoryText: Text
        switch musicAuthorizationStatus {
            case .restricted:
                explanatoryText = Text(LocalizedStringKey("musicAuthorizationStatus.restricted"))
            default:
                explanatoryText = Text(LocalizedStringKey("musicAuthorizationStatus"))
        }
        return explanatoryText
    }
    
    /// Provides additional text that explains how to get access to Apple Music
    /// after previously denying authorization.
    private var secondaryExplanatoryText: Text? {
        var secondaryExplanatoryText: Text?
        switch musicAuthorizationStatus {
            case .denied:
                secondaryExplanatoryText = Text(LocalizedStringKey("musicAuthorizationStatus.denied"))
            default:
                break
        }
        return secondaryExplanatoryText
    }
    
    /// A button that the user taps to continue using the app according to the current
    /// authorization status.
    private var buttonText: Text {
        let buttonText: Text
        switch musicAuthorizationStatus {
            case .notDetermined:
                buttonText = Text(LocalizedStringKey("continue"))
            case .denied:
                buttonText = Text(LocalizedStringKey("openSettings"))
            default:
                fatalError("No button should be displayed for current authorization status: \(musicAuthorizationStatus).")
        }
        return buttonText
    }
    
    // MARK: - Methods
    
    /// Allows the user to authorize Apple Music usage when tapping the Continue/Open Setting button.
    private func handleButtonPressed() {
        switch musicAuthorizationStatus {
            case .notDetermined:
                Task {
                    let musicAuthorizationStatus = await MusicAuthorization.request()
                    await update(with: musicAuthorizationStatus)
                }
            case .denied:
                if let settingsURL = URL(string: UIApplication.openSettingsURLString) {
                    openURL(settingsURL)
                }
            default:
                fatalError("No button should be displayed for current authorization status: \(musicAuthorizationStatus).")
        }
    }
    
    /// Safely updates the `musicAuthorizationStatus` property on the main thread.
    @MainActor
    private func update(with musicAuthorizationStatus: MusicAuthorization.Status) {
        withAnimation {
            self.musicAuthorizationStatus = musicAuthorizationStatus
        }
    }
    
    // MARK: - Presentation coordinator
    
    /// A presentation coordinator to use in conjuction with `SheetPresentationModifier`.
    class PresentationCoordinator: ObservableObject {
        static let shared = PresentationCoordinator()
        
        private init() {
            let authorizationStatus = MusicAuthorization.currentStatus
            musicAuthorizationStatus = authorizationStatus
            isWelcomeViewPresented = (authorizationStatus != .authorized)
        }
        
        @Published var musicAuthorizationStatus: MusicAuthorization.Status {
            didSet {
                isWelcomeViewPresented = (musicAuthorizationStatus != .authorized)
            }
        }
        
        @Published var isWelcomeViewPresented: Bool
    }
    
    // MARK: - Sheet presentation modifier
    
    /// A view modifier that changes the presentation and dismissal behavior of the welcome view.
    fileprivate struct SheetPresentationModifier: ViewModifier {
        @StateObject private var presentationCoordinator = PresentationCoordinator.shared
        
        func body(content: Content) -> some View {
            content
                .sheet(isPresented: $presentationCoordinator.isWelcomeViewPresented) {
                    WelcomeView(musicAuthorizationStatus: $presentationCoordinator.musicAuthorizationStatus)
                        .interactiveDismissDisabled()
                }
        }
    }
}

// MARK: - View extension

/// Allows the addition of the`welcomeSheet` view modifier to the top-level view.
extension View {
    func welcomeSheet() -> some View {
        modifier(WelcomeView.SheetPresentationModifier())
    }
}

// MARK: - Previews

struct WelcomeView_Previews: PreviewProvider {
    static var previews: some View {
        WelcomeView(musicAuthorizationStatus: .constant(.notDetermined))
    }
}
