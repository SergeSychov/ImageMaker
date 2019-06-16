//
//  ImageConvertor.swift
//  ImageMaker
//
//  Created by Serge Sychov on 16/06/2019.
//  Copyright © 2019 Serge Sychov. All rights reserved.
//

import UIKit

class ImageConvertor: NSObject {
    public class func convertImage(_ image: UIImage?, _ effect: String) -> UIImage? {
        if  image != nil {
            print(effect)
            return image
        } else {
            return nil
        }
    }
}
