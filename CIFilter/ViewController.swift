//
//  ViewController.swift
//  CIFilter
//
//  Created by Muis on 25/07/20.
//  Copyright © 2020 Muis. All rights reserved.
//

import Cocoa

class ViewController: NSViewController {
    
    private lazy var imageUrl = Bundle.main.urlForImageResource("image-to-test-ci-filter")!
    private lazy var nsImage = NSImage(imageLiteralResourceName: "image-to-test-ci-filter")
    
    private var filters: [String:CIFilter] = [:]
    
    @IBOutlet weak var imageView: NSImageView!
    
    @IBAction func applyAllFilters(_ sender: Any) {
        guard var ciimage = CIImage(contentsOf: imageUrl) else { return }
        for filter in filters.values {
            filter.setValue(ciimage, forKey: kCIInputImageKey)
            ciimage = filter.outputImage!
        }
        
        guard let cgImage = ciContext
            .createCGImage(ciimage, from: ciimage.extent)
            else { fatalError() }
        
        imageView.image = NSImage(cgImage: cgImage, size: nsImage.size)
    }
    
    @IBAction func resetFilters(_ sender: Any) {
        brightnessSliderControl.floatValue = 0.0
        brightnessSlider(brightnessSliderControl)
        contrastSliderControl.floatValue = 0.25
        contrastSlider(contrastSliderControl)
        saturationSliderControl.floatValue = 0.0
        saturationSlider(saturationSliderControl)
        imageView.image = nsImage
        filters = [:]
    }
    
    // MARK: Brightness
    
    @IBOutlet weak var brightnessValue: NSTextField!
    @IBOutlet weak var brightnessSliderControl: NSSlider!
    @IBAction func brightnessSlider(_ sender: NSSlider) {
        brightnessValue.stringValue = sender.stringValue
        let filter = CIFilter(name: "CIColorControls")!
        filter.setValue(CIImage(contentsOf: imageUrl), forKey: kCIInputImageKey)
        filter.setValue(sender.floatValue, forKey: kCIInputBrightnessKey)
        
        filters["brightness"] = filter
        
        let ciImage = filter.outputImage!
        
        guard let cgImage = ciContext
            .createCGImage(ciImage, from: ciImage.extent)
            else { fatalError() }
        
        imageView.image = NSImage(cgImage: cgImage, size: nsImage.size)
    }
    
    // MARK: Contrast
    
    @IBOutlet weak var contrastValue: NSTextField!
    
    @IBOutlet weak var contrastSliderControl: NSSlider!
    
    @IBAction func contrastSlider(_ sender: NSSlider) {
        contrastValue.stringValue = sender.stringValue
        let filter = CIFilter(name: "CIColorControls")!
        filter.setValue(CIImage(contentsOf: imageUrl), forKey: kCIInputImageKey)
        filter.setValue(sender.floatValue, forKey: kCIInputContrastKey)
        
        filters["contrast"] = filter
        
        let ciImage = filter.outputImage!
        
        guard let cgImage = ciContext
            .createCGImage(ciImage, from: ciImage.extent)
            else { fatalError() }
        
        imageView.image = NSImage(cgImage: cgImage, size: nsImage.size)
    }
    
    // MARK: Saturation
    
    @IBOutlet weak var saturationValue: NSTextField!
    @IBOutlet weak var saturationSliderControl: NSSlider!
    @IBAction func saturationSlider(_ sender: NSSlider) {
        saturationValue.stringValue = sender.stringValue
        let filter = CIFilter(name: "CIColorControls")!
        filter.setValue(CIImage(contentsOf: imageUrl), forKey: kCIInputImageKey)
        filter.setValue(sender.floatValue, forKey: kCIInputSaturationKey)
        
        filters["saturation"] = filter
        
        let ciImage = filter.outputImage!
        
        guard let cgImage = ciContext
            .createCGImage(ciImage, from: ciImage.extent)
            else { fatalError() }
        
        imageView.image = NSImage(cgImage: cgImage, size: nsImage.size)
    }
    
    @IBAction func tiltShift(_ sender: Any) {
        let filter = TiltShiftFilter()
        filter.setValue(CIImage(contentsOf: imageUrl),
                        forKey: kCIInputImageKey)
        filter.setValue(CIVector(cgPoint: CGPoint(x: nsImage.size.width * 0.5,
                                                  y: nsImage.size.height * 0.5)),
                        forKey: "inputCenter")
        filters["tiltShift"] = filter
        
        let ciImage = filter.outputImage!
        
        guard let cgImage = ciContext
            .createCGImage(ciImage, from: ciImage.extent)
            else { fatalError() }
        
        imageView.image = NSImage(cgImage: cgImage, size: nsImage.size)
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
