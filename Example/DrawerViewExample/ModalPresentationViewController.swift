//
//  ModalPresentationViewController.swift
//  DrawerViewExample
//
//  Created by Mikko Välimäki on 2019-11-28.
//  Copyright © 2019 Mikko Välimäki. All rights reserved.
//

import UIKit

class ModalPresentationViewController: UIViewController {

    @IBAction func close(_ sender: Any) {
        self.dismiss(animated: true)
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}
