//
//  ViewController.swift
//  ScrollTest
//
//  Created by Mikko Välimäki on 03/10/2017.
//  Copyright © 2017 Mikko Välimäki. All rights reserved.
//

import UIKit

class ViewController: UIViewController {

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
        return 15
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        var cell = tableView.dequeueReusableCell(withIdentifier: "Cell") ?? UITableViewCell(style: .default, reuseIdentifier: "Cell")
        cell.textLabel?.text = "Cell \(indexPath.row)"
        cell.backgroundColor = UIColor.clear
        return cell
    }
}

extension ViewController: UITableViewDelegate {

}

extension ViewController: UIScrollViewDelegate {

    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        if scrollView.contentOffset.y < 0 {
//            scrollView.contentOffset.y = 0
            if let s = scrollView.superview as? UIScrollView {
                //var o = s.contentOffset
                s.contentOffset.y = s.contentOffset.y + scrollView.contentOffset.y
                offset = offset + scrollView.contentOffset.y
                scrollView.contentOffset.y = 0
            }
        } else if offset < 0 {
            if let s = scrollView.superview as? UIScrollView {
                //var o = s.contentOffset
                s.contentOffset.y = s.contentOffset.y + scrollView.contentOffset.y
                offset = offset + scrollView.contentOffset.y
                scrollView.contentOffset.y = 0
            }
        }
        print("\(offset)")
    }
}
