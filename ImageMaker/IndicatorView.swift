//
//  IndicatorView.swift
//  ImageMaker
//
//  Created by Serge Sychov on 11/07/2019.
//  Copyright © 2019 Serge Sychov. All rights reserved.
//

import UIKit

class LinearIndicatorView: UIView {
    
    let indicatorColor:UIColor? = nil
    let pieces = 25
    let indentFromSides:CGFloat  = 0.10
    let lineWidth:CGFloat = 1.00
    
    var readyPart = 0.00 {
        didSet (newValue){
            if newValue == 1 {
                self.setNeedsDisplay()
                hideSelfAnimated()
            } else {
                if self.alpha == 0 {
                    showSelfAnimated()
                }
                setAnimation()
            }
        }
    }
    
    func setAnimation(){
        let animationLayerTwo = CAShapeLayer()
        animationLayerTwo.opacity = 0.00
        self.layer.addSublayer(animationLayerTwo)

        animationLayerTwo.path = drawLinearPatchInRect(rct: self.bounds, sideIndetn: indentFromSides, totalPieces: pieces, donePart: readyPart).cgPath
        animationLayerTwo.fillColor = indicatorColor?.cgColor ?? UIColor.white.cgColor
        animationLayerTwo.strokeColor = indicatorColor?.cgColor ?? UIColor.white.cgColor

        let opacityAnimation = CABasicAnimation(keyPath: "opacity")
        opacityAnimation.fromValue = NSNumber.init(value: 0.00)
        opacityAnimation.toValue = NSNumber.init(value: 1.00)
        opacityAnimation.duration = 0.2
        
        animationLayerTwo.add(opacityAnimation, forKey: "opacity")
    }
    

    
    // Only override draw() if you perform custom drawing.
    // An empty implementation adversely affects performance during animation.
    override func draw(_ rect: CGRect) {
        drawInitialIndicatorWithContext(context: UIGraphicsGetCurrentContext()!, rct: rect)
        // Drawing code
    }
    
    
    func drawInitialIndicatorWithContext(context: CGContext, rct: CGRect) {
        
        context.addPath(drawLinearPatchInRect(rct: rct, sideIndetn: indentFromSides, totalPieces: pieces, donePart: 1.00).cgPath)
        context.setLineWidth(lineWidth) //lineWidth
        context.setStrokeColor(indicatorColor?.cgColor ?? UIColor.white.cgColor)
        if (readyPart == 1) {
            context.drawPath(using: .stroke)
            context.drawPath(using: .fill)
        } else {
            context.drawPath(using: .stroke)
        }
        
    }
    
    func drawLinearPatchInRect(rct:CGRect, sideIndetn: CGFloat, totalPieces:Int, donePart:Double) -> UIBezierPath {
        
        let patch = UIBezierPath()
        
        let isHorisontal = rct.width > rct.height ? true : false
        let measure = isHorisontal ? rct.width : rct.height
        let step = measure * (1 - 2*sideIndetn) / CGFloat(totalPieces)
        let radius = step * 2 / 3
        
        let intDone = Int(round(donePart * Double(totalPieces)))
        
        for item in 0...intDone {
            var circleCenter:CGPoint
            var point1:CGPoint
            
            if isHorisontal {
                circleCenter = CGPoint(x: measure * sideIndetn + CGFloat(item) * step, y: rct.height / 2 )
                point1 = circleCenter
                point1.x += radius / 2
            } else {
                circleCenter = CGPoint(x: rct.width / 2 , y: measure * sideIndetn + CGFloat(item) * step)
                point1 = circleCenter
                point1.y += radius / 2
            }
            
            patch.move(to: point1)
            patch.addArc(withCenter: circleCenter, radius: radius/2, startAngle: 0, endAngle: CGFloat(Double.pi * 2), clockwise: true)
        }
        
        return patch
    }
    
    func hideSelfAnimated(){
        UIView.animate(withDuration: 0.6) {
            self.alpha = 0
        }
    }
    
    func showSelfAnimated(){
        UIView.animate(withDuration: 0.6) {
            self.alpha = 1
        }
    }
}

//---------------------------------------------------------------------------------------
//RADIAN INDICATOR VIEW
//_______________________________________________________________________________________
class RadialIndicatorView: UIView {
    
    var indicatorColor:UIColor? = nil

    var lineWidth:CGFloat = 1.00
    
    var readyPart = 0.00 {
        didSet (newValue){
            self.indicatorColor = UIColor.init(white: 1, alpha: CGFloat(newValue))
            self.setNeedsDisplay()
            if newValue == 1 {
                hideSelfAnimated()
            } else {
                if self.alpha == 0 {
                    showSelfAnimated()
                }
            }
        }
    }

    // Only override draw() if you perform custom drawing.
    // An empty implementation adversely affects performance during animation.
    override func draw(_ rect: CGRect) {
        drawInitialIndicatorWithContext(context: UIGraphicsGetCurrentContext()!, rct: rect)
        // Drawing code
    }
    
    
    func drawInitialIndicatorWithContext(context: CGContext, rct: CGRect) {
        
        context.addPath(drawRadianPatchInRect(rct: rct, donePart: readyPart).cgPath)
        context.setLineWidth(rct.width < rct.height ? rct.width / 6 : rct.height / 6) //lineWidth
        context.setLineCap(.round)
        context.setStrokeColor(indicatorColor?.cgColor ?? UIColor.white.cgColor)
        if (readyPart == 1) {
            context.drawPath(using: .stroke)
            context.drawPath(using: .fill)
        } else {
            context.drawPath(using: .stroke)
        }
        
    }
    
    func drawRadianPatchInRect(rct:CGRect, donePart:Double) -> UIBezierPath {
    
        let radiansReady = Double.pi * 2 * donePart
        let squareSide = rct.width < rct.height ? rct.width : rct.height
        let center = CGPoint(x: rct.size.width / 2, y: rct.size.height / 2)
        let radius = squareSide / 3

        let patch = UIBezierPath()
        patch.addArc(withCenter: center, radius: radius, startAngle: CGFloat(Double.pi * 1.5), endAngle: CGFloat(Double.pi * 1.5 + radiansReady), clockwise: true)
        
        return patch
    }
    
    func hideSelfAnimated(){
        UIView.animate(withDuration: 0.6) {
            self.alpha = 0
        }
    }
    
    func showSelfAnimated(){
        UIView.animate(withDuration: 0.6) {
            self.alpha = 1
        }
    }
}
