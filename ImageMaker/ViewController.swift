//
//  ViewController.swift
//  ImageMaker
//
//  Created by Serge Sychov on 13/06/2019.
//  Copyright © 2019 Serge Sychov. All rights reserved.
//

import UIKit

//definition for saving  files
let storageArrayName = "TaskManagerStorage.tskmng"
let inputImageName = "TaskManageInputImage.jpeg"
let tempPhotoName = "tempPhotoName.jpeg"
let workImageURL = "WorkImageURL"


class ViewController: UIViewController, UICollectionViewDataSource, UICollectionViewDataSourcePrefetching, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout, UIPopoverPresentationControllerDelegate, UINavigationControllerDelegate, UIImagePickerControllerDelegate, ResultImageObjDelegate {


    @IBOutlet weak var inputImageView: UIImageView!
    @IBOutlet weak var resultImageView: UIImageView!
    @IBOutlet weak var collectionOfResultImg: UICollectionView!

    var inputImageUrl: URL? //need only for save
    var resImgObjNamesStorage = [String]()
    var curentResObj:ResultImageObj?
    var resuableImageStorageCache = NSCache<NSString, UIImage>()
    
    var isUserChoosedNewImage: Bool{
        get {
            let isUserChoosed = UserDefaults.standard.bool(forKey: "isUserChoosedNewImage")
            return isUserChoosed //UserDefaults.standard.bool(forKey: "isUserChoosedNewImage")
        }
        set (newValue){
            
            UserDefaults.standard.set(newValue, forKey: "isUserChoosedNewImage")
        }
    }

    
    override func viewDidLoad() {

        choosePicthureContainerView.isHidden = true
        if #available(iOS 10.0, *){
           self.collectionOfResultImg.prefetchDataSource = self
        }

        getMainViewsPropertiesAndSetViews() //renew saved images
        
        //add observeres to save main variables
        NotificationCenter.default.addObserver(self, selector: #selector(appGoesOff), name: UIApplication.willResignActiveNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(appGoesOff), name: UIApplication.willTerminateNotification, object: nil)
        // Do any additional setup after loading the view.
        super.viewDidLoad()
    }

    override func didReceiveMemoryWarning() {
        saveObjsNamesToDisc()
    }
    
    @objc func appGoesOff() {
        saveObjsNamesToDisc()
    }
    
    //getting new images
    func userDidChoosedNewImg(_ imageURL:URL){
        do {
            //2. set input ImageView
            inputImageView.image = try loadImage(imageUrl: imageURL, size: inputImageView.bounds.size)
            inputImageUrl  = imageURL
            
            //3. clear result Image view - use this value as flag of setted new image
            resultImageView.image = nil //as flag for creating new cell at convertion action
            isUserChoosedNewImage = true
        } catch {
            print("userDidChoosedNewImg() some error: ", error)
        }
        
    }
    //convert image actions
    @IBAction func convertImageAction(_ sender: UIButton) {
        if isUserChoosedNewImage { //if it's new image
            //create new empty resultObj add it to result storage aray
            let newResObj = ResultImageObj(inputImageUrl!, delegate: self)
                if newResObj != nil {
                    curentResObj = newResObj
                    resImgObjNamesStorage.insert(newResObj!.imageName, at: 0)
                
                //and add new cell for collection View
                    collectionOfResultImg.performBatchUpdates({
                    collectionOfResultImg.insertItems(at: [IndexPath(item: 0, section: 0)])
                }) { (true) in
                    self.collectionOfResultImg.selectItem(at: IndexPath(item: 0, section: 0), animated: true, scrollPosition: .right)
                }
                isUserChoosedNewImage = false //now new image seted as input for convertion
            }
        }
        
        if sender.restorationIdentifier != nil {
            if(resImgObjNamesStorage.count > 0) && (curentResObj != nil) {
                curentResObj!.applyImgConvertionWith(sender.restorationIdentifier!)
            }
        } else {
            print("Button without restorationIdentifier!")
        }
    }
    
        //imageResultObj DELEGATE
    func changedImgResultObj(resultImageObjName: String, error: Error?) {
        print("changedImgResultObj call")
        if error != nil {
            print("changedImgResultObj some error occures: ", error as Any)
        } else {
            if let indexObj =  resImgObjNamesStorage.firstIndex(of: resultImageObjName) {
                if (indexObj == 0){ //if this resultObj is last in storage
                    if let image = loadImage(imageName:resultImageObjName, size:resultImageView.bounds.size){
                        resultImageView.image = image
                    }
                }
                resuableImageStorageCache.removeObject(forKey: resultImageObjName as NSString)//for renew image in Cache in collection delegate calling
                collectionOfResultImg.reloadItems(at:[IndexPath(row: indexObj, section: 0)])
            }
        }
    }

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

