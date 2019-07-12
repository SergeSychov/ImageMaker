//
//  IndicatorView.swift
//  ImageMaker
//
//  Created by Serge Sychov on 11/07/2019.
//  Copyright © 2019 Serge Sychov. All rights reserved.
//

import UIKit

class IndicatorView: UIView {
    
    let indicatorColor:UIColor? = nil
    let pieces = 25
    let indent:CGFloat  = 0.10
    
    var readyPart = 0.00 {
        didSet {
            setAnimation()
        }
    }
    
    var animationLayer:CAShapeLayer? = nil
    func setAnimation(){
        //if animationLayer == nil {
        let animationLayerTwo = CAShapeLayer()
        animationLayerTwo.opacity = 0.00
        self.layer.addSublayer(animationLayerTwo)
        //}
        
        let rct = self.bounds
        
        let isHorisontal = rct.width > rct.height ? true : false
        let measure = rct.width > rct.height ? rct.width : rct.height
        
        let step = measure * (1 - 2*indent) / CGFloat(pieces)
        
        //UIColor *fillColor = self.superview.backgroundColor;
        let lineWidth = step * 2 / 3
        animationLayerTwo.lineWidth = 1.0
        animationLayerTwo.fillColor = indicatorColor?.cgColor ?? UIColor.white.cgColor//??  UIColor.white.cgColor
        animationLayerTwo.strokeColor = indicatorColor?.cgColor ?? UIColor.white.cgColor
        
        let patch = UIBezierPath()
        
        let intDone = Int(round(readyPart * Double(pieces)))
        
        for item in 0...intDone {
            let circleCenter = CGPoint(x: measure * indent + CGFloat(item) * step, y: rct.height / 2 )
            var point1 = circleCenter
            point1.x += lineWidth / 2

            patch.move(to: point1)
            patch.addArc(withCenter: circleCenter, radius: lineWidth/2, startAngle: 0, endAngle: CGFloat(Double.pi * 2), clockwise: true)
            
        }
        
        animationLayerTwo.path = patch.cgPath
        
        let opacityAnimation = CABasicAnimation(keyPath: "opacity")
        opacityAnimation.fromValue = NSNumber.init(value: 0.00)
        opacityAnimation.toValue = NSNumber.init(value: 1.00)
        opacityAnimation.duration = 0.2
        
        animationLayerTwo.add(opacityAnimation, forKey: "opacity")
        
    }
    
    
    func drawIndicatorWithContext(context: CGContext, rct: CGRect) {
        
        let isHorisontal = rct.width > rct.height ? true : false
        let measure = isHorisontal ? rct.width : rct.height
        
        
        let step = measure * (1 - 2*indent) / CGFloat(pieces)

        let lineWidth = step * 2 / 3
        context.setLineWidth(1.00) //lineWidth
        //context.setLineJoin(.round)
        context.setLineCap(.round)
        context.setStrokeColor(indicatorColor?.cgColor ?? UIColor.white.cgColor)
        
        let patch = UIBezierPath()
        for item in 0...pieces {
            let circleCenter = CGPoint(x: measure * indent + CGFloat(item) * step, y: rct.height / 2 )
            var point1 = circleCenter
            point1.x += lineWidth / 2
            
            patch.move(to: point1)
            patch.addArc(withCenter: circleCenter, radius: lineWidth/2, startAngle: 0, endAngle: CGFloat(Double.pi * 2), clockwise: true)
        }
        context.addPath(patch.cgPath)
        context.drawPath(using: .stroke)
        
    }
    
    // Only override draw() if you perform custom drawing.
    // An empty implementation adversely affects performance during animation.
    override func draw(_ rect: CGRect) {
        drawIndicatorWithContext(context: UIGraphicsGetCurrentContext()!, rct: rect)
        // Drawing code
    }
    

}
