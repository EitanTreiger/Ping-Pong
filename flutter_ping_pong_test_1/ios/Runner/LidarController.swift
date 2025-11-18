import Foundation
import AVFoundation
import CoreImage
import VideoToolbox

class LidarController: NSObject, AVCaptureDataOutputSynchronizerDelegate {
    private var captureSession: AVCaptureSession?
    private let videoDataOutput = AVCaptureVideoDataOutput()
    private let depthDataOutput = AVCaptureDepthDataOutput()
    private var dataOutputSynchronizer: AVCaptureDataOutputSynchronizer?
    private let dataOutputQueue = DispatchQueue(label: "video data queue", qos: .userInitiated, attributes: [], autoreleaseFrequency: .workItem)
    
    private var assetWriter: AVAssetWriter?
    private var writerInput: AVAssetWriterInput?
    private var pixelBufferAdaptor: AVAssetWriterInputPixelBufferAdaptor?
    private var isRecording = false
    private var recordingStartTime: CMTime = .zero
    
    // Core Image context for combining frames
    private let ciContext = CIContext()
    private var combinedFrameBuffer: CVPixelBuffer?
    
    func startRecording() -> Bool {
        guard !isRecording else {
            print("Already recording.")
            return true
        }
        
        captureSession = AVCaptureSession()
        captureSession?.sessionPreset = .hd1920x1080 // Set a preset for the RGB camera
        
        guard let videoDevice = AVCaptureDevice.default(.builtInDualWideCamera, for: .video, position: .back) else {
            print("Dual Wide Camera not available.")
            return false
        }
        
        do {
            try videoDevice.lockForConfiguration()
            videoDevice.activeVideoMinFrameDuration = CMTime(value: 1, timescale: 15)
            videoDevice.activeVideoMaxFrameDuration = CMTime(value: 1, timescale: 15)
            videoDevice.unlockForConfiguration()
        } catch {
            print("Failed to lock device for configuration: \(error)")
        }
        
        do {
            let deviceInput = try AVCaptureDeviceInput(device: videoDevice)
            if captureSession?.canAddInput(deviceInput) ?? false {
                captureSession?.addInput(deviceInput)
            }
        } catch {
            print("Error setting up device input: \(error)")
            return false
        }
        
        // Add video output
        if captureSession?.canAddOutput(videoDataOutput) ?? false {
            captureSession?.addOutput(videoDataOutput)
        }
        
        // Add depth output
        if captureSession?.canAddOutput(depthDataOutput) ?? false {
            captureSession?.addOutput(depthDataOutput)
            depthDataOutput.isFilteringEnabled = true
        }
        
        // Synchronize outputs
        dataOutputSynchronizer = AVCaptureDataOutputSynchronizer(dataOutputs: [videoDataOutput, depthDataOutput])
        dataOutputSynchronizer?.setDelegate(self, queue: dataOutputQueue)
        
        captureSession?.startRunning()
        isRecording = true
        recordingStartTime = .zero
        return true
    }
    
    func stopRecording(completion: @escaping (URL?) -> Void) {
        guard isRecording else {
            completion(nil)
            return
        }
        
        isRecording = false
        captureSession?.stopRunning()
        
        writerInput?.markAsFinished()
        assetWriter?.finishWriting { [weak self] in
            guard let self = self, let outputURL = self.assetWriter?.outputURL else {
                completion(nil)
                return
            }
            print("Finished writing to \(outputURL)")
            self.assetWriter = nil
            self.writerInput = nil
            self.pixelBufferAdaptor = nil
            self.combinedFrameBuffer = nil
            completion(outputURL)
        }
    }
    
    private func setupAssetWriter(width: Int, height: Int) {
        let outputURL = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString).appendingPathExtension("mp4")
        do {
            assetWriter = try AVAssetWriter(outputURL: outputURL, fileType: .mp4)
        } catch {
            print("Error creating asset writer: \(error)")
            return
        }
        
        let videoSettings: [String: Any] = [
            AVVideoCodecKey: AVVideoCodecType.h264,
            AVVideoWidthKey: width,
            AVVideoHeightKey: height,
            AVVideoCompressionPropertiesKey: [AVVideoAverageBitRateKey: 12000000] // 12 Mbps
        ]
        
        writerInput = AVAssetWriterInput(mediaType: .video, outputSettings: videoSettings)
        writerInput?.expectsMediaDataInRealTime = true
        
        let sourcePixelBufferAttributes: [String: Any] = [
            kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32BGRA,
            kCVPixelBufferWidthKey as String: width,
            kCVPixelBufferHeightKey as String: height
        ]
        
        pixelBufferAdaptor = AVAssetWriterInputPixelBufferAdaptor(assetWriterInput: writerInput!, sourcePixelBufferAttributes: sourcePixelBufferAttributes)
        
        if let writerInput = writerInput, assetWriter?.canAdd(writerInput) ?? false {
            assetWriter?.add(writerInput)
        }
        
