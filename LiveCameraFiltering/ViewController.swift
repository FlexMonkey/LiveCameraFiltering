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
    let comicEffect = CIFilter(name: "CIComicEffect")
    
    let imageView = UIImageView(frame: CGRectZero)
    
    override func viewDidLoad()
    {
        super.viewDidLoad()
        
        view.addSubview(imageView)
        
        let captureSession = AVCaptureSession()
        captureSession.sessionPreset = AVCaptureSessionPresetPhoto
        
        
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
    
    func captureOutput(captureOutput: AVCaptureOutput!, didOutputSampleBuffer sampleBuffer: CMSampleBuffer!, fromConnection connection: AVCaptureConnection!)
    {
        let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer)
        let cameraImage = CIImage(CVPixelBuffer: pixelBuffer!)
        
        comicEffect!.setValue(cameraImage, forKey: kCIInputImageKey)
        
        let filteredImage = UIImage(CIImage: comicEffect!.valueForKey(kCIOutputImageKey) as! CIImage!)
        
        dispatch_async(dispatch_get_main_queue())
            {
                self.imageView.image = filteredImage
        }
        
    }
    
    override func viewDidLayoutSubviews()
    {
        imageView.frame = view.bounds.rectByInsetting(dx: 30, dy: 30)
    }
    
}


