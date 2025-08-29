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
var globalDir: String = "none"

class CameraViewController: UIViewController, AVCaptureVideoDataOutputSampleBufferDelegate {
    var captureSession: AVCaptureSession!
    var previewLayer: AVCaptureVideoPreviewLayer!
    let HandPoseReq = VNDetectHumanHandPoseRequest()
    let overlayView = UIView()
    let maxFrames = 25
    var xBuffer = [CGFloat]()
    var yBuffer = [CGFloat]()
    var vXTBuffer = [CGFloat]()
    var vYTBuffer = [CGFloat]()
    var vXMBuffer = [CGFloat]()
    var vYMBuffer = [CGFloat]()
    var prevDir = "none"
    var dir = "none"
    var prevX = 0.0
    var prevY = 0.0
    var prevXT = 0.0
    var prevXM = 0.0
    var prevYT = 0.0
    var prevYM = 0.0
    var prevprevX = 0.0
    var prevprevY = 0.0
    
    var onDirectionUpdate: ((String) -> Void)?

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
                    
                    let vX = (indexT.location.x+indexM.location.x)/2.0-prevprevX
                    let vY = (indexT.location.y+indexM.location.y)/2.0-prevprevY
                    let vXT = indexT.location.x - prevXT
                    let vXM = indexM.location.x - prevXM
                    let vYT = indexT.location.y - prevYT
                    let vYM = indexM.location.y - prevYM
                    let totVel = pow(pow(vX,2.0)+pow(vY,2.0),0.5)
                    //print("Current",index.location.x,index.location.y)
                    //print("Previous",prevX,prevY)
                    //print("Velocity",vX,vY,totVel)
                    if totVel > 0.035 && indexM.location.x > 0.2 && indexM.location.x < 0.8  && indexM.location.y > 0.0 && indexM.location.y < 0.6 {
                    //if totVel > 0.035 {
                            //print("Buffer Count:", xBuffer.count+1)
                        xBuffer.append(((indexT.location.x+indexM.location.x)/2.0+prevX+prevprevX)/3.0)
                        yBuffer.append(((indexT.location.y+indexM.location.y)/2.0+prevY+prevprevY)/3.0)
                        vXTBuffer.append(vXT)
                        vYTBuffer.append(vYT)
                        vXMBuffer.append(vXM)
                        vYMBuffer.append(vYM)
                        //print("XBuffer",xBuffer)
                        //print("YBuffer",yBuffer)
                        prevX = (indexT.location.x+indexM.location.x)/2.0
                        prevY = (indexT.location.y+indexM.location.y)/2.0
                        prevprevX = prevX
                        prevprevY = prevY
                        prevXT = indexT.location.x
                        prevYT = indexT.location.y
                        prevXM = indexM.location.x
                        prevYM = indexM.location.y

                        if xBuffer.count > maxFrames {
                            xBuffer.removeFirst(xBuffer.count - maxFrames)
                        }
                        
                        if yBuffer.count > maxFrames{
                            yBuffer.removeFirst(yBuffer.count - maxFrames)
                        }
                        
                    }
                    else {
                        
                        if xBuffer.count > 3 && yBuffer.count > 3 {
                            Detecting(xBuffer: xBuffer, yBuffer: yBuffer, vXTBuffer: vXTBuffer, vYTBuffer: vYTBuffer, vXMBuffer: vXMBuffer, vYMBuffer: vYMBuffer)
                        }

                        xBuffer.removeAll()
                        yBuffer.removeAll()
                        vXTBuffer.removeAll()
                        vYTBuffer.removeAll()
                        vXMBuffer.removeAll()
                        vYMBuffer.removeAll()
                    }
                }
                else {
                    if xBuffer.count > 3 && yBuffer.count > 3 {
                        Detecting(xBuffer: xBuffer, yBuffer: yBuffer, vXTBuffer: vXTBuffer, vYTBuffer: vYTBuffer, vXMBuffer: vXMBuffer, vYMBuffer: vYMBuffer)
                    }
                    xBuffer.removeAll()
                    yBuffer.removeAll()
                    vXTBuffer.removeAll()
                    vYTBuffer.removeAll()
                    vXMBuffer.removeAll()
                    vYMBuffer.removeAll()
                }
            }
        }
    }

    func Detecting(xBuffer: Array<CGFloat>, yBuffer: Array<CGFloat>, vXTBuffer: Array<CGFloat>, vYTBuffer: Array<CGFloat>, vXMBuffer: Array<CGFloat>, vYMBuffer: Array<CGFloat>) {
        if let xBufF = xBuffer.first, let xBufL = xBuffer.last, let yBufF = yBuffer.first, let yBufL = yBuffer.last {
            let disY = yBufF - yBufL
            let disX = xBufF - xBufL
            //print("distances",disX,disY)
            var differentiateFlag = "none"
            
            if abs(disX) > 2.0*abs(disY) {
                differentiateFlag = "horiz"
            }
            
            else {
                differentiateFlag = "vert"
            }
            
            if differentiateFlag == "horiz" {
                if disX <= -0.03 && xBuffer[0] < xBuffer[1] && xBuffer[1] < xBuffer[2] {
                    dir = "right"
                }
                else if disX >= 0.06 && xBuffer[0] > xBuffer[1] && xBuffer[1] > xBuffer[2] {
                    dir = "left"
                }
                else {
                    dir = "none"
                }
            }
            else if differentiateFlag == "vert" {
                if disY <= -0.0 && yBuffer[0] < yBuffer[1] && yBuffer[1] < yBuffer[2] {
                    dir = "up"
                }
                else if disY >= 0.0 && yBuffer[0] > yBuffer[1] && yBuffer[1] > yBuffer[2] {
                    dir = "down"
                }
                else {
                    dir = "none"
                }
            }
            else {dir = "none"}
                        

//
            DispatchQueue.main.async {
                if self.dir != "none" {
                    self.onDirectionUpdate?(self.dir)
//                    print("Direction",self.dir)
                }
            }
        }
    }
}

