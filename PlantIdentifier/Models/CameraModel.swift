import AVFoundation
import SwiftUI

class CameraModel: NSObject, ObservableObject {
    @Published var isTaken = false
    @Published var session = AVCaptureSession()
    @Published var alert = false
    @Published var output = AVCapturePhotoOutput()
    var preview: AVCaptureVideoPreviewLayer?
    
    var currentCamera: AVCaptureDevice?
    var completionHandler: ((String) -> Void)?
    
    func checkPermissions() {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            setUp()
            return
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { status in
                if status {
                    self.setUp()
                }
            }
        default:
            alert = true
            return
        }
    }
    
    func setUp() {
        do {
            self.session.beginConfiguration()
            
            let device = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back)
            currentCamera = device
            
            let input = try AVCaptureDeviceInput(device: device!)
            
            if self.session.canAddInput(input) {
                self.session.addInput(input)
            }
            
            if self.session.canAddOutput(self.output) {
                self.session.addOutput(self.output)
            }
            
            self.session.commitConfiguration()
            
            DispatchQueue.global(qos: .background).async {
                self.session.startRunning()
            }
            
        } catch {
            print(error.localizedDescription)
        }
    }
    
    func takePicture(completion: @escaping (String) -> Void) {
        completionHandler = completion
        DispatchQueue.global(qos: .background).async {
            self.output.capturePhoto(with: AVCapturePhotoSettings(), delegate: self)
        }
    }
    
    func switchCamera() {
        session.beginConfiguration()
        
        // Remove existing input
        guard let currentInput = session.inputs.first as? AVCaptureDeviceInput else { return }
        session.removeInput(currentInput)
        
        // Get new camera
        let newPosition: AVCaptureDevice.Position = currentInput.device.position == .back ? .front : .back
        guard let newCamera = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: newPosition) else { return }
        
        do {
            let newInput = try AVCaptureDeviceInput(device: newCamera)
            if session.canAddInput(newInput) {
                session.addInput(newInput)
                currentCamera = newCamera
            }
        } catch {
            print(error.localizedDescription)
        }
        
        session.commitConfiguration()
    }
}

extension CameraModel: AVCapturePhotoCaptureDelegate {
    func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
        if let imageData = photo.fileDataRepresentation() {
            let base64String = imageData.base64EncodedString()
            DispatchQueue.main.async {
                self.completionHandler?(base64String)
            }
        }
    }
} 