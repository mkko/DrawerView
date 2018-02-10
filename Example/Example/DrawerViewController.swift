//
//  DrawerViewController.swift
//  Example
//
//  Created by Mikko Välimäki on 04/02/2018.
//  Copyright © 2018 Mikko Välimäki. All rights reserved.
//

import UIKit
import DrawerView

class DrawerViewController: UIViewController {

    @IBAction func toggle(_ sender: Any) {
        findParentDrawerView(ofView: self.view)?.setPosition(.open, animated: true)
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}

func findParentDrawerView(ofView view: UIView?) -> DrawerView? {
    switch view?.superview {
    case .none:
        return nil
    case .some(let parent):
        return parent as? DrawerView ?? findParentDrawerView(ofView: view)
    }
}
