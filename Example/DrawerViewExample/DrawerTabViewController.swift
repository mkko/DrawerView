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

        contentView.subviews.forEach {
            $0.removeFromSuperview()
        }

        // Create the content programmatically.

        // Please note that it is crucial that the sizes of the
        // subitems are handled dynamically by the autolayout,
        // since the size of the content view will change during
        // the interaction.

        let labels = ["A", "B", "C"]
            .map { name -> UILabel in
                let label = UILabel()
                label.text = name
                label.font = UIFont(name: "HelveticaNeue-UltraLight", size: 256)
                label.textColor = UIColor(white: 0, alpha: 0.7)
                label.textAlignment = .center
                label.translatesAutoresizingMaskIntoConstraints = false
                return label
        }

        labels.forEach(self.contentView.addSubview)

        let results = labels.reduce((prev: nil, constraints: [])) { (result, label) -> (prev: UILabel?, constraints: [NSLayoutConstraint]) in

            let newConstraints = [
                label.widthAnchor.constraint(equalTo: (result.prev ?? contentView).widthAnchor),
                label.heightAnchor.constraint(equalTo: (result.prev ?? contentView).heightAnchor),
                label.leftAnchor.constraint(equalTo: result.prev?.rightAnchor ?? contentView.leftAnchor),
                label.topAnchor.constraint(equalTo: contentView.topAnchor),
                label.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
                ]

            return (prev: label, constraints: result.constraints + newConstraints)
        }

        let constraints = results.constraints
            + [labels.last!.rightAnchor.constraint(equalTo: contentView.rightAnchor)]

        constraints.forEach { $0.isActive = true }

        self.contentView.contentSize = CGSize(
            width: self.contentView.bounds.width * CGFloat(labels.count),
            height: self.contentView.bounds.height)
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