        if picker.sourceType == UIImagePickerController.SourceType.camera {
            if let image = info[UIImagePickerController.InfoKey.originalImage] as? UIImage{
                
                if let imageData = image.jpegData(compressionQuality: 1) as NSData? {
                    if let imageUrl = saveImageData(data: imageData, imageName: tempPhotoName) as  URL? {
                        userDidChoosedNewImg(imageUrl)
                    } else {
                        //error catchin URL
                        print("Don't catch URL of source")
                    }
                }
            }
        } else { //in taht case photo or photoLibrary
            if #available(iOS 11.0, *) {
                
                if let imageUrl = info[UIImagePickerController.InfoKey.imageURL] as? URL {
                    userDidChoosedNewImg(imageUrl)
                } else {
                    //error catchin URL
                    print("Don't catch URL of source")
                }
            } else {
                if let imgUrl = info[UIImagePickerController.InfoKey.referenceURL] as? URL{
                    
                    let localPath = NSTemporaryDirectory().appending(imgUrl.lastPathComponent)
                    let photoURL = URL.init(fileURLWithPath: localPath)
                    userDidChoosedNewImg(photoURL)
                } else {
                    //error catchin URL
                    print("Don't catch URL of source")
                }
            }
        }
        self.dismiss(animated: true, completion: nil);
    }

    //show and hide chooseImageContainer
    @IBOutlet weak var choosePicthureContainerView: UIView!
    @IBAction func tapWorksImageView(_ sender: UITapGestureRecognizer) {
        self.changeLookOfChoosePictureContainer()
    }
    
    @IBAction func shareButtonTapped(_ sender: Any) {
        /*for item in resImgObjStorage {
            print(item as Any)
        }*/
    }
    

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
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "resultImgCell", for: indexPath)
        let resultObjName = resImgObjNamesStorage[indexPath.row]
        //need guard this
        let imgView = cell.contentView.viewWithTag(1) as! UIImageView

        /*
        if resultObj.convertProcessDone == 1.0 {
        } else {
            imgView.image = nil
        }*/
        
        if let image = resuableImageStorageCache.object(forKey: resultObjName as NSString){
            imgView.image = image
        } else {
            let size = imgView.bounds.size
            DispatchQueue.global(qos: .userInitiated).async {
                if let image =  loadImage(imageName:resultObjName, size: size){
                    DispatchQueue.main.async {
                        self.resuableImageStorageCache.setObject(image, forKey:resultObjName as NSString)
                        self.collectionOfResultImg.reloadItems(at: [indexPath])
                    }
                }
            }
        }

        return cell
    }
    
    func configureCell(_ cell: UICollectionViewCell){
        
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
    
    func collectionView(_ collectionView: UICollectionView, shouldDeselectItemAt indexPath: IndexPath) -> Bool {
        return true
    }
    
    func collectionView(_ collectionView: UICollectionView, didDeselectItemAt indexPath: IndexPath) {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "resultImgCell", for: indexPath)
        //let resultObj = resImgObjNamesStorage[indexPath.row]
        //print("resultObj hase name: ", resultObj.imageName)
        cell.isHighlighted = true
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

    func saveObjsNamesToDisc(){
        if saveArray(resultObjsNames: resImgObjNamesStorage, name: storageArrayName){
            print("resultObjsStorage saved")
        }
    }
    
    func getMainViewsPropertiesAndSetViews (){

        //chek input image
        if let inputUrl = getUrlForExistingFile(inputImageName){
            self.inputImageUrl = inputUrl
            
            do {
                self.inputImageView.image = try loadImage(imageUrl: inputImageUrl!, size: self.inputImageView.bounds.size)
                self.resultImageView.image = nil

            } catch {
                print("getMainViewsPropertiesAndSetViews get inputImageView error: ", error)
                self.inputImageUrl = nil
                self.inputImageView.image = nil
                self.resultImageView.image = nil
                self.curentResObj = nil
                self.isUserChoosedNewImage = false
                welcomeUser()
            }
        } else { //at start
            self.inputImageUrl = nil
            self.inputImageView.image = nil
            self.resultImageView.image = nil
            self.curentResObj = nil
            self.isUserChoosedNewImage = false
            welcomeUser()
        }

        //get resultsObjsNamesArray
        if let _ = getUrlForExistingFile(storageArrayName){
            resImgObjNamesStorage = getStoredResObjNames(name: storageArrayName)
        }
    }
    
    func welcomeUser (){
        print("Hi guys!")
        changeLookOfChoosePictureContainer()
    }
    
    @IBAction func clearArhciveTapped(_ sender: Any) {
        DispatchQueue.global(qos: .userInitiated).async {

            for item in self.resImgObjNamesStorage {
                if !removeFile(named: item) {
                    print("not all disc storage have cleaned")
                }
            }
            DispatchQueue.main.async {
                var indexPathes = [IndexPath]()
                for item in self.resImgObjNamesStorage.indices {
                    indexPathes.append(IndexPath(item: item, section: 0))
                }
                self.resImgObjNamesStorage = [String]()
                self.resuableImageStorageCache.removeAllObjects()
                self.collectionOfResultImg.performBatchUpdates({
                    self.collectionOfResultImg.deleteItems(at: indexPathes)
                }) { (true) in
                    self.resultImageView.image = nil
                    self.isUserChoosedNewImage = true //set flag that imput image is new for work
                }
            }
        }
    }
}

