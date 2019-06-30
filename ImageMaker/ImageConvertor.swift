//
//  ImageConvertor.swift
//  ImageMaker
//
//  Created by Serge Sychov on 16/06/2019.
//  Copyright © 2019 Serge Sychov. All rights reserved.
//

import UIKit


let effects = [
    "Filter":1,
    "Mirror": 2,
    "Rotate": 3,
]

enum convertImageError:Error {
    case invalidFileURL
    case invalidImageData
    case invalidEffectName
    case noSuchFilter
    case invalidCreatingSourse
}

let filters = [
    "CutColors": "CIPhotoEffectMono",
]


func loadImage(imageUrl:URL, size:CGSize, scale:CGFloat = 2.0) throws -> UIImage {

    let imageSourceOptions = [kCGImageSourceShouldCache: false] as CFDictionary
    guard let imageSource = CGImageSourceCreateWithURL(imageUrl as CFURL, imageSourceOptions) else {
        throw convertImageError.invalidImageData
    }

    let maxdimentionInPixels = max(size.width, size.height)*scale
    let downSampleOptions = [
        kCGImageSourceCreateThumbnailFromImageAlways: true,
        kCGImageSourceShouldCacheImmediately: true,
        kCGImageSourceCreateThumbnailWithTransform: true,
        kCGImageSourceThumbnailMaxPixelSize:
                            maxdimentionInPixels] as CFDictionary
    
    guard let downSampledImage = CGImageSourceCreateThumbnailAtIndex(imageSource, 0, downSampleOptions) else {
        throw convertImageError.invalidCreatingSourse
    }

    return UIImage(cgImage: downSampledImage)
}


func convertImageFromURL(imageUrl: URL, effect: String) throws -> UIImage? {
    
    guard let ciImageFromURL = CIImage(contentsOf: imageUrl) else {
        throw convertImageError.invalidImageData
    }
   /* guard effects.keys.contains(effect) || filters.keys.contains(effect) else {
        throw convertImageError.invalidEffectName
    }
    let converTask = filters.keys.contains(effect) ? "Filter" : effect
    
    var outCiImage: CIImage?*/
    do {
        let outCiImage = try convertCIImage(ciImage: ciImageFromURL, with: effect)
        
        /*
        switch effects[converTask] {
        case effects["Filter"]:
            outCiImage = convertImageWithFilter(ciImage:ciImageFromURL, filterName: filters[effect]!)
        case effects["Mirror"]:
            outCiImage = mirrorHorizontally(ciImage: ciImageFromURL)
        case effects["Rotate"]:
            outCiImage = rotateImageLeft(ciImage: ciImageFromURL)
        default:
            outCiImage = ciImageFromURL
        }*/
        
        if outCiImage != nil {
            let cgImage = CIContext().createCGImage(outCiImage!, from: (outCiImage!.extent))
            
            if cgImage == nil {
                return UIImage(ciImage: outCiImage!) //return input image as result, can not convert
            } else {
                return UIImage(cgImage: cgImage!)
            }
        } else {
            return nil
        }
    } catch {
        print(error)
        return nil
    }
    
    
    /*do {
        let ciImageFromURL = try getCIImageFromURL(imageUrl: imageUrl)
        let resultCIImage =  try convertCIImage(ciImage: ciImageFromURL, with: effect)
        
        return UIImage(ciImage: resultCIImage!)
        
    } catch {
        throw error
    }*/
}

func getCIImageFromURL(imageUrl: URL) throws -> CIImage {
    guard let ciImageFromURL = CIImage(contentsOf: imageUrl) else {
        throw convertImageError.invalidImageData
    }
    return ciImageFromURL
}


func convertCIImage(ciImage: CIImage, with effect: String) throws -> CIImage? {
    guard effects.keys.contains(effect) || filters.keys.contains(effect) else {
        throw convertImageError.invalidEffectName
    }
    let converTask = filters.keys.contains(effect) ? "Filter" : effect
    
    switch effects[converTask] {
    case effects["Filter"]:
        return convertImageWithFilter(ciImage:ciImage, filterName: filters[effect]!)
    case effects["Mirror"]:
        return mirrorHorizontally(ciImage: ciImage)
    case effects["Rotate"]:
        return rotateImageLeft(ciImage: ciImage)
    default:
        return ciImage
    }
}

func convertImageWithFilter(ciImage:CIImage, filterName: String) -> CIImage? { //    class
    
    let filter = CIFilter(name: filterName)
    filter?.setValue(ciImage, forKey: "inputImage")
    
    return filter?.outputImage
    
    /*
    let ciOutput = filter?.outputImage
    
    let cgImage = CIContext().createCGImage(ciOutput!, from: (ciOutput?.extent)!)
    
    if cgImage == nil {
        return UIImage(ciImage: ciImage) //return input image as result, can not convert
    } else {
        return UIImage(cgImage: cgImage!)
    }*/
}

func mirrorHorizontally(ciImage: CIImage)->CIImage?{
    return ciImage.transformed(by: CGAffineTransform.init(scaleX: -1, y: 1))

    /*
    let ciOutput = ciImage.transformed(by: CGAffineTransform.init(scaleX: -1, y: 1))
    let cgImage = CIContext().createCGImage(ciOutput, from: (ciOutput.extent))
    if cgImage == nil {
        return UIImage(ciImage: ciImage) //return input image as result, can not convert
    } else {
        return UIImage(cgImage: cgImage!)
    }*/
}

