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

protocol PassCiImage {
    var ciImage:CIImage? {get}
}

protocol PassDataReady {
    func percentageOfCompletion(_ percentage: Double)
}

class ResultImageObj: NSObject, PassDataReady{
    
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
    var delayOperation:DelayOperation?

    //create new imgObj from Image if Image = nil create an empty Obj
    init?(_ inputImageURL:URL, delegate:ResultImageObjDelegate?){ //not RETURN NIL!!!! CHECK
        self.delegate = delegate
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
        
        //add delay func //Important after define CIImage dependency
        let delayOp = DelayOperation(Double.random(in: 1...5), self)
        delayOp.name = "DELAY"
        if self.delayOperation != nil {
            delayOp.addDependency(self.delayOperation!)
        }
        self.delayOperation = delayOp
        convertOperationsQueue.addOperation(delayOp)
        
        if operationAsDependenci == nil {
            let getCiImageOperation = GetCIImageOperation(self.imageName)
            convertOperationsQueue.addOperation(getCiImageOperation)
            operationAsDependenci = getCiImageOperation
        }
        
        let convertOperation = ConvertOperation( effect, nil)
        convertOperation.addDependency(operationAsDependenci!)
        convertOperationsQueue.addOperation(convertOperation)

        let saveOperation = SaveUIImageOperation(self.imageName, nil)
        saveOperation.addDependency(convertOperation)
        convertOperationsQueue.addOperation(saveOperation)

        
        
        let callOperation = ReadySignalOperation()
        callOperation.addDependency(delayOp)//add delay time dependency
        callOperation.addDependency(saveOperation)
        callOperation.completionBlock = {
            DispatchQueue.main.async{
                self.inputCiImage = nil
                self.processingDoneInPercent = 1.00
                self.currentConvertionEffect = nil
                if self.delegate != nil {
                    self.delegate!.changedImgResultObj(resultImageObjName:self.imageName, error: nil, percentageOfCompletion: 1.00)
                }
            }
        }
        convertOperationsQueue.addOperation(callOperation)
    }
    
    
    //pass date delegate
    func percentageOfCompletion(_ percentage: Double) {
        if self.delegate != nil {
            self.delegate!.changedImgResultObj(resultImageObjName:self.imageName, error: nil, percentageOfCompletion: percentage)
        }
    }
    
}


class GetCiImgFromURLandFixOrientationOperation:Operation, PassCiImage{ //need for right orientation
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

class GetCIImageOperation: Operation, PassCiImage{
    let imageName: String
    var outCiImage:CIImage?
    
    //passing protocol
    var ciImage: CIImage? {return outCiImage}
    var inputCiImage:CIImage? {
        var image: CIImage?
        if let depedencie = dependencies
            .filter({$0 is PassCiImage})
            .first as? PassCiImage {
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

class ConvertOperation: Operation, PassCiImage{
    
    private let _inputCiImage:CIImage?
    let effect: String
    var outCiImage:CIImage?

    //passing protocol
    var ciImage: CIImage? {return outCiImage}
    var inputCiImage:CIImage? {
        var image: CIImage?
        if self._inputCiImage != nil {
            image = self.inputCiImage
        } else if let depedencie = dependencies
            .filter({$0 is PassCiImage})
            .first as? PassCiImage {
            image = depedencie.ciImage
        }
        return image
    }

    init( _ effect:String, _ inputCiImage:CIImage?, _ timeIntervalToDelay:TimeInterval = 1.00){
        self.effect = effect
        self._inputCiImage = inputCiImage
    }
    
    override func main(){
        if isCancelled {
            return
        }
        
        do {
            if self.inputCiImage != nil {
                outCiImage = try convertCIImage(ciImage: self.inputCiImage!, with: effect)
            } 
        }
        catch {
            print("Convertion error:", error)
        }
    }
}

class SaveUIImageOperation: Operation, PassCiImage{
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
            .filter({$0 is PassCiImage})
            .first as? PassCiImage {
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
        outCiImage = inputCiImage
    }
}

class ReadySignalOperation: Operation, PassCiImage{ //need just for delegate call after delay and saved opperation will be completed
    private let _inputCiImage:CIImage? = nil
    var outCiImage:CIImage?
    
    //passing protocol
    var ciImage: CIImage? {return outCiImage}
    var inputCiImage:CIImage? {
        var image: CIImage?
        if self._inputCiImage != nil {
            image = self.inputCiImage
        } else if let depedencie = dependencies
            .filter({$0 is PassCiImage})
            .first as? PassCiImage {
            image = depedencie.ciImage
        }
        return image
    }
    
    override func main(){
        if isCancelled {
            return
        }
        outCiImage = inputCiImage
    }
}

class DelayOperation: Operation {
    
    let timeToExecute:TimeInterval
    var startDate:Date
    var delegateToCatchExecuting:PassDataReady?
    
    init(_ delayTime:TimeInterval = 1, _ delegate:PassDataReady?){
        self.timeToExecute = delayTime
        self.delegateToCatchExecuting = delegate
        self.startDate = Date()
    }
    override func start() {
        self.startDate = Date()
        super.start()
    }
    override func main(){
        while Date(timeInterval: timeToExecute, since: startDate) > Date() {
            Thread.sleep(forTimeInterval: 0.03) //25 frames per second
            DispatchQueue.main.async {
                if self.delegateToCatchExecuting != nil {
                    self.delegateToCatchExecuting?.percentageOfCompletion( (self.startDate.timeIntervalSinceNow/self.timeToExecute) * (-1))
                }
            }
        }
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
