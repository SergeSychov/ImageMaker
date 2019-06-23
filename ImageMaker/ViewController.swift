//
//  ViewController.swift
//  ImageMaker
//
//  Created by Serge Sychov on 13/06/2019.
//  Copyright © 2019 Serge Sychov. All rights reserved.
//

import UIKit

class ViewController: UIViewController, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout, UIPopoverPresentationControllerDelegate, UINavigationControllerDelegate, UIImagePickerControllerDelegate, ResultImageObjDelegate {

    
    @IBOutlet weak var inputImageView: UIImageView!
    @IBOutlet weak var resultImageView: UIImageView!
    @IBOutlet weak var collectionOfResultImg: UICollectionView!
    
    var workImage: UIImage? //image what will be uising for convertion
    var resImgObjStorage = [ResultImageObj]()
    var resuableImageStorageCache = NSCache<NSString, UIImage>()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.setProperties()
        choosePicthureContainerView.isHidden = true
        
        //add observeres to save main variables
        NotificationCenter.default.addObserver(self, selector: #selector(appGoesOff), name: UIApplication.willResignActiveNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(appGoesOff), name: UIApplication.willTerminateNotification, object: nil)
        // Do any additional setup after loading the view.
    }
    
    //convert image actions
    @IBAction func convertImageAction(_ sender: UIButton) {

        if (sender.restorationIdentifier != nil) && (workImage != nil) {
            if(resImgObjStorage.count > 0){
                resImgObjStorage.last!.applyImgConvertion(workImage!, sender.restorationIdentifier)
            }
        }
    }
    
    //ImageConvectorProcessDelegate
    func changedImgWithName(resultImage: UIImage, resultImageObj: ResultImageObj) {
        print("changed image with name: " + resultImageObj.imageName!)
        //set new image in cache
        resuableImageStorageCache.setObject(resultImage, forKey: NSString(string: resultImageObj.imageName!))
        //find resultImageObj index in storage
        let indexObj =  resImgObjStorage.firstIndex(of: resultImageObj)
        if indexObj != nil {
            if (indexObj == resImgObjStorage.count-1){ //if this resultObj is last in storage
                workImage = resultImage
                resultImageView.image = resultImage
            }
            collectionOfResultImg.reloadItems(at:[IndexPath(row: indexObj!, section: 0)])
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
        if #available(iOS 11.0, *) {
            
            if let imageUrl = info[UIImagePickerController.InfoKey.imageURL] as? URL {
                let image = loadImage(imageUrl:imageUrl , size: self.inputImageView.bounds.size, scale:2)
                didChoosedNewImg(image)
            }
        } else {
            if let imgUrl = info[UIImagePickerController.InfoKey.referenceURL] as? URL{

                let localPath = NSTemporaryDirectory().appending(imgUrl.lastPathComponent)
                let photoURL = URL.init(fileURLWithPath: localPath)
                let image = loadImage(imageUrl:photoURL , size: self.inputImageView.bounds.size, scale:2)
                didChoosedNewImg(image)
            }
        }
        self.dismiss(animated: true, completion: nil);
    }
    
    func didChoosedNewImg(_ image:UIImage){
        //1. set new work Image
        workImage = image
        //2. set input ImageView
        inputImageView.image = image
        //3. clear result Image view
        resultImageView.image = nil
        //3. if current cell hasen't result Image add new cell
        if (resImgObjStorage.count == 0) || (resImgObjStorage.last?.imageName != nil){
            addNewEmtyObjAndNewCollectionCellandGoToRightPosition()
        }
    }
    
    func addNewEmtyObjAndNewCollectionCellandGoToRightPosition(){
        //create new emty resultObj add it to result storage aary
        let newResultImageObj = ResultImageObj(nil, delegate: self)
        self.resImgObjStorage.append(newResultImageObj)
        //and add new cell for collection View
        self.collectionOfResultImg.performBatchUpdates({
            self.collectionOfResultImg.insertItems(at: [IndexPath(item: resImgObjStorage.count-1, section: 0)])
        }) { (true) in
            self.collectionOfResultImg.selectItem(at: IndexPath(item: self.resImgObjStorage.count-1, section: 0), animated: true, scrollPosition: .left)
        }
    }
  
    //show and hide chooseImageContainer
    @IBOutlet weak var choosePicthureContainerView: UIView!
    @IBAction func tapWorksImageView(_ sender: UITapGestureRecognizer) {
        self.changeLookOfChoosePictureContainer()
    }
    
    @IBAction func shareButtonTapped(_ sender: Any) {
        for item in resImgObjStorage {
            print(item as Any)
        }
    }
    
