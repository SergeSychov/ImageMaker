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
    func changedImgResultObj(resultImageObj:ResultImageObj, error:Error?)
}

class ResultImageObj: NSObject {
    
    //private var resultImg: UIImage?
    var imageName:String?
    weak var delegate: ResultImageObjDelegate?
    var processingDoneInPercent: CGFloat = 0.00 //default value. Value to show how image is converted from
    var currentConvertionEffect: String? //if not compleated convertion need to save that information
    public var convertProcessDone: CGFloat {
        get {
            return processingDoneInPercent
        }
    }

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
    init(name:String, delegate:ResultImageObjDelegate?, notCompleatedEffect: String?){
        self.imageName = name
        self.delegate = delegate
        self.processingDoneInPercent = 1.00
        super.init()
        
        if notCompleatedEffect != nil {
            //if load obj with not compleated effect - start convertion
            do {
                let objImgURL = try urlForFileNamed(name)
                self.applyImgConvertion(objImgURL, notCompleatedEffect!)
            } catch {
                print("ResObj init from file can't create URL for name", error)
            }
        }
    }

    func applyImgConvertion(_ workImageURL: URL,_ effect:String){
        //if it was an empty obj set the unic name for it
        if self.imageName == nil {
            self.imageName = "ImageMaker_" + ProcessInfo().globallyUniqueString + ".jpg"
        }
        self.processingDoneInPercent = 0.00 //start convertation
        self.currentConvertionEffect = effect
        
        DispatchQueue.global(qos: .userInitiated).async {
            var aplyConvertionError:Error?
            //1. save input DATA to obj URL for reasons if convertion will not be compleated till App go off
            do {
                let inputData = try NSData(contentsOf: workImageURL) as NSData
                if saveImageData(data: inputData, imageName: self.imageName!) != nil {
                    print("InputData saved")
                }
            } catch {
                print("NSData error: ", error)
                aplyConvertionError = error
            }
            
            var convertedUIImage: UIImage?
            var isNewImageSaved = false
            do {
                convertedUIImage = try convertImageFromURL(imageUrl:workImageURL, effect:effect)
                isNewImageSaved = saveImage(image:convertedUIImage!, name:self.imageName!)
            } catch {
                print("Convertion error: ", error)
                aplyConvertionError = error
            }
            
            DispatchQueue.main.async {
                if effect == self.currentConvertionEffect {//if it is atual request.
                    self.processingDoneInPercent = 1.00
                    self.currentConvertionEffect = nil
                    if self.delegate != nil {
                        self.delegate!.changedImgResultObj(resultImageObj: self, error: aplyConvertionError)
                    }
                }
                
            }
        }
    }
    
    func getURLOfImageFile() throws -> URL{
        do {
            return try urlForFileNamed(self.imageName!)
        } catch {
            print("getURLOfImageFile get URL:", error)
            throw error
        }
        
    }
    
    func getUIImage(forSize size:CGSize) throws -> UIImage{
        do {
            let imageDataFileURL = try urlForFileNamed(self.imageName!)
            return try loadImage(imageUrl: imageDataFileURL, size: size)
        } catch {
            print("Error getUIImage get URL:", error)
            throw error
        }
    }
    
}
