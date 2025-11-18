import Foundation
import AVFoundation
import CoreImage

class LidarController: NSObject, AVCaptureDepthDataOutputDelegate {
    private var captureSession: AVCaptureSession?
    private var depthDataOutput: AVCaptureDepthDataOutput?
    private var videoDevice: AVCaptureDevice?
    
    var onDepthData: ((CIImage) -> Void)?
    
    func startCapture() -> Bool {
        if #available(iOS 15.4, *) {
            captureSession = AVCaptureSession()
            
            guard let videoDevice = AVCaptureDevice.default(.builtInLiDARDepthCamera, for: .video, position: .back) else {
                print("LiDAR camera not available")
                return false
            }
            self.videoDevice = videoDevice
            
            do {
                let input = try AVCaptureDeviceInput(device: videoDevice)
                if captureSession?.canAddInput(input) ?? false {
                    captureSession?.addInput(input)
                }
            } catch {
                print("Error setting up device input: \(error)")
                return false
            }
            
            depthDataOutput = AVCaptureDepthDataOutput()
            if let depthDataOutput = depthDataOutput, captureSession?.canAddOutput(depthDataOutput) ?? false {
                captureSession?.addOutput(depthDataOutput)
                depthDataOutput.setDelegate(self, callbackQueue: DispatchQueue(label: "depth data queue"))
                depthDataOutput.isFilteringEnabled = true
                if let connection = depthDataOutput.connection(with: .depthData) {
                    connection.isEnabled = true
                }
            }
            
            captureSession?.startRunning()
            return true
        } else {
            print("LiDAR features require iOS 15.4 or newer.")
            return false
        }
    }
    
    func stopCapture() {
        captureSession?.stopRunning()
        captureSession = nil
    }
    
    func depthDataOutput(_ output: AVCaptureDepthDataOutput, didOutput depthData: AVDepthData, timestamp: CMTime, connection: AVCaptureConnection) {
        let depthPixelBuffer = depthData.depthDataMap
        let depthImage = CIImage(cvPixelBuffer: depthPixelBuffer)
        onDepthData?(depthImage)
    }
}
