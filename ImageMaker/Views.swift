//
//  Views.swift
//  ImageMaker
//
//  Created by Serge Sychov on 30/07/2019.
//  Copyright © 2019 Serge Sychov. All rights reserved.
//

import Foundation
import AVFoundation
import UIKit

class SelfScaledBorderImageView: UIImageView {
    
    var containerView:UIView?
    func setBorderAndSize(){
        if self.image != nil && self.containerView != nil {
            self.layer.masksToBounds = true
            self.layer.borderWidth = 5
            self.layer.borderColor = UIColor.white.cgColor
            self.layer.cornerRadius = self.layer.borderWidth / 2
            self.frame = AVMakeRect(aspectRatio: self.image!.size, insideRect: self.containerView!.frame)
            self.center = CGPoint(x: containerView!.bounds.width/2, y: containerView!.bounds.height/2)
        } else {
            self.layer.borderWidth = 0
            self.layer.borderColor = UIColor.clear.cgColor
        }
    }
    
    //load new image
    override var image: UIImage? {
        didSet {
            setBorderAndSize()
        }
    }
    
    //resize image
    override func layoutSubviews() {
        super.layoutSubviews()
        setBorderAndSize()
    }
}
