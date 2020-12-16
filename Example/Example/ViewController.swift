//
//  ViewController.swift
//  Example
//
//  Created by Archer on 2020/12/16.
//

import UIKit
import WMHPhotoSDK

class ViewController: UIViewController {
    private var selectedDataSource : [WMHThumbnailModel] = []

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
    }

    @IBAction func openAction(_ sender: Any) {
        let thumbVC = WMHThumbnailVC()
        thumbVC.selectedDataSource = selectedDataSource
        thumbVC.requestType = .photoAndVideo
        thumbVC.completeBlock = {
            (modelArr, isOrigin) in
            self.selectedDataSource.removeAll()
            self.selectedDataSource.append(contentsOf: modelArr)
            print(String(format: "%d + %@", modelArr.count, isOrigin == true ? "true" : "false"))
        }
        let nav = UINavigationController.init(rootViewController: thumbVC)
        nav.modalPresentationStyle = UIModalPresentationStyle(rawValue: 0)!
        self .present(nav, animated: true, completion: nil)
    }
    
}

