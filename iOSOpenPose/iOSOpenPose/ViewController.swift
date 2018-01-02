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
    
    let drawLayer = CALayer()
    
    // MARK: - UI Actions
    
    @IBAction func chooseImageAction(_ sender: Any) {
        
        let camera = CameraViewController(WidthAndHeight: 600) { image in
            
            if (image != nil){
                self.outputLabel.text = self.measure(self.runCoreML(image!)).duration
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
        
        self.view.layer.addSublayer(drawLayer)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    // MARK: - CoreML Methods
    
    func runCoreML(_ image: UIImage) {
        
        if let pixelBuffer = image.pixelBuffer(width: ImageWidth, height: ImageHeight) {
            
            let startTime2 = CFAbsoluteTimeGetCurrent()
            if let prediction = try? model.prediction(image: pixelBuffer) {
                
                let timeElapsed2 = CFAbsoluteTimeGetCurrent() - startTime2
                print("coreml elapsed for \(timeElapsed2) seconds")
                
                // view
                imageView.image = UIImage(pixelBuffer: pixelBuffer)
                
                //                let pred = prediction.MConv_Stage7_concat
                let pred = prediction.net_output
                let length = pred.count
                //                print(length)
                print(pred)
                
                let doublePtr =  pred.dataPointer.bindMemory(to: Double.self, capacity: length)
                let doubleBuffer = UnsafeBufferPointer(start: doublePtr, count: length)
                let mm = Array(doubleBuffer)
                
                drawLayer.sublayers = []
                
                drewLine(mm)
            }
        }
    }
    
    // MARK: - Drawing
    
    func drewLine(_ mm: Array<Double>){
        
        let com = Common(ImageWidth,ImageHeight)
        
        let h = imageView.image?.size.height
        let imageH = Int(h!)
        let w = imageView.image?.size.width
        let imageW = Int(w!)
        
        let heatH = ImageHeight / 8
        let heatW = ImageWidth / 8
        
        let res = measure(com.estimatePose(mm))
        let connections = res.result;
        print("estimate_pose \(res.duration)")
        
        let CocoPairsRender = com.cocoPairs[0..<com.cocoPairs.count-2]
        
        for human in connections.values {
            for (partIdx, part) in human.enumerated() {
                
                if !CocoPairsRender.contains(part.partIdx){
                    continue
                }
                
                let center1 = CGPoint(x: Int(Int(part.c1.0) * imageW / heatW), y: Int(Int(part.c1.1) * imageH / heatH))
                let center2 = CGPoint(x: Int(Int(part.c2.0) * imageW / heatW), y: Int(Int(part.c2.1) * imageH / heatH))
                
                if let color: UIColor = com.cocoColors[safe: partIdx] {
                    addLine(fromPoint: center1, toPoint: center2, color: color)
                }
            }
        }
    }
    
    func addLine(fromPoint start: CGPoint, toPoint end:CGPoint, color: UIColor) {
        let line = CAShapeLayer()
        let linePath = UIBezierPath()
        linePath.move(to: CGPoint(start.x + imageView.frame.origin.x, start.y + imageView.frame.origin.y))
        linePath.addLine(to: CGPoint(end.x + imageView.frame.origin.x, end.y + imageView.frame.origin.y))
        line.path = linePath.cgPath
        line.strokeColor = color.cgColor
        line.lineWidth = 3
        line.lineJoin = kCALineJoinRound
        drawLayer.addSublayer(line)
    }
    
    // MARK: - Help Methods
    
    func measure <T> (_ f: @autoclosure () -> T) -> (result: T, duration: String) {
        let startTime = CFAbsoluteTimeGetCurrent()
        let result = f()
        let timeElapsed = CFAbsoluteTimeGetCurrent() - startTime
        return (result, "Elapsed time is \(timeElapsed) seconds.")
    }
    
    func runJsonFile(_ image: UIImage) {
        imageView.image = image
        
        let url = Bundle.main.url(forResource: "hadou", withExtension: "bin")!
        let text2 = try? String(contentsOf: url, encoding: .utf8)
        let personalData: Data = text2!.data(using: String.Encoding.utf8)!
        let json = try? JSONSerialization.jsonObject(with: personalData, options: [])
        
        if let array = json as? [Double] {
            
            var m: Array<Double> = Array()
            for i in 0..<array.count {
                m.append(Double(array[i]))
            }
            
            drewLine(m)
        }
    }
    
}

