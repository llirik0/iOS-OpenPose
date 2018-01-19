//
//  ViewController.swift
//  iOSOpenPose
//
//  Created by Eugene Bokhan on 12/31/17.
//  Copyright © 2017 Eugene Bokhan. All rights reserved.
//

import UIKit
import CoreML

class ViewController: UIViewController {
    
    // MARK: - UI Properties
    
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var outputLabel: UILabel!
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }
    
    // MARK: - UI Actions
    
    @IBAction func chooseImageAction(_ sender: Any) {
        
        let camera = CameraViewController(WidthAndHeight: 600) { image in
            
            if (image != nil) {
                DispatchQueue.main.async {
                    MBProgressHUD.showAdded(to: self.view, animated: true)
                }
                DispatchQueue.main.async {
                    self.outputLabel.text = self.measure(self.runCoreML(image!)).duration
                    MBProgressHUD.hide(for: self.view, animated: true)
                }
            }
            
            self.dismiss(animated: true, completion: nil)
        }
        
        self.present(camera, animated: true, completion: nil)
        
    }
    
    // MARK: - CoreML Properties
    let model = MobileOpenPose()
    let ImageWidth = 368
    let ImageHeight = 368

    // MARK: - Lifecycle Methods
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    // MARK: - CoreML Methods
    
    func runCoreML(_ image: UIImage) {
        
        if let pixelBuffer = image.pixelBuffer(width: ImageWidth, height: ImageHeight) {
            
            let startTime = CFAbsoluteTimeGetCurrent()
            if let prediction = try? model.prediction(image: pixelBuffer) {
                
                let timeElapsed = CFAbsoluteTimeGetCurrent() - startTime
                print("coreml elapsed for \(timeElapsed) seconds")
                
                // Display new image
                imageView.image = UIImage(pixelBuffer: pixelBuffer)
                
                let predictionOutput = prediction.net_output
                let length = predictionOutput.count
                print(predictionOutput)
                
                let doublePointer =  predictionOutput.dataPointer.bindMemory(to: Double.self, capacity: length)
                let doubleBuffer = UnsafeBufferPointer(start: doublePointer, count: length)
                let mm = Array(doubleBuffer)
                
                // Delete Beizer paths of previous image
                imageView.layer.sublayers = []
                // Draw new lines
                drawLines(mm)
            }
        }
    }
    
    // MARK: - Drawing
    
    func drawLines(_ mm: Array<Double>){
        
        let poseEstimator = PoseEstimator(ImageWidth,ImageHeight)
        
        let res = measure(poseEstimator.estimate(mm))
        let humans = res.result;
        print("estimate \(res.duration)")
        
        var keypoint = [Int32]()
        var pos = [CGPoint]()
        for human in humans {
            var centers = [Int: CGPoint]()
            for i in 0...CocoPart.Background.rawValue {
                if human.bodyParts.keys.index(of: i) == nil {
                    continue
                }
                let bodyPart = human.bodyParts[i]!
                centers[i] = CGPoint(x: bodyPart.x, y: bodyPart.y)
            }
            
            for (pairOrder, (pair1,pair2)) in CocoPairsRender.enumerated() {
                
                if human.bodyParts.keys.index(of: pair1) == nil || human.bodyParts.keys.index(of: pair2) == nil {
                    continue
                }
                if centers.index(forKey: pair1) != nil && centers.index(forKey: pair2) != nil{
                    keypoint.append(Int32(pairOrder))
                    pos.append(centers[pair1]!)
                    pos.append(centers[pair2]!)
                }
            }
        }
        
        let openCVWrapper = OpenCVWrapper()
        let drawLayer = CALayer()
        drawLayer.frame = imageView.bounds
        drawLayer.opacity = 0.6
        drawLayer.masksToBounds = true
        if let renderedImage = openCVWrapper.renderKeyPoint(imageView.frame,
                                                     keypoint: &keypoint,
                                                     keypoint_size: Int32(keypoint.count),
                                                     pos: &pos) {
            drawLayer.contents = renderedImage.cgImage
        }

        imageView.layer.addSublayer(drawLayer)
        
    } 
    // MARK: - Help Methods
    
    func measure <T> (_ f: @autoclosure () -> T) -> (result: T, duration: String) {
        let startTime = CFAbsoluteTimeGetCurrent()
        let result = f()
        let timeElapsed = CFAbsoluteTimeGetCurrent() - startTime
        return (result, "Elapsed time is \(timeElapsed) seconds.")
    }
    
}

