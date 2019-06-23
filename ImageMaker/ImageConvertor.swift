//
//  ImageConvertor.swift
//  ImageMaker
//
//  Created by Serge Sychov on 16/06/2019.
//  Copyright © 2019 Serge Sychov. All rights reserved.
//

import UIKit

func resizeImage(cfDataImg:CFData, size:CGSize, scale:CGFloat) -> UIImage {
    
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
}

func loadImage(imageUrl:URL, size:CGSize, scale:CGFloat) -> UIImage {

        let imageSourceOptions = [kCGImageSourceShouldCache: false] as CFDictionary
        let imageSource = CGImageSourceCreateWithURL(imageUrl as CFURL, imageSourceOptions)!
    
        let maxdimentionInPixels = max(size.width, size.height)*scale
        let downSampleOptions =
            [kCGImageSourceCreateThumbnailFromImageAlways: true,
             kCGImageSourceShouldCacheImmediately: true,
             kCGImageSourceCreateThumbnailWithTransform: true,
                kCGImageSourceThumbnailMaxPixelSize: maxdimentionInPixels] as CFDictionary
        let downSampledImage = CGImageSourceCreateThumbnailAtIndex(imageSource, 0, downSampleOptions)!
    
        return UIImage(cgImage: downSampledImage)
}

protocol ImageConvectorProcessDelegate: class {
    //completedPart - percent of spent time according wholedelay interval
    func getDataFromImageConvectorProcess(_ completedPart:CGFloat, _ image: UIImage?)
}
class ImageConvertor: NSObject {
    /*weak var delegate: ImageConvectorProcessDelegate?
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
}
