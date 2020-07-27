//
//  ViewController.swift
//  CIFilter
//
//  Created by Muis on 25/07/20.
//  Copyright © 2020 Muis. All rights reserved.
//

import Cocoa
import GPUImage

class ViewController: NSViewController {
    
    private lazy var imageUrl = Bundle.main.urlForImageResource("image-to-test-ci-filter")!
    
    private var ciFilters: [String:CIFilter] = [:]
    private var gpuFilters: [String:ImageProcessingOperation] = [:]
    
    
    
    @IBOutlet weak var ciFilterImageView: NSImageView!
    @IBOutlet weak var gpuFilterImageView: NSImageView!
    
    @IBAction func applyAllFilters(_ sender: Any) {
        guard var ciimage = CIImage(contentsOf: imageUrl) else { return }
        guard let sourceImage = NSImage(contentsOf: imageUrl) else { return }
        
        do {
            for filter in ciFilters.values {
                filter.setValue(ciimage, forKey: kCIInputImageKey)
                ciimage = filter.outputImage!
            }
            
            guard let cgImage = ciContext
                .createCGImage(ciimage, from: ciimage.extent)
                else { fatalError() }
            
            ciFilterImageView.image = NSImage(cgImage: cgImage, size: sourceImage.size)
        }
        
        do {
            
            var image = sourceImage
            
            class OPS<T>: ImageProcessingOperation {
                private let ops: ImageProcessingOperation
                init(_ ops: T) {
                    self.ops = ops as! ImageProcessingOperation
                }
                
                var maximumInputs: UInt { ops.maximumInputs }
                
                var sources: SourceContainer { ops.sources }
                
                func newFramebufferAvailable(_ framebuffer: Framebuffer, fromSourceIndex: UInt) {
                    ops.newFramebufferAvailable(framebuffer, fromSourceIndex: fromSourceIndex)
                }
                
                var targets: TargetContainer { ops.targets }
                
                func transmitPreviousImage(to target: ImageConsumer, atIndex: UInt) {
                    ops.transmitPreviousImage(to: target, atIndex: atIndex)
                }
                
                
            }
            
            for filter in gpuFilters.values {
                let ops = OPS(filter)
                image = image.filterWithOperation(ops)
            }
            
            gpuFilterImageView.image = image
        }
    }
    
    @IBAction func resetFilters(_ sender: Any) {
        guard let sourceImage = NSImage(contentsOf: imageUrl) else { return }
        
        brightnessSliderControl.floatValue = 0.0
        brightnessSlider(brightnessSliderControl)
        contrastSliderControl.floatValue = 1.0
        contrastSlider(contrastSliderControl)
        saturationSliderControl.floatValue = 1.0
        saturationSlider(saturationSliderControl)
        ciFilterImageView.image = sourceImage
        gpuFilterImageView.image = sourceImage
        ciFilters = [:]
        gpuFilters = [:]
    }
    
    // MARK: Brightness
    
    @IBOutlet weak var brightnessValue: NSTextField!
    @IBOutlet weak var brightnessSliderControl: NSSlider!
    @IBAction func brightnessSlider(_ sender: NSSlider) {
        guard let sourceImage = NSImage(contentsOf: imageUrl) else { return }
        brightnessValue.stringValue = sender.stringValue
        
        do {
            //            let filter = CIFilter(name: "CIColorControls")!
            let filter = BrightnessFilter()
            filter.setValue(CIImage(contentsOf: imageUrl), forKey: kCIInputImageKey)
            filter.setValue(sender.floatValue, forKey: kCIInputBrightnessKey)
            
            ciFilters["brightness"] = filter
            
            let ciImage = filter.outputImage!
            
            guard let cgImage = ciContext
                .createCGImage(ciImage, from: ciImage.extent)
                else { fatalError() }
            
            ciFilterImageView.image = NSImage(cgImage: cgImage, size: sourceImage.size)
        }
        
        do {
            let filter = BrightnessAdjustment()
            filter.brightness = sender.floatValue
            gpuFilters["brightness"] = filter
            
            gpuFilterImageView.image = sourceImage.filterWithOperation(filter)
        }
    }
    
    // MARK: Contrast
    
    @IBOutlet weak var contrastValue: NSTextField!
    
    @IBOutlet weak var contrastSliderControl: NSSlider!
    
    @IBAction func contrastSlider(_ sender: NSSlider) {
        guard let sourceImage = NSImage(contentsOf: imageUrl) else { return }
        
        contrastValue.stringValue = sender.stringValue
        
        do {
            let filter = CIFilter(name: "CIColorControls")!
            filter.setValue(CIImage(contentsOf: imageUrl), forKey: kCIInputImageKey)
            filter.setValue(sender.floatValue, forKey: kCIInputContrastKey)
            
            ciFilters["contrast"] = filter
            
            let ciImage = filter.outputImage!
            
            guard let cgImage = ciContext
                .createCGImage(ciImage, from: ciImage.extent)
                else { fatalError() }
            
            ciFilterImageView.image = NSImage(cgImage: cgImage, size: sourceImage.size)
        }
        
        do {
            let filter = ContrastAdjustment()
            filter.contrast = sender.floatValue
            gpuFilters["contrast"] = filter
            
            gpuFilterImageView.image = sourceImage.filterWithOperation(filter)
        }
    }
    
