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
    func changedImgResultObj(resultImageObjName:String, error:Error?, percentageOfCompletion: Double)
    
}


protocol passCiImage {
    var ciImage:CIImage? {get}
}

protocol passDataReady {
    func percentageOfCompletion(_ percentage: Double)
}

class ResultImageObj: NSObject, passDataReady{
    
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
    init?(_ inputImageURL:URL, delegate:ResultImageObjDelegate?){ //not RETURN NIL!!!! CHECK
        self.delegate = delegate
        convertOperationsQueue.maxConcurrentOperationCount = 2
        self.imageName = "ImageMaker_" + ProcessInfo().globallyUniqueString + ".jpg" //create unic name for saved image

        super.init()

        let getCiAndFixOrientationFromUrlOperation = GetCiImgFromURLandFixOrientationOperation(inputImageURL)
        convertOperationsQueue.addOperation(getCiAndFixOrientationFromUrlOperation)
            
        let saveOperationToUrlwithName = SaveUIImageOperation(self.imageName, nil)
        saveOperationToUrlwithName.addDependency(getCiAndFixOrientationFromUrlOperation)
            convertOperationsQueue.addOperation(saveOperationToUrlwithName)
        print(convertOperationsQueue.operationCount)
    }
    
    //create new obj from saved file
    init?(name:String, delegate:ResultImageObjDelegate?, notCompleatedEffect: String?){
        convertOperationsQueue.maxConcurrentOperationCount = 1
        do {
            let url = try urlForFileNamed(name)
            guard CIImage(contentsOf: url) != nil else {
                print("init with get ciImage from url error: ")
                return nil
            }
            self.imageName = name
            self.delegate = delegate
            self.processingDoneInPercent = 1.00
            super.init()
        }
        catch {
            print("init with create url from string error: ", error)
            return nil
        }
    }
    
    func applyImgConvertionWith(_ effect: String){
        self.processingDoneInPercent = 0.00 //start convertation
        self.currentConvertionEffect = effect
        
        //define operation for next dependencies
        var operationAsDependenci:Operation?
        //1. get current operation array
        let operations = convertOperationsQueue.operations
        if operations.count > 0 {
            operationAsDependenci = operations.last
        }
        
        if operationAsDependenci == nil {
            let getCiImageOperation = GetCIImageOperation(self.imageName)
            convertOperationsQueue.addOperation(getCiImageOperation)
            operationAsDependenci = getCiImageOperation
        }
        
        let convertOperation = ConvertOperation( effect, nil)
        convertOperation.addDependency(operationAsDependenci!)
        convertOperation.delegateToCatchExecuting = self
        convertOperationsQueue.addOperation(convertOperation)

        let saveOperation = SaveUIImageOperation(self.imageName, nil)
        saveOperation.addDependency(convertOperation)
        saveOperation.completionBlock = {
            DispatchQueue.main.async{
                self.inputCiImage = nil
                self.processingDoneInPercent = 1.00
                self.currentConvertionEffect = nil
                if self.delegate != nil {
                    self.delegate!.changedImgResultObj(resultImageObjName:self.imageName, error: nil, percentageOfCompletion: 1.00)
                }
            }
        }
        convertOperationsQueue.addOperation(saveOperation)
    }
    
    
    //pass date delegate
    func percentageOfCompletion(_ percentage: Double) {
        if self.delegate != nil {
            self.delegate!.changedImgResultObj(resultImageObjName:self.imageName, error: nil, percentageOfCompletion: percentage)
        }
    }

    /*
    func getURLOfImageFile() throws -> URL{
        do {
            return try urlForFileNamed(self.imageName)
        } catch {
            print("getURLOfImageFile get URL:", error)
            throw error
        }
    } */
    
}


class GetCiImgFromURLandFixOrientationOperation:Operation, passCiImage{ //need for right orientation
    let inputImgUrl:URL
    var outCiImage:CIImage?
    
    //passing protocol
    var ciImage: CIImage? {return outCiImage}
    