    //collection view data sourse
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        if (resImgObjStorage.count>0){
            return resImgObjStorage.count
        } else {
            return 0
        }
    }
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "resultImgCell", for: indexPath)
        let resultObj = resImgObjStorage[indexPath.row]
        //need guard this
        let imgView = cell.contentView.viewWithTag(1) as! UIImageView

        if resultObj.imageName != nil {
            if let image = resuableImageStorageCache.object(forKey: NSString(string: resultObj.imageName!)){
                imgView.image = image
            } else {
                if let image = resImgObjStorage[indexPath.row].image {
                    imgView.image = image
                    resuableImageStorageCache.setObject(image, forKey: NSString(string: resultObj.imageName!))
                }
            }
        } else {
            imgView.image = nil
        }

        return cell
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
        let needOffset = collectionView.contentSize.width - collectionView.frame.size.width + 100
        
        if needOffset < 0 {
            return UIEdgeInsets(top: 0, left: -(needOffset), bottom: 0, right: 0)
        } else {
            return UIEdgeInsets(top: 0, left:0, bottom: 0, right: 100)
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
    
    func setProperties (){
        DispatchQueue.global(qos: .userInitiated).async {
            let inputImage = getSavedImage(named: inputImageName)
            let workImage = getSavedImage(named: workImageName)
            let resultsStorage = getSavedResultStorage(delegate: self)
            DispatchQueue.main.async {
                print("all properties have getted")
                if inputImage != nil {
                    self.inputImageView.image = inputImage
                    self.workImage = inputImage //in case if cant get saved workImage
                }
                
                if workImage != nil {
                    self.workImage = workImage
                }
                
                if resultsStorage != nil {
                    if(resultsStorage!.count > 0 ){
                        self.resImgObjStorage = resultsStorage!
                        self.collectionOfResultImg.reloadData()
                        if self.resuableImageStorageCache.object(forKey:NSString(string: (resultsStorage?.last?.imageName!)!)) != nil {
                            self.resultImageView.image = self.resuableImageStorageCache.object(forKey:NSString(string: (resultsStorage!.last!.imageName!)))
                        } else {
                            self.resultImageView.image = resultsStorage!.last!.image
                        }
                        self.collectionOfResultImg.selectItem(at: IndexPath(row: self.resImgObjStorage.count - 1, section: 0), animated: true, scrollPosition: .left)
                    } else {
                        self.addNewEmtyObjAndNewCollectionCellandGoToRightPosition()
                    }
                } else {
                   self.resImgObjStorage = [ResultImageObj]()
                }
            }
        }
        
    }
    
    
    @objc func appGoesOff() {
        self.saveMainProperties()
    }
    override func didReceiveMemoryWarning() {
        self.saveMainProperties()
    }
    
    func saveMainProperties (){
        //save input image with name and save name to user default
        let inputImage = self.inputImageView.image
        DispatchQueue.global(qos: .background).async {
            if inputImage != nil{
                if saveImage(image: inputImage!, name: inputImageName) {
                    print("Inpute image saved")
                }
            }
            
            if self.workImage != nil{
                if saveImage(image: self.workImage!, name: workImageName) {
                    print("Work image saved")
                }
            }
            if self.resImgObjStorage.count > 0 {
                if saveArray(resultObjsStorage: self.resImgObjStorage){
                    print("resultObjsStorage saved")
                }
            }
            DispatchQueue.main.async {
                print("all properties have saved")
            }
        }
        
        //save works image with name and save name to user default
        //save storage
    }
    
    @IBAction func clearArhciveTapped(_ sender: Any) {
        DispatchQueue.global(qos: .userInitiated).async {
            if clearStorage(resultObjsStorage: self.resImgObjStorage){
                
                print("Archive cleaned succesifully")
            }
            DispatchQueue.main.async {

                var indexPathes = [IndexPath]()
                for item in self.resImgObjStorage.indices {
                    indexPathes.append(IndexPath(item: item, section: 0))
                }
                self.resImgObjStorage = [ResultImageObj]()
                self.resuableImageStorageCache.removeAllObjects()
                self.collectionOfResultImg.performBatchUpdates({
                    self.collectionOfResultImg.deleteItems(at: indexPathes)
                }) { (true) in
                    self.resultImageView.image = nil
                    self.workImage = self.inputImageView.image
                }
            }
        }
        if clearStorage(resultObjsStorage: self.resImgObjStorage){
            resuableImageStorageCache.removeAllObjects()
            collectionOfResultImg.reloadData()
            print("Archive cleaned succesifully")
        }
    }
}

