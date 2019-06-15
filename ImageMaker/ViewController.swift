//
//  ViewController.swift
//  ImageMaker
//
//  Created by Serge Sychov on 13/06/2019.
//  Copyright © 2019 Serge Sychov. All rights reserved.
//

import UIKit

class ViewController: UIViewController {

    @IBOutlet weak var choosePicthureContainerView: UIView!
    override func viewDidLoad() {
        super.viewDidLoad()
        choosePicthureContainerView.isHidden = true

        // Do any additional setup after loading the view.
    }
    
    
    
    //show and hide chooseBottonContainerView
    @IBAction func tapWorksImageView(_ sender: UITapGestureRecognizer) {
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