    init(_ url:URL){
        self.inputImgUrl = url
    }
    
    override func main(){
        if isCancelled {
            return
        }
        outCiImage = getCiImgFromURLandFixOrientation(url: inputImgUrl)
    }
}

class GetCIImageOperation: Operation, passCiImage{
    let imageName: String
    var outCiImage:CIImage?
    
    //passing protocol
    var ciImage: CIImage? {return outCiImage}
    var inputCiImage:CIImage? {
        var image: CIImage?
        if let depedencie = dependencies
            .filter({$0 is passCiImage})
            .first as? passCiImage {
            image = depedencie.ciImage
        }
        return image
    }
    
    init(_ imageName:String){
        self.imageName = imageName
    }
    
    override func main(){
        if isCancelled {
            return
        }
        
        do {
            outCiImage = try CIImage(contentsOf: urlForFileNamed(self.imageName))
        }
        catch {
            print("getCIImageFromURL error: ", error)
        }
    }
}

class ConvertOperation: Operation, passCiImage{
    
    private let _inputCiImage:CIImage?
    let effect: String
    var outCiImage:CIImage?
    
    let timeToExecute:TimeInterval
    var startDate:Date
    var delegateToCatchExecuting:passDataReady?

    //passing protocol
    var ciImage: CIImage? {return outCiImage}
    var inputCiImage:CIImage? {
        var image: CIImage?
        if self._inputCiImage != nil {
            image = self.inputCiImage
        } else if let depedencie = dependencies
            .filter({$0 is passCiImage})
            .first as? passCiImage {
            image = depedencie.ciImage
        }
        return image
    }

    init( _ effect:String, _ inputCiImage:CIImage?, _ timeIntervalToDelay:TimeInterval = 1.00){
        self.effect = effect
        self._inputCiImage = inputCiImage
        self.timeToExecute = timeIntervalToDelay
        self.startDate = Date()
    }
    
    override func start() {
        self.startDate = Date()
        super.start()
    }
    
    override func main(){
        if isCancelled {
            return
        }
        
        do {
            let convertedImg:CIImage?
            if self.inputCiImage != nil {
                convertedImg = try convertCIImage(ciImage: self.inputCiImage!, with: effect)
            } else {
                convertedImg = nil
            }
            //var counter = 0
            while Date(timeInterval: timeToExecute, since: startDate) > Date() {
                Thread.sleep(forTimeInterval: 0.04) //25 frames per second
                DispatchQueue.main.async {
                    if self.delegateToCatchExecuting != nil {
                        self.delegateToCatchExecuting?.percentageOfCompletion( (self.startDate.timeIntervalSinceNow/self.timeToExecute) * (-1))
                    }
                }
               // print("sleep: ", counter)
               // counter += 1
            }
            outCiImage = convertedImg
            
        }
        catch {
            print("Convertion error:", error)
        }
    }
}

class SaveUIImageOperation: Operation, passCiImage{
    let fileName:String
    private let _inputCiImage:CIImage?
    var outCiImage:CIImage?
    
    //passing protocol
    var ciImage: CIImage? {return outCiImage}
    var inputCiImage:CIImage? {
        var image: CIImage?
        if self._inputCiImage != nil {
            image = self.inputCiImage
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
        if isCancelled {
            return
        }
        
        
        if inputCiImage != nil {
            if saveCIImageToFileWithName(inputCiImage!, fileName){
                print("New image saved")
            }
        }

        /*
        if let convertedUIImage = uiImageFromCiImage(inputCiImage) {
            if saveImage(image:convertedUIImage, name:self.fileName){
            }
        }*/
        outCiImage = inputCiImage
    }
}
/*
 func getUIImage(forSize size:CGSize) throws -> UIImage{
 do {
 let imageDataFileURL = try urlForFileNamed(self.imageName)
 return try loadImage(imageUrl: imageDataFileURL, size: size)
 } catch {
 print("Error getUIImage get URL:", error)
 throw error
 }
 }*/
