//
//  SchemePickerView.swift
//  ThemeSwitcher
//
//  Created by Modamori Oluwayomi on 2024-09-14.
//

import SwiftUI

enum AppScheme :String {
    case dark = "Dark"
    case light = "Light"
    case device = "Device"
}

 struct SchemePreview: Identifiable {
    var id: UUID = .init()
    var image: UIImage?
    var text: String
}

struct SchemeHostView<Content: View> : View {
    @ViewBuilder var content: Content
    @AppStorage("AppScheme") private var appScheme: AppScheme = .device
    init(@ViewBuilder content: @escaping () -> Content){
        self.content = content()
        
        if let window = (UIApplication.shared.connectedScenes.first as? UIWindowScene)? .keyWindow {
            window.overrideUserInterfaceStyle = appScheme == .dark ? .dark : appScheme == .light ? .light : .unspecified
        }
    }
    @SceneStorage("ShowScenePickerView") private var showPickerView: Bool = false
    @State private var showSheet: Bool = false
    @State private var schemePreviews: [SchemePreview] = []
    @State private var overlayWindow: UIWindow?
    @Environment (\.colorScheme) private var scheme
    var body: some View {
        content
            .sheet(isPresented: $showSheet, onDismiss: {
                schemePreviews =  []
                showPickerView = false
            }, content: {
                SchemePickerView(previews:  $schemePreviews)
            })
            .onChange(of: showPickerView) { oldValue, newValue in
                if newValue {
                    generateSchemePreviews()
                }else {
                    showSheet = false
                }
            }
            .onAppear{
                    if let scene = (UIApplication.shared.connectedScenes.first as? UIWindowScene), overlayWindow == nil {
                        let window = UIWindow(windowScene: scene)
                        window.backgroundColor = .clear
                        window.isHidden = false
                        window.isUserInteractionEnabled = false
                        let emptyController = UIViewController()
                        emptyController.view.backgroundColor = .clear
                        window.rootViewController = emptyController
                        
                        overlayWindow = window
                    }
            }
    }
    private func generateSchemePreviews(){
        Task{
            await MainActor.run{
                if let window =  (UIApplication.shared.connectedScenes.first as? UIWindowScene)?.keyWindow, schemePreviews.isEmpty {
                    let size =  window.screen.bounds.size
                    let defaultSchemePreview =  window.subviews.first?.image(size)
                    let defaultStyle = window.overrideUserInterfaceStyle
                    schemePreviews.append(
                        .init(
                            image:defaultSchemePreview,
                            text: scheme == .dark ? AppScheme.dark.rawValue : AppScheme.light.rawValue
                        )
                    )
                    
                    showOverlayImageView(defaultSchemePreview)
                    
                    window.overrideUserInterfaceStyle = scheme.oppositeInterfaceStyle
                    let otherSchemePreviewImage = window.image(size)
                    schemePreviews.append(
                        .init(
                            image: otherSchemePreviewImage,
                            text: scheme == .dark ? AppScheme.light.rawValue : AppScheme.dark.rawValue
                        )
                    )
                    
                    if scheme == .dark {
                        schemePreviews = schemePreviews
                            .reversed()
                    }
                    window.overrideUserInterfaceStyle = defaultStyle
                    removeOverlayImageView()
                    showSheet = true
                }
            }
        }
    }
    
    private func showOverlayImageView(_ image: UIImage?) {
        if overlayWindow?.rootViewController?.view.subviews.isEmpty ?? false {
            let imageView = UIImageView(image: image)
            imageView.contentMode = .scaleAspectFit
            
            overlayWindow?.rootViewController?.view.addSubview(imageView)
        }
    }
    
    private func removeOverlayImageView() {
        overlayWindow?.rootViewController?.view.subviews.forEach{
            $0.removeFromSuperview()
        }
    }
}

fileprivate extension ColorScheme {
    var oppositeInterfaceStyle: UIUserInterfaceStyle {
        return self == .dark ? .light : .dark
    }
}

struct SchemePickerView: View {
    @Binding var previews: [SchemePreview]
    @State private var localSchemeState: AppScheme = .device
    @AppStorage("AppScheme") private var appScheme: AppScheme = .device
    var body: some View {
        VStack(alignment: .leading, spacing: 15){
            Text("Apperance")
                .font(.title3.bold())
            
            Spacer(minLength: 0)
            GeometryReader{ _ in
                HStack(spacing: 0) {
                    ForEach(previews){ preview in
                    schemeCardView([preview])
                    }
                    schemeCardView(previews)
                }
            }
        }
        .padding(20)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background{
            ZStack {
                Rectangle()
                    .fill(.background)
                Rectangle()
                    .fill(Color.primary.opacity(0.05))
            }
            .clipShape(.rect(cornerRadius: 20))
        }
        .padding(.horizontal)
        .presentationDetents([.height(320)])
        .presentationBackground(.clear)
        .onChange(of: appScheme, initial: true) { oldValue, newValue in
            localSchemeState = newValue
        }
        .animation(.easeInOut(duration: 0.25), value: appScheme)
    }
    @ViewBuilder
    fileprivate func schemeCardView(_ preview: [SchemePreview]) -> some View {
        VStack(spacing: 6){
            if let image = preview.first?.image {
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .overlay{
                        if let secondImage = preview.last?.image, preview.count == 2 {
                            GeometryReader {
                                let width = $0.size.width / 2
                                Image(uiImage: secondImage)
                                    .resizable()
                                    .aspectRatio(contentMode: .fit)
                                    .mask(alignment: .trailing){
                                        Rectangle()
                                            .frame(width: width)
                                    }
                            }
                        }
                    }
                    .clipShape(.rect(cornerRadius: 15))
            }
            let text = preview.count == 2 ? "Device" : preview.first?.text ?? ""
            Text(text)
                .font(.caption)
                .foregroundStyle(.gray)
            
            ZStack{
                Image(systemName: "circle")
                if localSchemeState.rawValue == text {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(Color.primary)
                        .transition(.blurReplace)
                }
            }
        }
        .frame(maxWidth: .infinity)
        .contentShape(.rect)
        .onTapGesture {
            if preview.count == 2 {
                appScheme = .device
            }else{
                appScheme = preview.first?.text == AppScheme.dark.rawValue ? .dark : .light
            }
            updateScheme()
        }
    }
    private func updateScheme(){
        if let window = (UIApplication.shared.connectedScenes.first as? UIWindowScene)?.keyWindow {
            window.overrideUserInterfaceStyle = appScheme == .dark ? .dark : appScheme == .light ? .light : .unspecified
        }
    }
}

extension UIView{
    func image(_ size:CGSize) -> UIImage {
        let renderer = UIGraphicsImageRenderer(size: size)
        return renderer.image {_ in
            drawHierarchy(in: .init(origin: .zero, size: size), afterScreenUpdates: true)
        }
    }
}
