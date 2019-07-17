//
//  URLworking.swift
//  ImageMaker
//
//  Created by Serge Sychov on 13/07/2019.
//  Copyright © 2019 Serge Sychov. All rights reserved.
//

import UIKit
import Foundation

extension ViewController: URLSessionDelegate, URLSessionDownloadDelegate, UITextFieldDelegate {

    func downloadImageFromURL(_ url: URL){
        let config = URLSessionConfiguration.default
        let session = URLSession(configuration: config, delegate: self, delegateQueue: nil)
        
        // Don't specify a completion handler here or the delegate won't be called
        session.downloadTask(with: url).resume()
    }

    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didFinishDownloadingTo location: URL) {
        if let data = try? Data(contentsOf: location) as NSData, let _ = UIImage(data: data as Data) {
            DispatchQueue.main.async {
                //self.resultImageView.image = UIImage(data: data)
                if let imageUrl = saveImageData(data: data, imageName: tempPhotoName) as  URL? {
                    self.userDidChoosedNewImg(imageUrl)
                } else {
                    //error catchin URL
                    print("Don't catch URL of source")
                }
            }
        } else {
            session.invalidateAndCancel()
            print ("Not right URL or not image")
            //fatalError("Cannot load the image")
        }
    }
    
    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didWriteData bytesWritten: Int64, totalBytesWritten: Int64, totalBytesExpectedToWrite: Int64) {
        
        //only for test--------------------------------
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useKB, .useMB]
        //let num = formatter.
        let written = formatter.string(fromByteCount: totalBytesWritten)
        let expected = formatter.string(fromByteCount: totalBytesWritten)
        //print("Downloaded \(written) / \(expected)")
        //print("Downloaded", Double(bitPattern: UInt64(totalBytesWritten)) / Double(bitPattern: UInt64(totalBytesExpectedToWrite)))
        //------------------------------------------------------
        if totalBytesExpectedToWrite > 0 && totalBytesWritten < totalBytesExpectedToWrite{
            DispatchQueue.main.async {
                print("Downloaded", Double(bitPattern: UInt64(totalBytesWritten)) / Double(bitPattern: UInt64(totalBytesExpectedToWrite)))
                self.progressIndicatorView.readyPart = Double(bitPattern: UInt64(totalBytesWritten)) / Double(bitPattern: UInt64(totalBytesExpectedToWrite))
            }
        }
    }
}
