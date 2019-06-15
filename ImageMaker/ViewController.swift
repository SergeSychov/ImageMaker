//
//  ViewController.swift
//  ImageMaker
//
//  Created by Serge Sychov on 13/06/2019.
//  Copyright © 2019 Serge Sychov. All rights reserved.
//

import UIKit

class ViewController: UIViewController {

    @IBOutlet weak var takeFromPhotoButton: UIButton!
    @IBOutlet weak var useCameraButton: UIButton!
    @IBOutlet weak var loadByLinkButton: UIButton!
    override func viewDidLoad() {
        super.viewDidLoad()
        
        //set right behavoiur of buttons
        takeFromPhotoButton.titleLabel?.minimumScaleFactor = 0.3
        takeFromPhotoButton.titleLabel?.adjustsFontSizeToFitWidth = true
        takeFromPhotoButton.titleLabel?.textAlignment = .center;
        
        useCameraButton.titleLabel?.minimumScaleFactor = 0.3
        useCameraButton.titleLabel?.adjustsFontSizeToFitWidth = true
        useCameraButton.titleLabel?.textAlignment = .center;
        
        loadByLinkButton.titleLabel?.minimumScaleFactor = 0.3
        loadByLinkButton.titleLabel?.adjustsFontSizeToFitWidth = true
        loadByLinkButton.titleLabel?.textAlignment = .center;
        // Do any additional setup after loading the view.
    }


}

