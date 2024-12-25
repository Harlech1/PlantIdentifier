import SwiftUI
import AVFoundation
import Foundation
import MarkdownUI

struct ContentView: View {
    @State private var showingCamera = false
    @State private var capturedImageBase64: String?
    @State private var showingLoadingScreen = false
    
    var body: some View {
        NavigationStack {
            ZStack {
                Button(action: {
                    showingCamera = true
                }) {
                    VStack {
                        Image(systemName: "camera.fill")
                            .font(.system(size: 30))
                        Text("Take Photo")
                            .font(.headline)
                    }
                    .foregroundColor(.white)
                    .padding(20)
                    .background(Color.green)
                    .cornerRadius(10)
                }
            }
            .navigationBarTitle("Herbi")
            .fullScreenCover(isPresented: $showingCamera) {
                CameraView(capturedImageBase64: $capturedImageBase64, 
                          showingCamera: $showingCamera, 
                          showingLoadingScreen: $showingLoadingScreen)
            }
            .fullScreenCover(isPresented: $showingLoadingScreen) {
                LoadingView(imageBase64: $capturedImageBase64)
            }
        }
    }
} 