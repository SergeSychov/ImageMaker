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
    var imageName:String
    weak var delegate: ResultImageObjDelegate?
    var inputCiImage: CIImage?
    var processingDoneInPercent: CGFloat = 0.00 //default value. Value to show how image is converted from
    var currentConvertionEffect: String? //if not compleated convertion need to save that information
    public var convertProcessDone: CGFloat {
        get {
            return processingDoneInPercent
        }
    }
    let convertOperationsQueue = OperationQueue()

    //create new imgObj from Image if Image = nil create an empty Obj
    init?(_ inputImageURL:URL, delegate:ResultImageObjDelegate?){
        self.delegate = delegate

        do {
            self.imageName = "ImageMaker_" + ProcessInfo().globallyUniqueString + ".jpg" //create unic name for saved image
            inputCiImage = try getCIImageFromURL(inputImageURL)
            if copyDataToFile(at: inputImageURL, fileName: self.imageName){
                print("InputData saved")
            }
            /*
            let inputData = try NSData(contentsOf: inputImageURL) as NSData
            if saveImageData(data: inputData, imageName: self.imageName) != nil {
                print("InputData saved")
            }*/
            super.init()
        } catch {
            print("init with image error: ", error)
            return nil
        }
    }
    
    //create new obj from saved file
    init?(name:String, delegate:ResultImageObjDelegate?, notCompleatedEffect: String?){
        
        do {
            _ = try getCIImageFromURL(urlForFileNamed(name)) //if thw file is readable as image
            self.imageName = name
            self.delegate = delegate
            self.processingDoneInPercent = 1.00
             super.init()
            if notCompleatedEffect != nil {
                //if load obj with not compleated effect - start convertion
                self.applyImgConvertionWith(notCompleatedEffect!)
            }
        }
        catch {
            print("init with string error: ", error)
            return nil
        }

    }
    
    func applyImgConvertionWith(_ effect: String){
        self.processingDoneInPercent = 0.00 //start convertation
        self.currentConvertionEffect = effect
        
        let convertOperation = ConvertOperation(self.imageName, effect, nil)
        convertOperationsQueue.addOperation(convertOperation)

        let saveOperation = saveUIImageOperation(self.imageName, nil)
        saveOperation.addDependency(convertOperation)
        saveOperation.completionBlock = {
            DispatchQueue.main.async{
                self.inputCiImage = nil
                self.processingDoneInPercent = 1.00
                self.currentConvertionEffect = nil
                if self.delegate != nil {
                    self.delegate!.changedImgResultObj(resultImageObj: self, error: nil)
                }
            }
        }
        convertOperationsQueue.addOperation(saveOperation)
    }

    func getURLOfImageFile() throws -> URL{
        do {
            return try urlForFileNamed(self.imageName)
        } catch {
            print("getURLOfImageFile get URL:", error)
            throw error
        }
    }
    
    func getUIImage(forSize size:CGSize) throws -> UIImage{
        do {
            let imageDataFileURL = try urlForFileNamed(self.imageName)
            return try loadImage(imageUrl: imageDataFileURL, size: size)
        } catch {
            print("Error getUIImage get URL:", error)
            throw error
        }
    }
}

protocol passCiImage {
    var ciImage:CIImage? {get}
}

class ConvertOperation: Operation, passCiImage{
    
    var inputCiImage:CIImage?
    let imageName: String
    let effect: String
    var outCiImage:CIImage?
    //var convertionError:Error?
    
    //passing protocol
    var ciImage: CIImage? {return outCiImage}
    
    init(_ imageName:String, _ effect:String, _ inputCiImage:CIImage?){
        self.imageName = imageName
        self.effect = effect
        if inputCiImage != nil {
            self.inputCiImage = inputCiImage!
        }
    }
    
    override func main(){
        if isCancelled {
            return
        }
        
        do {
            if self.inputCiImage != nil {
                outCiImage = try convertCIImage(ciImage: self.inputCiImage!, with: effect)
            } else {
                outCiImage = try convertCIImage(ciImage: getCIImageFromURL(urlForFileNamed(self.imageName)), with: effect)
            }

        } catch {
            print("Convertion error: ", error)
           // convertionError = error
        }
    }
}

class saveUIImageOperation: Operation {
    let fileName:String
    private let _inputCiImage:CIImage?
    
    var inputCiImage:CIImage? {
        var image: CIImage?
        if let inputCiImage = self._inputCiImage {
            image = inputCiImage
        } else if let depedencie = dependencies
            .filter({$0 is passCiImage})
            .first as? passCiImage {
                image = depedencie.ciImage
        }
        return image
    }
    
    init(_ fileName:String, _ inputCiImage:CIImage?){
        self.fileName = fileName
        self._inputCiImage = inputCiImage
    }
    
    override func main(){
        if let convertedUIImage = uiImageFromCiImage(inputCiImage) {
            if saveImage(image:convertedUIImage, name:self.fileName){
                print("saved converted image")
            }
        }
    }
}
