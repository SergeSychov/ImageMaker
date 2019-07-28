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
    let lineWidth:CGFloat = 1.0
    let minPiecesQnty = 5 //min value of pieces of indicat

    var isHorisontal:Bool?
    var pieceSize:CGSize?
    var pieceRadius: CGFloat?
    var totalPiecesQuantity:Int?
    var donePieces:Int = 0
    
    func setMeasures(rect: CGRect){
        isHorisontal = rect.width > rect.height ? true : false
        if isHorisontal! {
            totalPiecesQuantity = rect.width / rect.height > CGFloat(minPiecesQnty) ? Int(rect.width / rect.height) : minPiecesQnty
            pieceSize = CGSize(width: rect.width / CGFloat(totalPiecesQuantity!), height: rect.height)
        } else {
            totalPiecesQuantity = rect.height / rect.width > CGFloat(minPiecesQnty) ? Int(rect.height / rect.width) : minPiecesQnty
            pieceSize = CGSize(width: rect.width, height: rect.height / CGFloat(totalPiecesQuantity!))
        }
        pieceRadius = pieceSize!.width < pieceSize!.height ? pieceSize!.width * 0.8 / 2 : pieceSize!.height * 0.8 / 2
    }
    
    var readyPart:Double? { //percent of ready part
        willSet (newValue) {
            if  Int(newValue! * Double(totalPiecesQuantity!)) != donePieces {
                donePieces = Int(newValue! * Double(totalPiecesQuantity!))
                self.setNeedsDisplay()
                setAnimation()
            }
        }
    }
   
    var animationLayer:CAShapeLayer?
    func setAnimation(){
        
        if animationLayer == nil {
            animationLayer = CAShapeLayer()
            animationLayer!.bounds = CGRect(x: 0, y: 0, width: pieceSize!.width, height: pieceSize!.height)

            //set position
            let centerPoint = CGPoint(x: pieceSize!.width / 2, y: pieceSize!.height / 2)
            animationLayer!.path = UIBezierPath(arcCenter: centerPoint, radius: pieceRadius!, startAngle: 0, endAngle: CGFloat(Double.pi * 2), clockwise: true).cgPath
            animationLayer!.fillColor = indicatorColor?.cgColor ?? UIColor.white.cgColor
            animationLayer!.strokeColor = indicatorColor?.cgColor ?? UIColor.white.cgColor
            
            animationLayer!.position = centerPoint
            
            self.layer.addSublayer(animationLayer!)
            
            animationLayer!.opacity = 0.00
            let opacityAnimation = CABasicAnimation(keyPath: "opacity")
            opacityAnimation.fromValue = NSNumber.init(value: 0.00)
            opacityAnimation.toValue = NSNumber.init(value: 1.00)

            let scaleAnimation = CABasicAnimation(keyPath: "transform.scale")
            scaleAnimation.fromValue = NSNumber.init(value: 0.00)
            scaleAnimation.toValue = NSNumber.init(value: 1.2)
            
            let layerAnimationGroup = CAAnimationGroup()
            layerAnimationGroup.animations = [opacityAnimation, scaleAnimation]
            layerAnimationGroup.duration = 0.3
            
            layerAnimationGroup.repeatCount = Float.infinity
            layerAnimationGroup.autoreverses = true
            
            animationLayer!.add(layerAnimationGroup, forKey: nil)

        }

        var newPositionPoint: CGPoint
        if isHorisontal! {
            newPositionPoint = CGPoint(x: CGFloat(donePieces) * pieceSize!.width + pieceSize!.width / 2, y: pieceSize!.height / 2)
        } else {
            newPositionPoint = CGPoint(x: pieceSize!.height / 2, y: CGFloat(donePieces) * pieceSize!.height + pieceSize!.height / 2)
        }
        animationLayer!.position = newPositionPoint
    }

    // Only override draw() if you perform custom drawing.
    // An empty implementation adversely affects performance during animation.
    override func draw(_ rect: CGRect) {
        setMeasures(rect: rect)
        drawWithContext(context: UIGraphicsGetCurrentContext()!)
        // Drawing code
    }
    
    
    func drawWithContext(context: CGContext) {
        
        context.setLineWidth(lineWidth) //lineWidth
        context.setStrokeColor(indicatorColor?.cgColor ?? UIColor.white.cgColor)
        context.setFillColor(indicatorColor?.cgColor ?? UIColor.white.cgColor)
        
        let patchDone = UIBezierPath()
        for item in 0...donePieces {
            var circleCenter:CGPoint
            var point1:CGPoint
            
            if isHorisontal! {
                circleCenter = CGPoint(x: CGFloat(item) * pieceSize!.width - pieceSize!.width / 2, y:  pieceSize!.height / 2 )
                point1 = CGPoint(x: CGFloat(item) * pieceSize!.width - pieceSize!.width / 2 + pieceRadius!, y:  pieceSize!.height / 2 )
            } else {
                circleCenter = CGPoint(x: pieceSize!.width / 2 , y: CGFloat(item) * pieceSize!.height - pieceSize!.height / 2)
                point1 = CGPoint(x: pieceSize!.width / 2 + pieceRadius! , y: CGFloat(item) * pieceSize!.height - pieceSize!.height / 2)
            }
            patchDone.move(to: point1)
            patchDone.addArc(withCenter: circleCenter, radius: pieceRadius!, startAngle: 0, endAngle: CGFloat(Double.pi * 2), clockwise: true)
            
        }
        //draw done indicators
        context.addPath(patchDone.cgPath)
        context.drawPath(using: .fill)
        
        if donePieces < totalPiecesQuantity! {
            let patchEmpty = UIBezierPath()
            for item in (donePieces + 1)...totalPiecesQuantity! {
                var circleCenter:CGPoint
                var point1:CGPoint
                
                if isHorisontal! {
                    circleCenter = CGPoint(x: CGFloat(item) * pieceSize!.width - pieceSize!.width / 2, y:  pieceSize!.height / 2 )
                    point1 = CGPoint(x: CGFloat(item) * pieceSize!.width - pieceSize!.width / 2 + pieceRadius!, y:  pieceSize!.height / 2 )
                } else {
                    circleCenter = CGPoint(x: pieceSize!.width / 2 , y: CGFloat(item) * pieceSize!.height - pieceSize!.height / 2)
                    point1 = CGPoint(x: pieceSize!.width / 2 + pieceRadius! , y: CGFloat(item) * pieceSize!.height - pieceSize!.height / 2)
                }
                patchEmpty.move(to: point1)
                patchEmpty.addArc(withCenter: circleCenter, radius: pieceRadius!, startAngle: 0, endAngle: CGFloat(Double.pi * 2), clockwise: true)
                
            }
            //draw empty indicators
            context.addPath(patchEmpty.cgPath)
            context.drawPath(using: .stroke)
        }
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
        UIView.animate(withDuration: 0.6, animations: {
                self.alpha = 0
        })
    }
    
    func showSelfAnimated(){
        UIView.animate(withDuration: 0.6, animations: {
            self.alpha = 1
        })
    }
}
