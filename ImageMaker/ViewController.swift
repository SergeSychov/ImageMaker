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


class ViewController: UIViewController, UIPopoverPresentationControllerDelegate, UINavigationControllerDelegate, UIImagePickerControllerDelegate, ResultImageObjDelegate {


    @IBOutlet weak var inputImageView: UIImageView!
    @IBOutlet weak var resultImageView: UIImageView!
    @IBOutlet weak var collectionOfResultImg: UICollectionView!
    @IBOutlet weak var loadIndicatorView: LinearIndicatorView!
    @IBOutlet weak var progressIndicatorView: LinearIndicatorView!
    @IBOutlet weak var progressRadialIndicatorView: RadialIndicatorView!
    
    var inputImageUrl: URL? //need only for save
    var curentResObj:ResultImageObj?
    var resuableImageStorageCache = NSCache<NSString, UIImage>()
    
    var alertURLController: UIAlertController?

    var resImgObjNamesStorage = [String](){
        didSet{
            DispatchQueue.global(qos: .background).async {
                self.saveObjsNamesToDisc()
            }
        }
    }
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
        
        //set initial view of indicator
        progressIndicatorView.alpha = 0
        progressRadialIndicatorView.alpha = 0
        
        collectionOfResultImg.allowsSelection = true
        collectionOfResultImg.allowsMultipleSelection = false
        if resImgObjNamesStorage.count > 0 {
            collectionOfResultImg.selectItem(at: IndexPath(item: 0, section: 0), animated: false, scrollPosition: .right)
        }
        