func rotateImageLeft(ciImage: CIImage)->CIImage?{
    return ciImage.transformed(by: CGAffineTransform.init(rotationAngle: -.pi/2))
   
    /*
    let ciOutput = ciImage.transformed(by: CGAffineTransform.init(rotationAngle: -.pi/2))
    let cgImage = CIContext().createCGImage(ciOutput, from: (ciOutput.extent))
    
    if cgImage == nil {
        return UIImage(ciImage: ciImage) //return input image as result, can not convert
    } else {
        return UIImage(cgImage: cgImage!)
    }*/

}


/*func resizeImage(cfDataImg:CFData, size:CGSize, scale:CGFloat) -> UIImage {
 
 let imageSourceOptions = [kCGImageSourceShouldCache: false] as CFDictionary
 let imageSource = CGImageSourceCreateWithData(cfDataImg, imageSourceOptions)!
 //let imageSource = CGImageSourceCreateWithURL(imageUrl as CFURL, imageSourceOptions)!
 
 let maxdimentionInPixels = max(size.width, size.height)*scale
 let downSampleOptions =
 [kCGImageSourceCreateThumbnailFromImageAlways: true,
 kCGImageSourceShouldCacheImmediately: true,
 kCGImageSourceCreateThumbnailWithTransform: true,
 kCGImageSourceThumbnailMaxPixelSize: maxdimentionInPixels] as CFDictionary
 let downSampledImage = CGImageSourceCreateThumbnailAtIndex(imageSource, 0, downSampleOptions)!
 
 return UIImage(cgImage: downSampledImage)
 }*/

/*var retImg = image
 if(image.imageOrientation != UIImage.Orientation.up){
 UIGraphicsBeginImageContext(image.size)
 image.draw(at: .zero)
 let newImage = UIGraphicsGetImageFromCurrentImageContext()
 UIGraphicsEndImageContext()
 retImg = newImage ?? image
 }*/

/*class ImageConvertor: NSObject {

    weak var delegate: ImageConvectorProcessDelegate?
    public class func convertImageInProcess (_ image: UIImage?, _ effect: String){
        var retImage:UIImage
        let startDate = NSDate.init()
        let delay = Int.random(in: 2..<10)
        let onePercentOfDelay = delay/100;\
        let start = DispatchTime.now()
        DispatchQueue.global(qos: .background).async {
            DispatchQueue.main.asyncAfter(deadline: .now() + 10.0, execute: {
                if  image != nil {
                    print(effect)
                    
                    if effect == "CutColors" {
                        retImage = ImageConvertor.convertImageToBW(image: image!)
                    } else if effect == "Mirror" {
                        retImage = ImageConvertor.mirrorHorizontally(image: image!)
                    } else if effect == "Rotate" {
                        retImage = ImageConvertor.rotateImageLeft(image: image!)
                    }
                    else {
                        retImage = image!
                    }
                } else {
                    retImage = image!
                }
            })
        }
    }*/
    
    
    
/*
    public class func convertImage(_ image: UIImage?, _ effect: String) -> UIImage? {

        if  image != nil {
            print(effect)
            if effect == "CutColors" {
                return self.convertImageToBW(image: image!)
            } else if effect == "Mirror" {
                return self.mirrorHorizontally(image: image!)
            } else if effect == "Rotate" {
                return self.rotateImageLeft(image: image!)
            }
            else {
                return image
            }
        } else {
            return nil
        }
    }
    
    class func convertImageToBW(image:UIImage) -> UIImage { //    class
        
        let filter = CIFilter(name: "CIPhotoEffectMono")
        
        // convert UIImage to CIImage and set as input
        let ciInput = CIImage(image: image)
        filter?.setValue(ciInput, forKey: "inputImage")

        let ciOutput = filter?.outputImage
        let ciContext = CIContext()
        let cgImage = ciContext.createCGImage(ciOutput!, from: (ciOutput?.extent)!)
        
        return  UIImage(cgImage: cgImage!, scale: 1, orientation: image.imageOrientation)
    }
    
    class func mirrorHorizontally(image:UIImage)->UIImage{

        var retImg = image
        if(image.imageOrientation != UIImage.Orientation.up){
            UIGraphicsBeginImageContext(image.size)
            image.draw(at: .zero)
            let newImage = UIGraphicsGetImageFromCurrentImageContext()
            UIGraphicsEndImageContext()
            retImg = newImage ?? image
        }

        //let ciInput = CIImage(contentsOf: <#T##URL#>)// CIImage(image: image)
        let ciInput = CIImage(image: retImg)// CIImage(image: image)
        let ciOutput = ciInput?.transformed(by: CGAffineTransform.init(scaleX: -1, y: 1))
        let ciContext = CIContext()
        let cgImage = ciContext.createCGImage(ciOutput!, from: (ciOutput?.extent)!)
        return  UIImage(cgImage: cgImage!, scale: 1, orientation:retImg.imageOrientation)
    }
    
    class func rotateImageLeft(image:UIImage)->UIImage{
        let ciInput = CIImage(image: image)// CIImage(image: image)
        let ciOutput = ciInput?.transformed(by: CGAffineTransform.init(rotationAngle: -.pi/2))
        let ciContext = CIContext()
        let cgImage = ciContext.createCGImage(ciOutput!, from: (ciOutput?.extent)!)
        return  UIImage(cgImage: cgImage!, scale: 1, orientation:image.imageOrientation)
    }
}*/