    // MARK: Saturation
    
    @IBOutlet weak var saturationValue: NSTextField!
    @IBOutlet weak var saturationSliderControl: NSSlider!
    @IBAction func saturationSlider(_ sender: NSSlider) {
        guard let sourceImage = NSImage(contentsOf: imageUrl) else { return }
        
        saturationValue.stringValue = sender.stringValue
        
        do {
            let filter = CIFilter(name: "CIColorControls")!
            filter.setValue(CIImage(contentsOf: imageUrl), forKey: kCIInputImageKey)
            filter.setValue(sender.floatValue, forKey: kCIInputSaturationKey)
            
            ciFilters["saturation"] = filter
            
            let ciImage = filter.outputImage!
            
            guard let cgImage = ciContext
                .createCGImage(ciImage, from: ciImage.extent)
                else { fatalError() }
            
            ciFilterImageView.image = NSImage(cgImage: cgImage, size: sourceImage.size)
        }
        
        do {
            let filter = SaturationAdjustment()
            filter.saturation = sender.floatValue
            gpuFilters["saturation"] = filter
            
            gpuFilterImageView.image = sourceImage.filterWithOperation(filter)
        }
    }
    
    @IBAction func tiltShift(_ sender: Any) {
        guard let sourceImage = NSImage(contentsOf: imageUrl) else { return }
        
        do {
            let filter = TiltShiftFilter()
            filter.setValue(CIImage(contentsOf: imageUrl),
                            forKey: kCIInputImageKey)
            filter.setValue(
                CIVector(
                    cgPoint: CGPoint(
                        x: sourceImage.size.width * 0.5,
                        y: sourceImage.size.height * 0.5)),
                forKey: "inputCenter")
            ciFilters["tiltShift"] = filter
            
            let ciImage = filter.outputImage!
            
            guard let cgImage = ciContext
                .createCGImage(ciImage, from: ciImage.extent)
                else { fatalError() }
            
            ciFilterImageView.image = NSImage(cgImage: cgImage, size: sourceImage.size)
            
        }
        
        do {
            let filter = GPUImage.TiltShift()
            gpuFilters["tiltShift"] = filter
            
            gpuFilterImageView.image = sourceImage.filterWithOperation(filter)
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        resetFilters(NSObject())
    }
    
    override var representedObject: Any? {
        didSet {
            // Update the view, if already loaded.
        }
    }
    
    private lazy var ciContext = CIContext()
}

final class TiltShiftFilter: CIFilter {
    @objc dynamic var inputImage: CIImage?
    @objc dynamic var inputCenter: CIVector?
    
    override var outputImage: CIImage? {
        guard let inputImage = inputImage else {
            fatalError()
        }
        guard let point = inputCenter else {
            fatalError()
        }
        
        let blurEffect = CIFilter(name: "CIGaussianBlur")!
        blurEffect.setValue(inputImage.clampedToExtent(),
                            forKey: kCIInputImageKey)
        blurEffect.setValue(5.0, forKey: kCIInputRadiusKey)
        
        
        let radialGradient = CIFilter(name: "CIRadialGradient")!
        radialGradient.setValue(point, forKey: "inputCenter")
        radialGradient.setValue(NSNumber(value: 250), forKey: "inputRadius0")
        radialGradient.setValue(NSNumber(value: 125), forKey: "inputRadius1")
        
        let blend = CIFilter(name: "CIBlendWithMask")!
        blend.setValue(blurEffect.outputImage!, forKey: kCIInputImageKey)
        blend.setValue(inputImage, forKey: kCIInputBackgroundImageKey)
        blend.setValue(radialGradient.outputImage!, forKey: kCIInputMaskImageKey)
        return blend.outputImage?.cropped(to: inputImage.extent)
    }
}

final class BrightnessFilter: CIFilter {
    @objc var inputImage: CIImage?
    @objc var inputBrightness: NSNumber?
    
    private lazy var kernel: CIColorKernel? = {
        let name = "Brightness.cikernel"
            .split(separator: ".")
            .map({ String($0) })
        guard let path = Bundle.main.path(forResource: name[0],
                                          ofType: name[1]),
            let code = try? String(contentsOfFile: path) else {
                fatalError("Failed to load \(name.joined(separator: ".")) from bundle")
        }
        let kernel = CIColorKernel(source: code)
        return kernel
    }()
    
    override var outputImage: CIImage? {
        guard let inputImage = inputImage else {
            fatalError()
        }
        guard let brightness = inputBrightness else {
            fatalError()
        }
        
        return kernel?.apply(
            extent: inputImage.extent,
            arguments: [
                inputImage,
                brightness
        ])
    }
}
