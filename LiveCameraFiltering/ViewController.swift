//
//  ViewController.swift
//  LiveCameraFiltering
//
//  Created by Simon Gladman on 05/07/2015.
//	Updated to Swift 4 by Daniel Illescas Romero on June 10th, 2017
//  Copyright © 2015 Simon Gladman. All rights reserved.
//
// Thanks to: http://www.objc.io/issues/21-camera-and-photos/camera-capture-on-ios/

import UIKit
import AVFoundation
import CoreMedia

let CMYKHalftone = "CMYK Halftone"
let CMYKHalftoneFilter = CIFilter(name: "CICMYKHalftone", withInputParameters: ["inputWidth" : 20, "inputSharpness": 1])

let ComicEffect = "Comic Effect"
let ComicEffectFilter = CIFilter(name: "CIComicEffect")

let Crystallize = "Crystallize"
let CrystallizeFilter = CIFilter(name: "CICrystallize", withInputParameters: ["inputRadius" : 30])

let Edges = "Edges"
let EdgesEffectFilter = CIFilter(name: "CIEdges", withInputParameters: ["inputIntensity" : 10])

let HexagonalPixellate = "Hex Pixellate"
let HexagonalPixellateFilter = CIFilter(name: "CIHexagonalPixellate", withInputParameters: ["inputScale" : 40])

let Invert = "Invert"
let InvertFilter = CIFilter(name: "CIColorInvert")

let Pointillize = "Pointillize"
let PointillizeFilter = CIFilter(name: "CIPointillize", withInputParameters: ["inputRadius" : 30])

let LineOverlay = "Line Overlay"
let LineOverlayFilter = CIFilter(name: "CILineOverlay")

let Posterize = "Posterize"
let PosterizeFilter = CIFilter(name: "CIColorPosterize", withInputParameters: ["inputLevels" : 5])

let Filters = [
    CMYKHalftone: CMYKHalftoneFilter,
    ComicEffect: ComicEffectFilter,
    Crystallize: CrystallizeFilter,
    Edges: EdgesEffectFilter,
    HexagonalPixellate: HexagonalPixellateFilter,
    Invert: InvertFilter,
    Pointillize: PointillizeFilter,
    LineOverlay: LineOverlayFilter,
    Posterize: PosterizeFilter
]

let FilterNames = [String](Filters.keys).sorted()

class ViewController: UIViewController, AVCaptureVideoDataOutputSampleBufferDelegate {
	
	@IBOutlet weak var mainGroup: UIStackView!
	@IBOutlet weak var imageView: UIImageView!
	@IBOutlet weak var filtersControl: UISegmentedControl!
    
    override func viewDidLoad() {
		
        super.viewDidLoad()
		
		filtersControl.removeAllSegments()
		
		for filterName in FilterNames {
			filtersControl.insertSegment(withTitle: filterName, at: filtersControl.numberOfSegments, animated: false)
		}
		filtersControl.selectedSegmentIndex = 0
        
        let captureSession = AVCaptureSession()
        captureSession.sessionPreset = AVCaptureSession.Preset.photo
		
		guard let captureDevice = AVCaptureDevice.default(for: .video), let input = try? AVCaptureDeviceInput(device: captureDevice) else {
			print("Can't access the camera")
			return
		}
		
		if captureSession.canAddInput(input) {
			captureSession.addInput(input)
		}
        
        let videoOutput = AVCaptureVideoDataOutput()
		
        videoOutput.setSampleBufferDelegate(self, queue: DispatchQueue.main)
        if captureSession.canAddOutput(videoOutput) {
            captureSession.addOutput(videoOutput)
        }
		
		let previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
		view.layer.addSublayer(previewLayer)
        
        captureSession.startRunning()
    }
    
    func captureOutput(_ captureOutput: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
		
		DispatchQueue.main.async {
			
			switch UIApplication.shared.statusBarOrientation {
			case .landscapeLeft:
				connection.videoOrientation = .landscapeLeft
			case .landscapeRight:
				connection.videoOrientation = .landscapeRight
			default:
				connection.videoOrientation = .portrait
			}
			
			if let filter = Filters[FilterNames[self.filtersControl.selectedSegmentIndex]] {
				
				guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }
				let cameraImage = CIImage(cvPixelBuffer: pixelBuffer)
				
				filter?.setValue(cameraImage, forKey: kCIInputImageKey)
				
				if let outputValue = filter?.value(forKey: kCIOutputImageKey) as? CIImage {
					
					let filteredImage = UIImage(ciImage: outputValue)
					self.imageView.image = filteredImage
				}
			}
		}
    }
}
