//
//  ResultImageObj.swift
//  ImageMaker
//
//  Created by Serge Sychov on 18/06/2019.
//  Copyright © 2019 Serge Sychov. All rights reserved.
//

import UIKit

func saveImage(image:UIImage, name:String) -> Bool {
    guard let data = image.jpegData(compressionQuality: 1) else {
        return false
    }
    guard let directory = try? FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: false) as NSURL else {
        return false
    }
    
    //Checks if file exists, remove it
    if FileManager.default.fileExists(atPath: directory.appendingPathComponent(name)!.path) {
        do {
            //remove old img
            try FileManager.default.removeItem(atPath: directory.appendingPathComponent(name)!.path)
        } catch let removeError {
            print("not remove img", removeError)
            return false
        }
    }
    
    do {
        try data.write(to: directory.appendingPathComponent(name)!)
        return true
    } catch let saveError {
        print("not save img", saveError)
        return false
    }
}

func removeFile(named: String) -> Bool {
    guard let directory = try? FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: false) as NSURL else {
        return false
    }
    
    //Checks if file exists, remove it
    if FileManager.default.fileExists(atPath: directory.appendingPathComponent(named)!.path) {
        do {
            //remove old img
            try FileManager.default.removeItem(atPath: directory.appendingPathComponent(named)!.path)
            print("success deleting file")
            return true
        } catch let removeError {
            print("not remove img", removeError)
            return false
        }
    } else {
        return false
    }
}

func getSavedImage(named: String) -> UIImage? {
    if let dir = try? FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: false) {
        return UIImage(contentsOfFile: URL(fileURLWithPath: dir.absoluteString).appendingPathComponent(named).path)
    }
    return nil
}

protocol ResultImageObjDelegate: class {
    //completedPart - percent of spent time according wholedelay interval
    func changedImgWithName(resultImage: UIImage, resultImageObj:ResultImageObj)
}

class ResultImageObj: NSObject {
    
    //private var resultImg: UIImage?
    var imageName:String?
    weak var delegate: ResultImageObjDelegate?
    
    public var image:UIImage?{
        if imageName != nil{
        return getSavedImage(named:imageName!)
        } else {
            return nil
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
    }
    
    deinit {
        if imageName != nil {
            if !removeFile(named: self.imageName!) {
                print("can't delete file")
            }
        }
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
