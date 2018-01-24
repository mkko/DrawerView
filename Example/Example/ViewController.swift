//
//  ViewController.swift
//  DrawerView
//
//  Created by Mikko Välimäki on 24/10/2017.
//  Copyright © 2017 Mikko Välimäki. All rights reserved.
//

import UIKit
import DrawerView

class ViewController: UIViewController {

    @IBOutlet weak var drawerView: DrawerView!
    @IBOutlet weak var searchBar: UISearchBar!

    @IBAction func expand(_ sender: Any) {
        drawerView.setPosition(.open, animated: true)
    }

    @IBAction func collapse(_ sender: Any) {
        drawerView.setPosition(.collapsed, animated: true)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        drawerView.supportedPositions = [.collapsed, .partiallyOpen, .open]
        drawerView.position = .collapsed
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
}

extension ViewController: UITableViewDataSource {

    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 25
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell") ?? UITableViewCell(style: .default, reuseIdentifier: "Cell")
        cell.textLabel?.text = "Cell \(indexPath.row)"
        cell.backgroundColor = UIColor.clear
        return cell
    }
}

extension ViewController: UITableViewDelegate {

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        drawerView.setPosition(.open, animated: true)
    }
}

extension ViewController: UISearchBarDelegate {

    func searchBarTextDidBeginEditing(_ searchBar: UISearchBar) {
        drawerView.setPosition(.open, animated: true)
    }
}

extension ViewController: DrawerViewDelegate {

    func drawer(_ drawerView: DrawerView, willTransitionFrom position: DrawerPosition) {
        if position == .open {
            searchBar.resignFirstResponder()
        }
    }
}
