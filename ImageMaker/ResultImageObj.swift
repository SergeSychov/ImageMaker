//
//  ResultImageObj.swift
//  ImageMaker
//
//  Created by Serge Sychov on 18/06/2019.
//  Copyright © 2019 Serge Sychov. All rights reserved.
//

import UIKit

protocol ResultImageObjDelegate: class {
    //completedPart - percent of spent time according wholedelay interval
    func changedImgWithName(resultImage: UIImage, resultImageObj:ResultImageObj)
}

class ResultImageObj: NSObject {
    
    //private var resultImg: UIImage?
    var imageName:String?
    weak var delegate: ResultImageObjDelegate?
    
    public var image:UIImage?{
        get {
            if imageName != nil{
                return getSavedImage(named:imageName!)
            } else {
                return nil
            }
        }
        set (newImsge){
            if newImsge != nil {
                if self.imageName == nil {
                    self.imageName = "ImageMaker_" + ProcessInfo().globallyUniqueString + ".jpg"
                }
                if saveImage(image:newImsge!, name:self.imageName!) {
                    print("result img saved")
                }
            }
        }
    }
    
   // let percentOfCompletedConvertion: CGFloat //for future for convertion with delay
    
    //create new imgObj from Image if Image = nil create an empty Obj
    init(_ inputImage:UIImage?, delegate:ResultImageObjDelegate?){
        self.delegate = delegate
        self.imageName = nil
        if inputImage != nil {
            self.imageName = "ImageMaker_" + ProcessInfo().globallyUniqueString + ".jpg"
            if saveImage(image:inputImage!, name:self.imageName!) {
                print("result img saved")
            }
        } //else make an obj with string name nil
        super.init()
    }
    
    //create new obj from saved file
    init(name:String, delegate:ResultImageObjDelegate?){
        self.imageName = name
        self.delegate = delegate
    }

    public func applyImgConvertion(_ workImage: UIImage,_ effect:String?){
        let outImg:UIImage
        if effect == "CutColors" {
            outImg = ImageConvertor.convertImageToBW(image: workImage)
        } else if effect == "Mirror" {
            outImg = ImageConvertor.mirrorHorizontally(image: workImage)
        } else if effect == "Rotate" {
            outImg = ImageConvertor.rotateImageLeft(image: workImage)
        } else {
            outImg = workImage
        }
        //if it was an empty obj set the unic name for it and save result image
        
        if self.imageName == nil {
            self.imageName = "ImageMaker_" + ProcessInfo().globallyUniqueString + ".jpg"
        }
        if saveImage(image:outImg, name:self.imageName!) {
            print("result img saved")
            if self.delegate != nil {
                self.delegate!.changedImgWithName(resultImage:outImg, resultImageObj:self)
            }
        }
    }
    
}
