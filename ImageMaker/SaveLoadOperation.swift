//
//  SaveLoadOperation.swift
//  ImageMaker
//
//  Created by Serge Sychov on 24/06/2019.
//  Copyright © 2019 Serge Sychov. All rights reserved.
//
import UIKit
import Foundation

let storageArrayName = "TaskManagerStorage.tskmng"
let inputImageName = "TaskManageInputImage.jpeg"
let workImageName = "TaskManageWorkImage.jpeg"

func urlForFileNamed(_ name:String)-> NSURL? {
    if let directory = try? FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: false) as NSURL {
        return directory.appendingPathComponent(name) as NSURL?
    } else {
        return nil
    }
}

func saveArray(resultObjsStorage: [ResultImageObj], name:String = storageArrayName) -> Bool{
    guard let directory = try? FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: false) as NSURL else {
        return false
    }
    //save only image names
    var nameStringArray = [String]()
    for item in resultObjsStorage {
        nameStringArray.append(item.imageName!) //THINK about emty obj
    }
    
    //Checks if file exists, remove it
    if FileManager.default.fileExists(atPath: directory.appendingPathComponent(name)!.path) {
        do {
            //remove old img
            try FileManager.default.removeItem(atPath: directory.appendingPathComponent(name)!.path)
        } catch let removeError {
            print("not remove obj arrays", removeError)
            return false
        }
    }
    
    do {
        try NSKeyedArchiver.archivedData(withRootObject: nameStringArray).write(to: directory.appendingPathComponent(name)!)
        return true
    } catch let saveError {
        print("not save array", saveError)
        return false
    }
}

func getSavedResultStorage (named: String = storageArrayName, delegate: ResultImageObjDelegate) -> [ResultImageObj]? {
    if let dir = try? FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: false) {
        guard let namesArray = NSKeyedUnarchiver.unarchiveObject(withFile: URL(fileURLWithPath: dir.absoluteString).appendingPathComponent(named).path) as? [String] else { return [ResultImageObj]() }
        var resultObjsStorage = [ResultImageObj]()
        for item in namesArray {
            resultObjsStorage.append(ResultImageObj(name: item, delegate: delegate))
        }
        return resultObjsStorage
    }
    return nil
}

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
