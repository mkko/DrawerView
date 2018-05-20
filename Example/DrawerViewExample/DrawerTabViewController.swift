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

    @IBOutlet weak var stackView: UIStackView!

    public var drawerView: DrawerView!

    @IBAction func jumpToPage(_ sender: UIButton) {
        goToPage(sender.tag)
    }

    func goToPage(_ pageNumber: Int) {
        let offset = CGPoint(x: CGFloat(pageNumber) * contentView.bounds.width, y: 0)
        contentView.setContentOffset(offset, animated: true)
        drawerView.setPosition(.open, animated: true)
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        contentView.contentInsetAdjustmentBehavior = .never

        // Create the content programmatically.

        // Please note that it is crucial that the sizes of the
        // subitems are matched to the content size by the autolayout,
        // since the this will change during the drawer interaction.

        let stackButtons = stackView.subviews
            .flatMap { $0 as? UIButton }
            .sorted { a, b in a.title(for: .normal)! < b.title(for: .normal)! }

        // Set up toolbar buttons' targets.
        stackButtons.enumerated().map { (index: $0, element: $1) }
            .forEach {
                $0.element.tag = $0.index
                $0.element.addTarget(self, action: #selector(jumpToPage(_:)), for: .touchUpInside)
        }

        let labels = stackButtons
            .map { button -> UILabel in
            let label = UILabel()
            label.text = button.title(for: .normal)!
            label.font = UIFont(name: "HelveticaNeue-UltraLight", size: 256)
            label.textColor = UIColor(white: 0, alpha: 0.7)
            label.textAlignment = .center
            label.translatesAutoresizingMaskIntoConstraints = false
            return label
        }

        contentView.setupAsPager(withViews: labels)
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

fileprivate extension UIScrollView {

    func setupAsPager(withViews views: [UIView]) {
        self.isPagingEnabled = true

        views.forEach(self.addSubview)

        let results = views.reduce((prev: nil, constraints: [])) { (result, view) -> (prev: UIView?, constraints: [NSLayoutConstraint]) in

            let newConstraints = [
                view.widthAnchor.constraint(equalTo: (result.prev ?? self).widthAnchor),
                view.heightAnchor.constraint(equalTo: (result.prev ?? self).heightAnchor),
                view.leftAnchor.constraint(equalTo: result.prev?.rightAnchor ?? self.leftAnchor),
                view.topAnchor.constraint(equalTo: self.topAnchor),
                view.bottomAnchor.constraint(equalTo: self.bottomAnchor),
                ]

            return (prev: view, constraints: result.constraints + newConstraints)
        }

        let constraints = results.constraints
            + [views.last!.rightAnchor.constraint(equalTo: self.rightAnchor)]

        constraints.forEach { $0.isActive = true }

        self.contentSize = CGSize(
            width: self.bounds.width * CGFloat(views.count),
            height: self.bounds.height)

    }

}
