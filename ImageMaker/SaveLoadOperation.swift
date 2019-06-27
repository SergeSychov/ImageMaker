//
//  SaveLoadOperation.swift
//  ImageMaker
//
//  Created by Serge Sychov on 24/06/2019.
//  Copyright © 2019 Serge Sychov. All rights reserved.
//
import UIKit
import Foundation

func copyDataToFile(at:URL, fileName: String) -> Bool{ //not important process
    
    if let fileURL = urlForFileNamed(fileName) as URL? {
        
        //Checks if file exists, remove it
        if FileManager.default.fileExists(atPath: fileURL.path) {
            do {
                //remove old img
                try FileManager.default.removeItem(atPath: fileURL.path)
            } catch let removeError {
                print("not remove img", removeError)
            }
        }
        
        do {
            try FileManager.default.copyItem(at: at, to: fileURL)
            print("copyData done")
            return true
        } catch{
            print("copyData error", error)
            return false
        }
    } else {
        print("copyData couldn't get URL for name")
        return false
    }
}


func urlForFileNamed(_ name:String)-> URL? {
    if let directory = try? FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: false) as URL {
        return directory.appendingPathComponent(name)
    } else {
        return nil
    }
}

func getUrlForExistingFile(_ name:String)-> URL? {
    var retUrl:URL?
    let url = urlForFileNamed(name)
    if url != nil {
        if FileManager.default.fileExists(atPath: url!.path) {
            retUrl = url
        }
    }
    return retUrl
}

func saveArray(resultObjsStorage: [ResultImageObj], name:String) -> Bool{

    if let fileURL = urlForFileNamed(name) as URL? {
        
        var nameStringArray = [String]()
        for item in resultObjsStorage {
            if item.imageName != nil {
                var savedString = item.imageName!
                if item.currentConvertionEffect != nil {//if object hase not compleated conversion
                    savedString = savedString + "_effect_" + item.currentConvertionEffect!
                }
                nameStringArray.append(savedString) //THINK about emty obj
            }
        }
        
        //Checks if file exists, remove it
        if FileManager.default.fileExists(atPath: fileURL.path) {
            do {
                //remove old img
                try FileManager.default.removeItem(atPath: fileURL.path)
            } catch let removeError {
                print("not remove old obj arrays", removeError)
                return false
            }
        }
        
        do {
            try NSKeyedArchiver.archivedData(withRootObject: nameStringArray).write(to: fileURL)
            print("Array saved succesufully")
            return true

        } catch let saveError {
            print("not save array", saveError)
            return false
        }
    } else {
        print("saveArray couldn't get URL for name")
        return false
    }
    //save only image names as strings array
    
}



func getSavedResultStorageWithName(name: String, delegate: ResultImageObjDelegate) -> [ResultImageObj] {
    
    if let fileURL = urlForFileNamed(name) as URL? {

        guard let namesArray = NSKeyedUnarchiver.unarchiveObject(withFile: fileURL.path) as? [String] else {
            print("getSavedResultStorageWithName no archive in file")
            return [ResultImageObj]()
            
        }
        var resultObjsStorage = [ResultImageObj]()
        for item in namesArray {
            var imageName = item
            var effectStr:String?
            if let effectRange = item.range(of: "_effect_"){
                //if there is effect string - convertion didn't compleated, set parameters and start convertion
                imageName = String(item[..<effectRange.lowerBound])
                effectStr = String(item[effectRange.upperBound...])
            }
            resultObjsStorage.append(ResultImageObj(name: imageName, delegate: delegate, notCompleatedEffect: effectStr))
        }
        return resultObjsStorage
        
    } else {
        print("getSavedResultStorageWithName can;t get URL for name")
        return [ResultImageObj]()
    }
}


/*
func getSavedResultStorageFromURL (url: URL, delegate: ResultImageObjDelegate) -> [ResultImageObj]? {
    
    let namesArrayOne = NSKeyedUnarchiver.unarchiveObject(withFile: url.path)
        guard let namesArray = NSKeyedUnarchiver.unarchiveObject(withFile: url.path) as? [String] else { return [ResultImageObj]() }
        var resultObjsStorage = [ResultImageObj]()
        for item in namesArray {
            var imageName = item
            var effectStr:String?
            if let effectRange = item.range(of: "_effect_"){
                //if there is effect string - convertion didn't compleated, set parameters and start convertion
                imageName = String(item[..<effectRange.lowerBound])
               effectStr = String(item[effectRange.upperBound...])
            }
            resultObjsStorage.append(ResultImageObj(name: imageName, delegate: delegate, notCompleatedEffect: effectStr))
        }
        return resultObjsStorage
}*/

func clearStorage(resultObjsStorage: [ResultImageObj])-> Bool{
    var success = true
    for item in resultObjsStorage {
        if !removeFile(named: item.imageName!) {
            print("not all disc storage have cleaned")
            success = false
        }
    }
    return success
}

func saveImageData(data: NSData, imageName: String) -> URL? {
    guard let directory = try? FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: false) as NSURL else {
        return nil
    }
    
    //Checks if file exists, remove it
    if FileManager.default.fileExists(atPath: directory.appendingPathComponent(imageName)!.path) {
        do {
            //remove old img
            try FileManager.default.removeItem(atPath: directory.appendingPathComponent(imageName)!.path)
        } catch let removeError {
            print("not remove img", removeError)
            return nil
        }
    }
    
    do {
        try data.write(to: directory.appendingPathComponent(imageName)!)
        return directory.appendingPathComponent(imageName)
    } catch let saveError {
        print("not save img", saveError)
        return nil
    }
}

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
