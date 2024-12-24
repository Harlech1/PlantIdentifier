import SwiftUI
import AVFoundation

struct CameraView: View {
    @Environment(\.dismiss) var dismiss
    @StateObject private var camera = CameraModel()
    @Binding var capturedImageBase64: String?
    @Binding var showingCamera: Bool
    @Binding var showingLoadingScreen: Bool
    
    var body: some View {
        ZStack {
            CameraPreviewView(camera: camera)
                .ignoresSafeArea()
            
            VStack {
                Spacer()
                HStack {
                    Button(action: {
                        dismiss()
                    }) {
                        Image(systemName: "xmark")
                            .font(.title)
                            .foregroundColor(.white)
                            .padding()
                    }
                    
                    Spacer()
                    
                    Button(action: {
                        camera.takePicture { base64String in
                            capturedImageBase64 = base64String
                            showingCamera = false
                            showingLoadingScreen = true
                        }
                    }) {
                        Circle()
                            .stroke(Color.white, lineWidth: 3)
                            .frame(width: 65, height: 65)
                            .overlay(
                                Circle()
                                    .fill(Color.white)
                                    .frame(width: 55, height: 55)
                            )
                    }
                    
                    Spacer()
                    
                    Button(action: {
                        camera.switchCamera()
                    }) {
                        Image(systemName: "camera.rotate.fill")
                            .font(.title)
                            .foregroundColor(.white)
                            .padding()
                    }
                }
                .padding(.horizontal)
                .padding(.bottom, 30)
            }
        }
        .onAppear {
            camera.checkPermissions()
        }
    }
} 