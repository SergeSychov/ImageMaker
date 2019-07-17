//
//  CollectionExtention.swift
//  ImageMaker
//
//  Created by Serge Sychov on 16/07/2019.
//  Copyright © 2019 Serge Sychov. All rights reserved.
//

import Foundation
import UIKit


class ImgCell: UICollectionViewCell {
    
    @IBOutlet weak var delCellButton: UIButton!
    
    var indicatorView:RadialIndicatorView? = nil
    var readyImg = 1.00 {
        didSet (newValue) {
            if newValue < 1.00 {
                
                if indicatorView == nil {
                    indicatorView = RadialIndicatorView(frame: self.bounds)
                    indicatorView!.backgroundColor = UIColor.init(white: 0.5, alpha: 0.5)
                    self.addSubview(indicatorView!)
                }
                indicatorView!.readyPart = newValue
            } else {
                if indicatorView != nil {
                    indicatorView!.removeFromSuperview()
                    indicatorView = nil
                }
            }
        }
    }
}

extension ViewController: UICollectionViewDataSource, UICollectionViewDataSourcePrefetching, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout {

    //collection view data sourse
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        if (resImgObjNamesStorage.count>0){
            //print("Numbers of rows: ",resImgObjNamesStorage.count)
            return resImgObjNamesStorage.count
        } else {
            return 0
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "resultImgCell", for: indexPath) as! ImgCell
        let resultObjName = resImgObjNamesStorage[indexPath.row]
        let imgView = cell.contentView.viewWithTag(1) as! UIImageView
        
        if let image = resuableImageStorageCache.object(forKey: resultObjName as NSString){
            imgView.image = image
        } else {
            imgView.image = nil
            let activityIndicator = UIActivityIndicatorView(style: .whiteLarge)
            activityIndicator.frame = cell.contentView.bounds
            cell.addSubview(activityIndicator)
            activityIndicator.startAnimating()
            
            let size = imgView.bounds.size
            DispatchQueue.global(qos: .userInitiated).async {
                //if let image =  loadImage(imageName:resultObjName, size: size){
                let image =  loadImage(imageName:resultObjName, size: size)
                DispatchQueue.main.async {
                    activityIndicator.stopAnimating()
                    activityIndicator.removeFromSuperview()
                    if image != nil {
                        self.resuableImageStorageCache.setObject(image!, forKey:resultObjName as NSString)
                        self.collectionOfResultImg.reloadItems(at: [indexPath])
                    }
                }
            }
        }
        
       if cell.isSelected{
            cell.delCellButton.isHidden = false
        } else {
            cell.delCellButton.isHidden = true
        }
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, prefetchItemsAt indexPaths: [IndexPath]) {
        let side = collectionView.bounds.height > collectionView.bounds.width ? collectionView.bounds.width : collectionView.bounds.height
        
        for indexPath in indexPaths {
            //print(indexPath)
            let resultObjName = self.resImgObjNamesStorage[indexPath.row]
            if  self.resuableImageStorageCache.object(forKey:resultObjName as NSString) == nil{
                DispatchQueue.global(qos: .userInitiated).async {
                    
                    if let image =  loadImage(imageName: resultObjName, size: CGSize(width: side, height: side)){
                        DispatchQueue.main.async {
                            self.resuableImageStorageCache.setObject(image, forKey:resultObjName as NSString)
                        }
                    }
                }
            }
        }
    }

    //collection view delegate
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        
        if let cell = collectionView.cellForItem(at: indexPath) as? ImgCell{
            cell.isSelected = true
            resultImageView.image = loadImage(imageName: resImgObjNamesStorage[indexPath.row], size:resultImageView.bounds.size)
            if indexPath != IndexPath(item: 0, section: 0){ //don't allow add the existing img to collection
                self.addToCollectionCurrentImageButton.isEnabled = false

                cell.delCellButton.isHidden = false //enable to delete not first cell in any others cases - hide dell button
            } else {
                self.addToCollectionCurrentImageButton.isEnabled = true
                cell.delCellButton.isHidden = true
            }
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, didDeselectItemAt indexPath: IndexPath) {
        if let cell = collectionView.cellForItem(at: indexPath) as? ImgCell{
            cell.isSelected = false
            cell.delCellButton.isHidden = true
        }
    }
    
    //collection view flow layout delegate
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let height = collectionView.frame.size.height-2.0
        return CGSize(width: height, height: height)
    }
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return 1.0
    }
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        return 1.0
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        return UIEdgeInsets(top: 0, left:100, bottom: 0, right: 0)
    }
    
}
