//
//  SaveLoadOperation.swift
//  ImageMaker
//
//  Created by Serge Sychov on 24/06/2019.
//  Copyright © 2019 Serge Sychov. All rights reserved.
//
import UIKit
import Foundation

enum saveLoadOperationError:Error {
    case invalidFileURL
    case invalidImageData
    case invalidEffectName
    case noSuchFilter
}


func urlForFileNamed(_ name:String) throws -> URL {
    do {
        let directory = try FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: false)
        return directory.appendingPathComponent(name)
    } catch {
        print("urlForFileNamed can't return URL", error)
        throw error
    }
}

func getUrlForExistingFile(_ name:String)-> URL? {

    do {
        let url = try urlForFileNamed(name)
        if FileManager.default.fileExists(atPath: url.path) {
            return url
        } else { return nil }
            
    } catch {
        print("getUrlForExistingFile can't get URL for name:", error)
        return nil
    }
}

func saveArray(resultObjsStorage: [ResultImageObj], name:String) -> Bool{

    do {
        let fileURL = try urlForFileNamed(name)
        
        var nameStringArray = [String]()
        for item in resultObjsStorage {
                var savedString = item.imageName
                if item.currentConvertionEffect != nil {//if object hase not compleated conversion
                    savedString = savedString + "_effect_" + item.currentConvertionEffect!
                }
                //save only image's names as strings array
                nameStringArray.append(savedString) //THINK about emty obj
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
    } catch {
        print("saveArray can't get URL for name:", error)
        return false
    }
}


func getStoredResObjNames(name:String) -> [String]{
    do {
        let fileURL = try urlForFileNamed(name)
        guard let namesArray = NSKeyedUnarchiver.unarchiveObject(withFile: fileURL.path) as? [String] else {
            print("getSavedResultStorageWithName no archive in file")
            return [String]()
        }
        return namesArray
    }
    catch {
        print("Get URL from name error:", error)
        return [String]()
    }
}

func setResObjFromStoredName(name:String, delegate:ResultImageObjDelegate ) -> ResultImageObj? {
    var effectStr:String?
    var imageName = name
    
    if let effectRange = name.range(of: "_effect_"){
        //if there is effect string - convertion didn't compleated, set parameters and start convertion
        imageName = String(imageName[..<effectRange.lowerBound])
        effectStr = String(imageName[effectRange.upperBound...])
    }
    
    if let resObj = ResultImageObj(name: imageName, delegate: delegate, notCompleatedEffect: effectStr) {
        return resObj
    } else {
        DispatchQueue.global(qos: .background).async {
            if removeFile(named: imageName) {
                print("not aded to array and removed from disc")
            }
        }
        return nil
    }
}


func getSavedResultStorageWithName(name: String, delegate: ResultImageObjDelegate) -> [ResultImageObj] {

    let namesArray = getStoredResObjNames(name: name)
        
    var resultObjsStorage = [ResultImageObj]()
    for item in namesArray {
        if let resObj = setResObjFromStoredName(name:item, delegate:delegate) {
            resultObjsStorage.append(resObj)
        }
    }
    return resultObjsStorage
}

func clearStorage(resultObjsStorage: [ResultImageObj])-> Bool{
    var success = true
    for item in resultObjsStorage {
        if !removeFile(named: item.imageName) {
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

func copyDataToFile(at:URL, fileName: String) -> Bool{ //not important process
    
    do {
        let fileURL = try urlForFileNamed(fileName)
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
            print("copyDataToFile done")
            return true
        } catch{
            print("copyDataToFile error", error)
            return false
        }
    } catch {
        print("copyDataToFile can't get url for name:", error)
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

//=======================NOT USES IN APP ================================
/*
func getSavedImage(named: String) -> UIImage? {
    
    if let dir = try? FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: false) {
        return UIImage(contentsOfFile: URL(fileURLWithPath: dir.absoluteString).appendingPathComponent(named).path)
    }
    return nil
}*/

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
} */
 
//=======================================================================
