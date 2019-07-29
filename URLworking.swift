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
        self.loadIndicatorView.showSelfAnimated()
        session.downloadTask(with: url).resume()
    }

    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didFinishDownloadingTo location: URL) {
        if let data = try? Data(contentsOf: location) as NSData, let _ = UIImage(data: data as Data) {
            DispatchQueue.main.async {
                //self.resultImageView.image = UIImage(data: data)
                if let imageUrl = saveImageData(data: data, imageName: tempPhotoName) as  URL? {
                    self.userDidChoosedNewImg(imageUrl)
                } else {
                    self.showNotSuccesAlert()
                }
                self.loadIndicatorView.hideSelfAnimated()
            }
        } else {
            DispatchQueue.main.async {
                self.showNotSuccesAlert()
                self.loadIndicatorView.hideSelfAnimated()
            }
            session.invalidateAndCancel()
        }
    }
    
    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didWriteData bytesWritten: Int64, totalBytesWritten: Int64, totalBytesExpectedToWrite: Int64) {
        if totalBytesExpectedToWrite > 0 && totalBytesWritten < totalBytesExpectedToWrite{
            DispatchQueue.main.async {
                self.loadIndicatorView.readyPart = Double(bitPattern: UInt64(totalBytesWritten)) / Double(bitPattern: UInt64(totalBytesExpectedToWrite))
            }
        }
    }
    func showNotSuccesAlert(){
        let alertcontroller = UIAlertController(title: "Can't load image by this link", message:"try another", preferredStyle: .alert)
        present(alertcontroller, animated: true, completion: nil)
        alertcontroller.addAction(UIAlertAction(title: "Ok", style: .cancel, handler: { (UIAlertAction) in
            //self.changeLookOfChoosePictureContainer()
        }))
    }
}
