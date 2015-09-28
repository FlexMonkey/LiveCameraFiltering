//
//  ViewController.swift
//  LiveCameraFiltering
//
//  Created by Simon Gladman on 05/07/2015.
//  Copyright © 2015 Simon Gladman. All rights reserved.
//
// Thanks to: http://www.objc.io/issues/21-camera-and-photos/camera-capture-on-ios/

import UIKit
import AVFoundation
import CoreMedia

class ViewController: UIViewController, AVCaptureVideoDataOutputSampleBufferDelegate
{
    let bumpDistortionFilter = CIFilter(name: "CIBumpDistortion")!
    let imageView = UIImageView(frame: CGRectZero)
    
    typealias TouchInfo = (location: CGPoint, force: CGFloat)
    
    var touchInfo = TouchInfo(location: CGPointZero, force: 0)
    
    override func viewDidLoad()
    {
        super.viewDidLoad()
        
        view.addSubview(imageView)
        
        imageView.contentMode = UIViewContentMode.ScaleAspectFit
        
        let captureSession = AVCaptureSession()
        captureSession.sessionPreset = AVCaptureSessionPreset1280x720
        
        let backCamera = AVCaptureDevice.defaultDeviceWithMediaType(AVMediaTypeVideo)
        
        do
        {
            let input = try AVCaptureDeviceInput(device: backCamera)
            
            captureSession.addInput(input)
        }
        catch
        {
            print("can't access camera")
            return
        }
        
        // although we don't use this, it's required to get captureOutput invoked
        let previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
        view.layer.addSublayer(previewLayer)
        
        let videoOutput = AVCaptureVideoDataOutput()
        
        videoOutput.setSampleBufferDelegate(self, queue: dispatch_queue_create("sample buffer delegate", DISPATCH_QUEUE_SERIAL))
        if captureSession.canAddOutput(videoOutput)
        {
            captureSession.addOutput(videoOutput)
        }
        
        captureSession.startRunning()
    }
    
    override func touchesMoved(touches: Set<UITouch>, withEvent event: UIEvent?)
    {
        super.touchesMoved(touches, withEvent: event)
        
        guard let touch = touches.first else
        {
            return
        }
        
        let touchLocation = touch.locationInView(self.view)
        let force = touch.force
        let maximumPossibleForce = touch.maximumPossibleForce
        
        let normalisedXPosition = touchLocation.x / view.frame.width
        let normalisedYPosition = 1 - touchLocation.y / view.frame.height
        let normalisedZPosition = force / maximumPossibleForce
        
        touchInfo = TouchInfo(location: CGPoint(x: normalisedXPosition, y: normalisedYPosition),
            force: normalisedZPosition)
    }
    
    override func touchesEnded(touches: Set<UITouch>, withEvent event: UIEvent?)
    {
        super.touchesEnded(touches, withEvent: event)
        
        touchInfo = TouchInfo(location: CGPointZero, force: 0)
    }
    
    func captureOutput(captureOutput: AVCaptureOutput!, didOutputSampleBuffer sampleBuffer: CMSampleBuffer!, fromConnection connection: AVCaptureConnection!)
    {
        let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer)
        let cameraImage = CIImage(CVPixelBuffer: pixelBuffer!)
        
        bumpDistortionFilter.setValue(cameraImage, forKey: kCIInputImageKey)
        bumpDistortionFilter.setValue(CIVector(x: 1280 * touchInfo.location.x, y: 640 * touchInfo.location.y), forKey: kCIInputCenterKey)
        bumpDistortionFilter.setValue(-touchInfo.force * 5, forKey: kCIInputScaleKey)
        bumpDistortionFilter.setValue(250, forKey: kCIInputRadiusKey)
        
        let filteredImage = UIImage(CIImage: bumpDistortionFilter.valueForKey(kCIOutputImageKey) as! CIImage!)
        
        dispatch_async(dispatch_get_main_queue())
            {
                self.imageView.image = filteredImage
        }
        
    }
    
    override func supportedInterfaceOrientations() -> UIInterfaceOrientationMask
    {
        return UIInterfaceOrientationMask.Landscape
    }
    
    override func viewDidLayoutSubviews()
    {
        let topMargin = topLayoutGuide.length
        
        imageView.frame = CGRect(x: 0,
            y: topMargin,
            width: view.frame.width,
            height: view.frame.height - topMargin).insetBy(dx: 5, dy: 5)
    }
    
}


