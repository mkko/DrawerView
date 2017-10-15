//
//  ViewController.swift
//  ScrollTest
//
//  Created by Mikko Välimäki on 03/10/2017.
//  Copyright © 2017 Mikko Välimäki. All rights reserved.
//

import UIKit

class ViewController: UIViewController {

    @IBOutlet weak var parentScrollView: UIScrollView!

    @IBOutlet weak var tableView: UITableView!

    var isDragging = false

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    var offset: CGFloat = 0.0

}

extension ViewController: UITableViewDataSource {

    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 25
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        var cell = tableView.dequeueReusableCell(withIdentifier: "Cell") ?? UITableViewCell(style: .default, reuseIdentifier: "Cell")
        cell.textLabel?.text = "Cell \(indexPath.row)"
        cell.backgroundColor = UIColor.clear
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
    }
}

extension ViewController: UITableViewDelegate {

}

extension ViewController: UIScrollViewDelegate {

    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        if isDragging, let parentScroll = scrollView.superview as? UIScrollView {

            // Accumulate offset when negative
            if scrollView.contentOffset.y < 0 {
                // Try #1
//                parentScroll.contentOffset.y = parentScroll.contentOffset.y + scrollView.contentOffset.y
//                offset = offset + scrollView.contentOffset.y
//                scrollView.contentOffset.y = 0

                // Try #2
                offset = offset + scrollView.contentOffset.y
                print("offset: \(offset)")
                print("offset: \(offset)")
                parentScroll.bounds = CGRect(
                    origin: CGPoint(x: parentScroll.bounds.origin.x, y: offset),
                    size: parentScroll.bounds.size)

                scrollView.contentOffset.y = 0

            } else if scrollView.contentOffset.y > 0 && offset < 0 {
                // var o = s.contentOffset

//                offset = offset + scrollView.contentOffset.y
//                if offset > 0 {
//                    print("!")
//                    offset = 0
//                } else {
//                    s.contentOffset.y = s.contentOffset.y + scrollView.contentOffset.y
//                    scrollView.contentOffset.y = 0
//                }

            }
        }
        //print("\(offset)")
    }

    func scrollViewWillBeginDecelerating(_ scrollView: UIScrollView) {
        print("scrollViewWillBeginDecelerating")
    }

    func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        self.isDragging = true
    }

    func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        self.isDragging = false
        print("scrollViewDidEndDragging")
        if offset < 0 {
            parentScrollView.setContentOffset(CGPoint(x: 0, y: 0), animated: true)
            offset = 0
        }
    }
}
