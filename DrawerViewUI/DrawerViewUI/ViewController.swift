//
//  ViewController.swift
//  DrawerViewUI
//
//  Created by Mikko Välimäki on 17.7.2024.
//

import UIKit
import DrawerView

public enum DrawerViewEvent: String {
    case willTransitionFrom
    case didTransitionTo
    case drawerDidMove
    case willBeginDragging
    case willEndDragging

    case drawerPresentationWillBegin
    case drawerPresentationDidEnd
    case drawerDismissalWillBegin
    case drawerDismissalDidEnd
}

class ViewController: UIViewController {

    let drawerView = DrawerView()

    let tableView = UITableView()

    let resetButton = UIButton()

    var presentationManager: DrawerPresentationManager?
    
    var presented: UIViewController?

    var events: [DrawerViewEvent] = [] {
        didSet {
            tableView.reloadData()
        }
    }

    func record(event: DrawerViewEvent) {
        // Skip duplicating consequent events
        if events.last != event {
            events.append(event)
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = .systemBlue

        tableView.frame = view.bounds
        view.addSubview(tableView)
        tableView.dataSource = self

        drawerView.accessibilityIdentifier = "drawer"
        drawerView.attachTo(view: view)
        drawerView.backgroundColor = .systemTeal
        drawerView.delegate = self

        let buttons = UIStackView()
        buttons.distribution = .equalSpacing
        buttons.frame = CGRect(x: 0, y: 10, width: drawerView.bounds.width - 0, height: 40)
        buttons.autoresizingMask = [
            .flexibleWidth, .flexibleBottomMargin
        ]
        drawerView.addSubview(buttons)

        // resetButton.frame = CGRect(x: 10, y: 10, width: 100, height: 40)
        resetButton.accessibilityIdentifier = "reset"
        resetButton.setTitle("Reset", for: .normal)
        resetButton.addTarget(self, action: #selector(reset), for: .touchUpInside)
        buttons.addArrangedSubview(resetButton)

        let modalButton = UIButton()
        modalButton.accessibilityIdentifier = "modal"
        modalButton.setTitle("Modal", for: .normal)
        modalButton.addTarget(self, action: #selector(modal), for: .touchUpInside)
        buttons.addArrangedSubview(modalButton)
    }

    @objc func reset() {
        events = []
    }

    @objc func modal() {
        let presented = UIViewController()
        presented.view.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(dismissModal)))
        presented.view.accessibilityIdentifier = "dismiss"
        presentationManager = .init()
        presentationManager?.presentationDelegate = self
        presented.modalPresentationStyle = .custom
        presented.transitioningDelegate = presentationManager

        self.presented = presented
        self.present(presented, animated: true)
    }

    @objc func dismissModal() {
        presented?.dismiss(animated: true)
    }
}

extension ViewController: UITableViewDataSource {

    func numberOfSections(in tableView: UITableView) -> Int {
        1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        events.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell")
        ?? UITableViewCell()
        var config = UIListContentConfiguration.cell()
        config.text = events[indexPath.row].rawValue
        cell.contentConfiguration = config
        return cell
    }
}

extension ViewController: DrawerViewDelegate {

    func drawer(_ drawerView: DrawerView, willTransitionFrom startPosition: DrawerPosition, to targetPosition: DrawerPosition) {
        record(event: .willTransitionFrom)
    }

    func drawer(_ drawerView: DrawerView, didTransitionTo position: DrawerPosition) {
        record(event: .didTransitionTo)
    }

    func drawerDidMove(_ drawerView: DrawerView, drawerOffset: CGFloat) {
        record(event: .drawerDidMove)
    }

    func drawerWillBeginDragging(_ drawerView: DrawerView) {
        record(event: .willBeginDragging)
    }

    func drawerWillEndDragging(_ drawerView: DrawerView) {
        record(event: .willEndDragging)
    }
}

extension ViewController: DrawerPresentationDelegate {

    func drawerPresentationWillBegin(for viewController: UIViewController, in drawerView: DrawerView) {
        record(event: .drawerPresentationWillBegin)
    }

    func drawerPresentationDidEnd(for viewController: UIViewController, in drawerView: DrawerView, completed: Bool) {
        record(event: .drawerPresentationDidEnd)
    }

    func drawerDismissalWillBegin(for viewController: UIViewController, in drawerView: DrawerView) {
        record(event: .drawerDismissalWillBegin)
    }

    func drawerDismissalDidEnd(for viewController: UIViewController, in drawerView: DrawerView, completed: Bool) {
        record(event: .drawerDismissalDidEnd)
    }
}
