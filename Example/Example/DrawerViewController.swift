//
//  DrawerViewController.swift
//  Example
//
//  Created by Mikko Välimäki on 04/02/2018.
//  Copyright © 2018 Mikko Välimäki. All rights reserved.
//

import UIKit

class DrawerViewController: UIViewController {

    @IBAction func toggle(_ sender: Any) {
        self.drawer?.setPosition(.open, animated: true)
    }

    override func viewDidLoad() {
        let btn = (self.view.subviews[1] as! UIButton)
        let x = btn.actions(forTarget: self, forControlEvent: UIControlEvents.touchUpInside)

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
