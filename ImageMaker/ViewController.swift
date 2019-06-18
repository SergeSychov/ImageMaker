//
//  ViewController.swift
//  ImageMaker
//
//  Created by Serge Sychov on 13/06/2019.
//  Copyright © 2019 Serge Sychov. All rights reserved.
//

import UIKit

class ViewController: UIViewController, UIPopoverPresentationControllerDelegate, UINavigationControllerDelegate, UIImagePickerControllerDelegate, ImageConvectorProcessDelegate {
    
    @IBOutlet weak var workImageView: UIImageView!
    @IBOutlet weak var resultImageView: UIImageView!
    var resStorage = [ResultImageObj]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        choosePicthureContainerView.isHidden = true

        // Do any additional setup after loading the view.
    }
    
    //convert image actions
    @IBAction func convertImageAction(_ sender: UIButton) {

        if sender.restorationIdentifier != nil  && workImageView.image != nil{
            let resImgObj = ResultImageObj(workImageView.image!, sender.restorationIdentifier!)
            resStorage.append(resImgObj)
            if resImgObj.resultImg != nil {
                resultImageView.image = resImgObj.resultImg
            }
        }
    }
    
    //ImageConvectorProcessDelegate
    func getDataFromImageConvectorProcess(_ completedPart: CGFloat, _ image: UIImage?) {
        print("compleated part of convertion: ", completedPart)
        if image != nil {
            print("Image ready")
        }
        
    }
    
    //getting new images
    @IBAction func plusButtonTapped(_ sender: UIButton) {

        let alertcontroller = UIAlertController(title: nil, message:nil, preferredStyle: .actionSheet)
        alertcontroller.addAction(UIAlertAction(title: "take from Photo", style: .default, handler: { (UIAlertAction) in
            self.getImageFrom("Photo")
            self.changeLookOfChoosePictureContainer()
        }))
        
        alertcontroller.addAction(UIAlertAction(title: "use Camera", style: .default, handler: { (UIAlertAction) in
            self.getImageFrom("Camera")
            self.changeLookOfChoosePictureContainer()
        }))
        alertcontroller.addAction(UIAlertAction(title: "load by link", style: .default, handler: { (UIAlertAction) in
            //self.showSafariVC(for:"https://www.google.com/")
            //self.performSegue(withIdentifier: "popEnterURLcontroller", sender: self)
        }))
        alertcontroller.addAction(UIAlertAction(title: "Отмена", style: .cancel, handler: { (UIAlertAction) in
            self.changeLookOfChoosePictureContainer()
        }))
        
        present(alertcontroller, animated: true, completion: nil)
    }
    
    func getImageFrom (_ string: String){
        let imagePickerController = UIImagePickerController()
        imagePickerController.delegate = self
        imagePickerController.allowsEditing = false
        if string == "Photo" {
            imagePickerController.modalPresentationStyle = .popover
            imagePickerController.sourceType = .photoLibrary
        } else if string == "Camera" {
            imagePickerController.modalPresentationStyle = .fullScreen
            imagePickerController.sourceType = UIImagePickerController.SourceType.camera
        } else if string == "Link" {
            
        }
        self.present(imagePickerController, animated: true, completion: nil)
    }
    
    //picker controller Delegate
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        if let image = info[UIImagePickerController.InfoKey.originalImage] as? UIImage {
            workImageView.image = image
        } else {
            //error message
        }
        self.dismiss(animated: true, completion: nil);
    }
    
    //show and hide chooseImageContainer
    @IBOutlet weak var choosePicthureContainerView: UIView!
    @IBAction func tapWorksImageView(_ sender: UITapGestureRecognizer) {
        self.changeLookOfChoosePictureContainer()
    }
    
    @IBAction func shareButtonTapped(_ sender: Any) {
        for item in resStorage {
            print(item.imageName as Any)
        }
    }
    
    func changeLookOfChoosePictureContainer(){
        if choosePicthureContainerView.isHidden {
            choosePicthureContainerView.alpha = 0
            choosePicthureContainerView.isHidden = false;
            UIView .animate(withDuration: 0.4) {
                self.choosePicthureContainerView.alpha = 1
            }
        } else {
            UIView .animate(withDuration: 0.4, animations: {
                self.choosePicthureContainerView.alpha = 0
            }) { (Bool) in
                self.choosePicthureContainerView.isHidden = true
            }
        }
    }
}

