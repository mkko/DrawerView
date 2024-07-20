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

    let toggleButton = UIButton()

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

        let containerView = UIView()
        let actions = UIStackView()
        [containerView, actions].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
            view.addSubview($0)
        }

        actions.backgroundColor = .systemPink
        actions.distribution = .equalSpacing

        NSLayoutConstraint.activate([
            containerView.topAnchor.constraint(equalTo: view.topAnchor),
            containerView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            containerView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            containerView.bottomAnchor.constraint(equalTo: actions.topAnchor),

            actions.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            actions.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            actions.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),
        ])


        drawerView.accessibilityIdentifier = "drawer"
        drawerView.attachTo(view: containerView)
        drawerView.backgroundColor = .systemTeal
        drawerView.delegate = self


        resetButton.accessibilityIdentifier = "clear"
        resetButton.setTitle("Clear", for: .normal)
        resetButton.addTarget(self, action: #selector(reset), for: .touchUpInside)
        actions.addArrangedSubview(resetButton)

        toggleButton.accessibilityIdentifier = "toggle"
        toggleButton.setTitle("Toggle", for: .normal)
        toggleButton.addTarget(self, action: #selector(toggle), for: .touchUpInside)
        actions.addArrangedSubview(toggleButton)

        let concealButton = UIButton()
        concealButton.accessibilityIdentifier = "hide"
        concealButton.setTitle("Hide", for: .normal)
        concealButton.addTarget(self, action: #selector(hide), for: .touchUpInside)
        actions.addArrangedSubview(concealButton)

        let modalButton = UIButton()
        modalButton.accessibilityIdentifier = "modal"
        modalButton.setTitle("Modal", for: .normal)
        modalButton.addTarget(self, action: #selector(modal), for: .touchUpInside)
        actions.addArrangedSubview(modalButton)
    }

    @objc func reset() {
        events = []
    }

    @objc func toggle() {
        switch drawerView.position {
        case .closed, .collapsed, .partiallyOpen:
            drawerView.setPosition(.open, animated: true)
        case .open:
            drawerView.setPosition(.collapsed, animated: true)
        }
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

    @objc func hide() {
        drawerView.setConcealed(!drawerView.isConcealed, animated: true)
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