        super.viewDidLoad()
    }

    //getting new images
    func userDidChoosedNewImg(_ imageURL:URL){
        do {
            //2. set input ImageView
            inputImageView.image = try loadImage(imageUrl: imageURL, size: inputImageView.bounds.size)
            inputImageUrl  = imageURL
            DispatchQueue.global(qos: .default).async {
                if copyDataToFile(at: imageURL, fileName: inputImageName){
                    DispatchQueue.main.async {
                        print("Input image saved to app storage")
                    }
                }
            }
            
            //3. clear result Image view - use this value as flag of setted new image
            resultImageView.image = nil //as flag for creating new cell at convertion action
            isUserChoosedNewImage = true
        } catch {
            print("userDidChoosedNewImg() some error: ", error)
        }
        
    }
    //convert image actions
    @IBAction func convertImageAction(_ sender: UIButton) {
        progressIndicatorView.readyPart = 0.00
        progressRadialIndicatorView.readyPart = 0.00

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
    func changedImgResultObj(resultImageObjName: String, error: Error?, percentageOfCompletion: Double) {
       // print("changedImgResultObj call")

        if error != nil {
            print("changedImgResultObj some error occures: ", error as Any)
        } else {
            if let indexObj =  resImgObjNamesStorage.firstIndex(of: resultImageObjName) {
                
                if (indexObj == 0) {
                    progressIndicatorView.readyPart = percentageOfCompletion
                    progressRadialIndicatorView.readyPart = percentageOfCompletion
                }
                
                if let imgCell = collectionOfResultImg.cellForItem(at:IndexPath(row: indexObj, section: 0)) as? ImgCell {
                    imgCell.readyImg = percentageOfCompletion
                }
                
                if percentageOfCompletion == 1 {
                    if (indexObj == 0){ //if this resultObj is last in storage
                        resultImageView.image = loadImage(imageName:resultImageObjName, size:resultImageView.bounds.size)
                        progressIndicatorView.readyPart = percentageOfCompletion
                        progressRadialIndicatorView.readyPart = percentageOfCompletion
                    }
                    resuableImageStorageCache.removeObject(forKey: resultImageObjName as NSString)//for renew image in Cache in collection delegate calling
                    collectionOfResultImg.reloadItems(at:[IndexPath(item: indexObj, section: 0)])
                }
            }
        }
    }

    @IBAction func plusButtonTapped(_ sender: UIButton) {

        let alertcontroller = UIAlertController(title: nil, message:nil, preferredStyle: .actionSheet)
        alertcontroller.addAction(UIAlertAction(title: "Take from Photo", style: .default, handler: { (UIAlertAction) in
            self.getImageFrom("Photo")
            self.changeLookOfChoosePictureContainer()
        }))
        
        alertcontroller.addAction(UIAlertAction(title: "Use Camera", style: .default, handler: { (UIAlertAction) in
            self.getImageFrom("Camera")
            self.changeLookOfChoosePictureContainer()
        }))
        alertcontroller.addAction(UIAlertAction(title: "Load by link", style: .default, handler: { (UIAlertAction) in
            self.showURLAllert()
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
        
        if resImgObjNamesStorage.count > 0 {
            var cellectedCelIndexPatch = collectionOfResultImg.indexPathsForSelectedItems?.first
            if cellectedCelIndexPatch == nil {
                cellectedCelIndexPatch = IndexPath(item: 0, section: 0)
            }
            do {
                let imageToShare = try UIImage(contentsOfFile: urlForFileNamed(resImgObjNamesStorage[cellectedCelIndexPatch!.row]).path)
                
                let alertController = UIAlertController(title: "Save image to photo library", message:nil, preferredStyle: .actionSheet)
                
                alertController.addAction(UIAlertAction(title: "Ok", style: .default, handler: { (UIAlertAction) in
                    UIImageWriteToSavedPhotosAlbum(imageToShare!, nil, nil, nil)
                }))
                
                alertController.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: { (UIAlertAction) in
                }))
                
                present(alertController, animated: true, completion: nil)
                
                /* //Use activity
                 let imageToShare = try UIImage(contentsOfFile: urlForFileNamed(resImgObjNamesStorage[cellectedCelIndexPatch.row]).path)
                 let activityViewController = UIActivityViewController(activityItems: [imageToShare!], applicationActivities: nil)
                 activityViewController.popoverPresentationController?.sourceView = self.view
                 activityViewController.excludedActivityTypes = [.assignToContact, .airDrop,.mail,.message, .airDrop, .postToFacebook,.copyToPasteboard ]
                 self.present(activityViewController, animated: true, completion: nil)
                 */
            }
            catch {
                print("shareButtonTapped error: ",error)
            }
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
            if (resImgObjNamesStorage.count > 0) && !isUserChoosedNewImage {
                
                curentResObj = ResultImageObj(name: resImgObjNamesStorage.first!, delegate: self, notCompleatedEffect: nil)
                
                if let image = loadImage(imageName:resImgObjNamesStorage.first!, size:resultImageView.bounds.size){
                    resultImageView.image = image
                }
                
                //check image with names and delete BAD images (can't load image)
                DispatchQueue.global(qos: .background).async {
                    var bedDataFilesPatches = [IndexPath]()
                    var renewedNameStorage = [String]()
                    for  item in self.resImgObjNamesStorage {
                        do {
                            if let _ = CIImage(contentsOf: try urlForFileNamed(item)){
                                renewedNameStorage.append(item)
                            } else {
                                bedDataFilesPatches.append(IndexPath(item: self.resImgObjNamesStorage.firstIndex(of: item)!, section: 0))
                            }
                        }
                        catch {
                            bedDataFilesPatches.append(IndexPath(item: self.resImgObjNamesStorage.firstIndex(of: item)!, section: 0))
                        }
                        
                    }
                    if bedDataFilesPatches.count > 0 {
                        DispatchQueue.main.async {
                            
                            self.resImgObjNamesStorage = renewedNameStorage
                            self.collectionOfResultImg.performBatchUpdates({
                                self.collectionOfResultImg.deleteItems(at: bedDataFilesPatches)
                            }) { (true) in
                                self.collectionOfResultImg.reloadData()
                            }
                        }
                    }
                }
                    
            }
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

