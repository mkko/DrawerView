//
//  TableViewController.swift
//  DrawerViewUI
//
//  Created by Mikko Välimäki on 18.7.2024.
//

import UIKit
import DrawerView

class TableViewController: UITableViewController {

    let drawerView = DrawerView()

    var events: [DrawerViewEvent] = [] {
        willSet {
            tableView.beginUpdates()
        }
        didSet {
            // tableView.endUpdates()
            tableView.reloadData()
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupDrawer()
    }

    func setupDrawer() {
        drawerView.accessibilityIdentifier = "drawer"
        drawerView.attachTo(view: view)
        drawerView.backgroundColor = .systemTeal
        drawerView.delegate = self
        view.bringSubviewToFront(drawerView)
    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of rows
        return events.count
    }

    /*
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "reuseIdentifier", for: indexPath)

        // Configure the cell...

        return cell
    }
    */

    /*
    // Override to support conditional editing of the table view.
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        // Return false if you do not want the specified item to be editable.
        return true
    }
    */

    /*
    // Override to support editing the table view.
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            // Delete the row from the data source
            tableView.deleteRows(at: [indexPath], with: .fade)
        } else if editingStyle == .insert {
            // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
        }    
    }
    */

    /*
    // Override to support rearranging the table view.
    override func tableView(_ tableView: UITableView, moveRowAt fromIndexPath: IndexPath, to: IndexPath) {

    }
    */

    /*
    // Override to support conditional rearranging of the table view.
    override func tableView(_ tableView: UITableView, canMoveRowAt indexPath: IndexPath) -> Bool {
        // Return false if you do not want the item to be re-orderable.
        return true
    }
    */

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}

extension TableViewController: DrawerViewDelegate {

    func drawer(_ drawerView: DrawerView, willTransitionFrom startPosition: DrawerPosition, to targetPosition: DrawerPosition) {
        events.append(.willTransitionFrom)
    }

    func drawer(_ drawerView: DrawerView, didTransitionTo position: DrawerPosition) {
        events.append(.didTransitionTo)
    }

    func drawerDidMove(_ drawerView: DrawerView, drawerOffset: CGFloat) {
        events.append(.drawerDidMove)
    }

    func drawerWillBeginDragging(_ drawerView: DrawerView) {
        events.append(.willBeginDragging)
    }

    func drawerWillEndDragging(_ drawerView: DrawerView) {
        events.append(.willEndDragging)
    }
}
