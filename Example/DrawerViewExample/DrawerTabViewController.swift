//
//  DrawerTabViewController.swift
//  DrawerViewExample
//
//  Created by Mikko Välimäki on 15/05/2018.
//  Copyright © 2018 Mikko Välimäki. All rights reserved.
//

import UIKit
import DrawerView

class DrawerTabViewController: UIViewController {

    @IBOutlet weak var contentView: UIScrollView!

    @IBOutlet weak var buttonA: UIButton!

    @IBOutlet weak var buttonB: UIButton!

    @IBOutlet weak var buttonC: UIButton!

    public var drawerView: DrawerView!

    @IBAction func toggleA(_ sender: Any) {
        goToPage(0)
    }

    @IBAction func toggleB(_ sender: Any) {
        goToPage(1)
    }

    @IBAction func toggleC(_ sender: Any) {
        goToPage(2)
    }

    func goToPage(_ pageNumber: Int) {
        let offset = CGPoint(x: CGFloat(pageNumber) * contentView.bounds.width, y: 0)
        contentView.setContentOffset(offset, animated: true)
        drawerView.setPosition(.open, animated: true)
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        contentView.contentInsetAdjustmentBehavior = .never
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

extension DrawerTabViewController: UIScrollViewDelegate {

    func scrollViewDidScroll(_ scrollView: UIScrollView) {

    }
}
