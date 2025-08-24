//
//  TrackingLogic.swift
//  pikkproto
//
//  Created by Leo Nguyen on 8/19/25.
// mewo meow mewo meow pikd

import UIKit
import AVFoundation
import Vision


//for camera inputs

class CameraViewController: UIViewController, AVCaptureVideoDataOutputSampleBufferDelegate {
    var captureSession: AVCaptureSession!
    var previewLayer: AVCaptureVideoPreviewLayer!
    let HandPoseReq = VNDetectHumanHandPoseRequest()
    let overlayView = UIView()
    let maxFrames = 25
    var xBuffer = [CGFloat]()
    var yBuffer = [CGFloat]()
    var vXBuffer = [CGFloat]()
    var vYBuffer = [CGFloat]()
    var prevDir = "none"
    var prevX = 0.0
    var prevY = 0.0
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Set background color (in case camera fails)
        view.backgroundColor = .black
        
        setupCamera()
        setupOver()
        //        setupHelloWorldLabel()
    }
    
    func setupOver() {
        overlayView.frame = view.bounds
        overlayView.backgroundColor = .clear
        view.addSubview(overlayView)
    }
    
    func setupCamera() {
        captureSession = AVCaptureSession()
        captureSession.sessionPreset = .high
        
        guard let camera = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .front),
              let input = try? AVCaptureDeviceInput(device: camera) else {
            print("Could not access camera")
            return
        }
        
        let vidOut = AVCaptureVideoDataOutput()
        vidOut.setSampleBufferDelegate(self, queue: DispatchQueue(label: "herro"))
        
        if captureSession.canAddInput(input) {
            captureSession.addInput(input)
        }
        
        if captureSession.canAddOutput(vidOut) {
            captureSession.addOutput(vidOut)
        }
        
        previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
        previewLayer.frame = view.layer.bounds
        previewLayer.videoGravity = .resizeAspectFill
        //        view.layer.insertSublayer(previewLayer, below: view.layer.sublayers?.first)
        
        DispatchQueue.global(qos: .userInitiated).async {
            self.captureSession.startRunning()
        }
    }
    
    func captureOutput (_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else {return}
        
        let reqHandl = VNImageRequestHandler(cvPixelBuffer: pixelBuffer, orientation: .leftMirrored, options: [:])
        do {
            try reqHandl.perform([HandPoseReq])
            if let observations = HandPoseReq.results, !observations.isEmpty {
                DispatchQueue.main.async {
                    handleHandObs(observations)
                }
            } else {
                DispatchQueue.main.async {
                    self.overlayView.layer.sublayers?.forEach {$0.removeFromSuperlayer()}
                }
            }
        } catch {
            print("uh oh the shit couldnt perform:",error)
            
        }
        
        
        
        func handleHandObs(_ observations: [VNHumanHandPoseObservation]) {
            
            overlayView.layer.sublayers?.forEach { $0.removeFromSuperlayer() }
            
            
            for obs in observations {
                guard let recognizedPoints = try? obs.recognizedPoints(.all),
                    let indexT = recognizedPoints[.indexTip],
                    let indexM = recognizedPoints[.indexMCP] else { continue }
                
                if indexT.confidence > 0.5 && indexM.confidence > 0.5 {
                    
                    let vX = (indexT.location.x+indexM.location.x)/2.0-prevX
                    let vY = (indexT.location.y+indexM.location.y)/2.0-prevY
                    let totVel = pow(pow(vX,2.0)+pow(vY,2.0),0.5)
                    //print("Current",index.location.x,index.location.y)
                    //print("Previous",prevX,prevY)
                    //print("Velocity",vX,vY,totVel)
                    if totVel > 0.065 && indexM.location.x > 0.2 && indexM.location.x < 0.8  && indexM.location.y > 0.1 && indexM.location.y < 0.4 {
                        //print("Buffer Count:", xBuffer.count+1)
                        xBuffer.append(((indexT.location.x+indexM.location.x)/2.0+prevX)/2.0)
                        yBuffer.append(((indexT.location.y+indexM.location.y)/2.0+prevY)/2.0)
                        vXBuffer.append(vX)
                        vYBuffer.append(vY)
                        //print("XBuffer",xBuffer)
                        //print("YBuffer",yBuffer)
                        prevX = (indexT.location.x+indexM.location.x)/2.0
                        prevY = (indexT.location.y+indexM.location.y)/2.0
                        
                        if xBuffer.count > maxFrames {
                            xBuffer.removeFirst(xBuffer.count - maxFrames)
                        }
                        
                        if yBuffer.count > maxFrames{
                            yBuffer.removeFirst(yBuffer.count - maxFrames)
                        }
                        
                    }
                    else {
                        
                        if xBuffer.count > 2 && yBuffer.count > 2 {
                            Detecting(xBuffer: xBuffer, yBuffer: yBuffer)
                        }
                        
                        xBuffer.removeAll()
                        yBuffer.removeAll()
                        vXBuffer.removeAll()
                        vYBuffer.removeAll()
                    }
                }
                else {
                    if xBuffer.count > 2 && yBuffer.count > 2 {
                        Detecting(xBuffer: xBuffer, yBuffer: yBuffer)
                    }
                    xBuffer.removeAll()
                    yBuffer.removeAll()
                    vXBuffer.removeAll()
                    vYBuffer.removeAll()
                }
            }
        }
    }
    func Detecting(xBuffer: Array<CGFloat>, yBuffer: Array<CGFloat>) {
        if let xBufF = xBuffer.first, let xBufL = xBuffer.last, let yBufF = yBuffer.first, let yBufL = yBuffer.last {
            let disY = yBufF - yBufL
            let disX = xBufF - xBufL
            //print("distances",disX,disY)
            var dir = "none"
            var differentiateFlag = "none"
            
            if abs(disX) > 2.0*abs(disY) {
                differentiateFlag = "horiz"
            }
            
            else {
                differentiateFlag = "vert"
            }
            
            if differentiateFlag == "horiz" {
                if disX <= -0.04 {
                    dir = "right"
                }
                else if disX >= 0.04 {
                    dir = "left"
                }
            }
            else if differentiateFlag == "vert" {
                if disY <= -0.0 {
                    dir = "up"
                }
                else if disY >= 0.02 {
                    dir = "down"
                }
            }
            else {dir = "none"}
                        


            DispatchQueue.main.async {
                if dir != "none" {
                    print("Direction",dir)
                }
            }
        }
    }
}