        assetWriter?.startWriting()
    }

    func dataOutputSynchronizer(_ synchronizer: AVCaptureDataOutputSynchronizer, didOutput synchronizedData: AVCaptureSynchronizedDataCollection) {
        guard isRecording,
              let syncedVideoData = synchronizedData.synchronizedData(for: videoDataOutput) as? AVCaptureSynchronizedSampleBufferData,
              let syncedDepthData = synchronizedData.synchronizedData(for: depthDataOutput) as? AVCaptureSynchronizedDepthData else {
            return
        }
        
        let timestamp = syncedVideoData.timestamp
        guard let videoPixelBuffer = CMSampleBufferGetImageBuffer(syncedVideoData.sampleBuffer) else { return }
        var depthData = syncedDepthData.depthData
        
        if depthData.depthDataType != kCVPixelFormatType_DepthFloat32 {
            depthData = depthData.converting(toDepthDataType: kCVPixelFormatType_DepthFloat32)
        }
        
        if assetWriter == nil {
            let videoWidth = CVPixelBufferGetWidth(videoPixelBuffer)
            let depthWidth = CVPixelBufferGetWidth(depthData.depthDataMap)
            let height = CVPixelBufferGetHeight(videoPixelBuffer)
            setupAssetWriter(width: videoWidth + depthWidth, height: height)
        }
        
        guard let writerInput = writerInput, writerInput.isReadyForMoreMediaData, let adaptor = pixelBufferAdaptor else { return }
        
        if assetWriter?.status == .writing {
            if recordingStartTime == .zero {
                recordingStartTime = timestamp
                assetWriter?.startSession(atSourceTime: timestamp)
            }
            
            guard let depthGrayscaleBuffer = convertToGrayscale(depthData: depthData) else { return }
            
            if combinedFrameBuffer == nil {
                let videoWidth = CVPixelBufferGetWidth(videoPixelBuffer)
                let depthWidth = CVPixelBufferGetWidth(depthGrayscaleBuffer)
                let height = CVPixelBufferGetHeight(videoPixelBuffer)
                CVPixelBufferCreate(kCFAllocatorDefault, videoWidth + depthWidth, height, kCVPixelFormatType_32BGRA, nil, &combinedFrameBuffer)
            }
            
            guard let combinedBuffer = combinedFrameBuffer else { return }
            
            combineBuffers(video: videoPixelBuffer, depth: depthGrayscaleBuffer, into: combinedBuffer)
            
            adaptor.append(combinedBuffer, withPresentationTime: timestamp)
        }
    }
    
    private func combineBuffers(video: CVPixelBuffer, depth: CVPixelBuffer, into output: CVPixelBuffer) {
        let videoImage = CIImage(cvPixelBuffer: video)
        let depthImage = CIImage(cvPixelBuffer: depth)
        
        let videoWidth = videoImage.extent.width
        
        // Translate depth image to be to the right of the video image
        let transform = CGAffineTransform(translationX: videoWidth, y: 0)
        let translatedDepthImage = depthImage.transformed(by: transform)
        
        // Composite depth over the video image background
        let combinedImage = translatedDepthImage.composited(over: videoImage)
        
        ciContext.render(combinedImage, to: output)
    }
    
    private func convertToGrayscale(depthData: AVDepthData) -> CVPixelBuffer? {
        let depthPixelBuffer = depthData.depthDataMap
        let width = CVPixelBufferGetWidth(depthPixelBuffer)
        let height = CVPixelBufferGetHeight(depthPixelBuffer)
        
        var grayscalePixelBuffer: CVPixelBuffer?
        let status = CVPixelBufferCreate(kCFAllocatorDefault, width, height, kCVPixelFormatType_32BGRA, nil, &grayscalePixelBuffer)
        guard status == kCVReturnSuccess, let buffer = grayscalePixelBuffer else { return nil }
        
        CVPixelBufferLockBaseAddress(depthPixelBuffer, .readOnly)
        CVPixelBufferLockBaseAddress(buffer, [])
        
        guard let depthBaseAddress = CVPixelBufferGetBaseAddress(depthPixelBuffer),
              let grayBaseAddress = CVPixelBufferGetBaseAddress(buffer) else {
            CVPixelBufferUnlockBaseAddress(depthPixelBuffer, .readOnly)
            CVPixelBufferUnlockBaseAddress(buffer, [])
            return nil
        }
        
        let depthBytesPerRow = CVPixelBufferGetBytesPerRow(depthPixelBuffer)
        let grayBytesPerRow = CVPixelBufferGetBytesPerRow(buffer)

        // Depth values are in meters.
        let minDepth: Float32 = 0.25
        let maxDepth: Float32 = 5.0
        let range = maxDepth - minDepth
        
        for y in 0..<height {
            let depthRow = depthBaseAddress.advanced(by: y * depthBytesPerRow).assumingMemoryBound(to: Float32.self)
            let grayRow = grayBaseAddress.advanced(by: y * grayBytesPerRow).assumingMemoryBound(to: UInt8.self)
            
            for x in 0..<width {
                let depth = depthRow[x]
                var normalized: Float32 = 0.0
                if depth.isFinite && range > 0 {
                    let clampedDepth = max(minDepth, min(depth, maxDepth))
                    normalized = (clampedDepth - minDepth) / range
                }
                
                let grayValue = UInt8(normalized * 255.0)
                let pixelIndex = x * 4
                grayRow[pixelIndex] = grayValue
                grayRow[pixelIndex + 1] = grayValue
                grayRow[pixelIndex + 2] = grayValue
                grayRow[pixelIndex + 3] = 255
            }
        }
        
        CVPixelBufferUnlockBaseAddress(depthPixelBuffer, .readOnly)
        CVPixelBufferUnlockBaseAddress(buffer, [])
        
        return buffer
    }
}
