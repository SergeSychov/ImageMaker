//
//  ImageConvertor.swift
//  ImageMaker
//
//  Created by Serge Sychov on 16/06/2019.
//  Copyright © 2019 Serge Sychov. All rights reserved.
//

import UIKit
import MobileCoreServices


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
}

func mirrorHorizontally(ciImage: CIImage)->CIImage?{
    
    return ciImage.transformed(by: CGAffineTransform.init(scaleX: -1, y: 1))
}

func rotateImageLeft(ciImage: CIImage)->CIImage?{
    return ciImage.transformed(by: CGAffineTransform.init(rotationAngle: -.pi/2))
}


//============== LOAD AND USE IMAGE ===============================================================
func getCIImageFromURL(_ imageUrl: URL) throws -> CIImage {
    guard let ciImageFromURL = CIImage(contentsOf: imageUrl) else {
        throw convertImageError.invalidImageData
    }
    return ciImageFromURL
}


func uiImageFromCiImage(_ ciImage:CIImage?) -> UIImage? {
    if ciImage != nil {
        let cgImage = CIContext().createCGImage(ciImage!, from: (ciImage!.extent))
        
        if cgImage == nil {
            return UIImage(ciImage: ciImage!) //return input image as result, can not convert
        } else {
            return UIImage(cgImage: cgImage!)
        }
    } else {
        return nil
    }
}



func resaveForRightOrientationImageFrom(url: URL, toFile name: String) -> Bool {
    let imageSourceOptions = [kCGImageSourceShouldCache: false] as CFDictionary
    guard let imageSource = CGImageSourceCreateWithURL(url as CFURL, imageSourceOptions) else {
        //throw convertImageError.invalidImageData
        return false
    }
    
    let downSampleOptions = [kCGImageSourceCreateThumbnailFromImageAlways: true,
                             kCGImageSourceCreateThumbnailWithTransform: true,] as CFDictionary
    
    guard let downSampledImage = CGImageSourceCreateThumbnailAtIndex(imageSource, 0, downSampleOptions) else {
        print("chekImageOnOrientationAndReturnFrom Can't create image with new orientation")
        return false
    }
    do {
        let fileURL = try urlForFileNamed(name) as CFURL
        let dest = CGImageDestinationCreateWithURL(fileURL, kUTTypeJPEG2000, 1, nil)
        if dest != nil {
            CGImageDestinationAddImage(dest!, downSampledImage, nil)
            if !CGImageDestinationFinalize(dest!){
                print("chekImageOnOrientationAndReturnFrom cant save file")
                return false
            } else {
                print("chekImageOnOrientationAndReturnFrom File Saved")
                //return url
                return true
            }
        } else {
            print("chekImageOnOrientationAndReturnFrom cna't create destination")
            return false
        }
        
    }
        
    catch {
        print("chekImageOnOrientationAndReturnFrom can't create URL")
        return false
    }
}


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
        kCGImageSourceThumbnailMaxPixelSize: maxdimentionInPixels/*,
         kCGImagePropertyOrientation: 1*/] as CFDictionary
    
    guard let downSampledImage = CGImageSourceCreateThumbnailAtIndex(imageSource, 0, downSampleOptions) else {
        throw convertImageError.invalidCreatingSourse
    }
    
    return UIImage(cgImage: downSampledImage)
}

//==================== not used in APP ==============================================
/*
 
 func convertImageFromURL(imageUrl: URL, effect: String) throws -> UIImage? {
 
 do {
 let ciImageFromURL = try getCIImageFromURL(imageUrl)
 let outCiImage = try convertCIImage(ciImage: ciImageFromURL, with: effect)
 
 return uiImageFromCiImage(outCiImage)
 } catch {
 print(error)
 return nil
 }
 }
*/

/*
func chekImageOnOrientationAndReturnFrom(url:URL)-> URL {
    let imageSourceOptions = [kCGImageSourceShouldCache: false] as CFDictionary
    guard let imageSource = CGImageSourceCreateWithURL(url as CFURL, imageSourceOptions) else {
        //throw convertImageError.invalidImageData
        return url
    }
    
    let options = CGImageSourceCopyPropertiesAtIndex(imageSource, 0, nil) as Dictionary?
    if (options != nil) && (options![kCGImagePropertyOrientation] != nil) && (options![kCGImagePropertyOrientation] as! Int != 1){
        //create image with normal orientation
        let downSampleOptions = [kCGImageSourceCreateThumbnailFromImageAlways: true,
                                 kCGImageSourceCreateThumbnailWithTransform: true,] as CFDictionary
        
        guard let downSampledImage = CGImageSourceCreateThumbnailAtIndex(imageSource, 0, downSampleOptions) else {
            print("chekImageOnOrientationAndReturnFrom Can't create image with new orientation")
            return url
        }
        
        do {
            let fileURL = try urlForFileNamed(tempPhotoName) as CFURL
            let dest = CGImageDestinationCreateWithURL(fileURL, kUTTypeJPEG2000, 1, nil)
            if dest != nil {
                CGImageDestinationAddImage(dest!, downSampledImage, nil)
                if !CGImageDestinationFinalize(dest!){
                    print("chekImageOnOrientationAndReturnFrom cant save file")
                    return url
                } else {
                    print("chekImageOnOrientationAndReturnFrom File Saved")
                    //return url
                    return fileURL as URL
                }
            } else {
                print("chekImageOnOrientationAndReturnFrom cna't create destination")
                return url
            }
            
        }
            
        catch {
            print("chekImageOnOrientationAndReturnFrom can't create URL")
            return url
        }
    } else {
        print("normal or without options")
        return url
    }
}*/
//===========================================================



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
