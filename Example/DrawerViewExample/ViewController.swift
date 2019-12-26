//
//  ViewController.swift
//  DrawerView
//
//  Created by Mikko Välimäki on 24/10/2017.
//  Copyright © 2017 Mikko Välimäki. All rights reserved.
//

import UIKit
import MapKit
import DrawerView
import WebKit

enum DrawerPresentationType {
    case none
    case drawer(DrawerView)
    case presentation
}

struct DrawerMapEntry {
    let key: String
    let presentation: DrawerPresentationType
}

extension DrawerMapEntry {
    var drawer: DrawerView? {
        switch presentation {
        case .none:
            return nil
        case .drawer(let drawer):
            return drawer
        case .presentation:
            return nil
        }
    }
}

class ViewController: UIViewController {

    @IBOutlet weak var mapView: MKMapView!

    @IBOutlet weak var drawerView: DrawerView!

    @IBOutlet weak var tableView: UITableView!

    @IBOutlet weak var searchBar: UISearchBar!

    @IBOutlet weak var topPanel: UIStackView!

    @IBOutlet weak var locateButtonContainer: UIView!

    private var items: [Int] = Array(0...15)

    var drawers: [DrawerMapEntry] = []

    let locationManager = CLLocationManager()

    // MARK: - View lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()

        // We're using safe area insets to reposition the user location
        // button, so remove automatic inset adjustment in the table view.
        tableView.contentInsetAdjustmentBehavior = .never

        tableView.keyboardDismissMode = .onDrag

        drawers = [
            ("↓", DrawerPresentationType.none),
            ("search", setupDrawer()),
            ("modal", setupProgrammaticDrawerView()),
            ("dark", setupDarkThemedDrawerView()),
            ("toolbar", setupTabDrawerView()),
            ("❏", DrawerPresentationType.presentation)
        ].map(DrawerMapEntry.init(key:presentation:))

        self.setupDrawers()
        self.setupLocateButton()

        showDrawer(drawer: drawerView, animated: false)
    }

    override func viewDidAppear(_ animated: Bool) {
        locationManager.requestWhenInUseAuthorization()
        locationManager.startUpdatingLocation()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    // MARK: - Private

    @objc private func toggleTapped(sender: UIButton) {
        guard let entry = sender.titleLabel?.text.flatMap({drawers[$0]}) else {
            return
        }

        switch entry.presentation {
        case .drawer(let drawer):
            showDrawer(drawer: drawer, animated: true)
        case .none:
            showDrawer(drawer: nil, animated: true)
        case .presentation:
            showDrawer(drawer: nil, animated: true)
            presentDrawer()
            break
        }
    }

    let drawerPresentation = DrawerPresentationManager()

    private func presentDrawer() {
        let viewController = self.storyboard!.instantiateViewController(withIdentifier: "ModalPresentationViewController") as! ModalPresentationViewController
        drawerPresentation.drawer.openHeightBehavior = .fitting
        viewController.transitioningDelegate = drawerPresentation
        viewController.modalPresentationStyle = .custom
        self.present(viewController, animated: true, completion: nil)
    }

    private func showDrawer(drawer: DrawerView?, animated: Bool) {
        for another in drawers.compactMap({ $0.drawer }) {
            if another !== drawer {
                another.setConcealed(true, animated: animated)
            } else if another.isConcealed {
                another.setConcealed(false, animated: animated)
            }  else if let nextPosition = another.getNextPosition(offsetBy: 1) ?? another.getNextPosition(offsetBy: -1) {
                another.setPosition(nextPosition, animated: animated)
            }
        }
    }

    private func setupDrawer() -> DrawerPresentationType {
        drawerView.snapPositions = [.collapsed, .partiallyOpen, .open]
        drawerView.insetAdjustmentBehavior = .automatic
        drawerView.delegate = self
        drawerView.position = .collapsed

        return .drawer(drawerView)
    }

    private func setupDrawers() {
        let toggles = drawers
            .map { e -> UIButton in
                let button = UIButton(type: UIButton.ButtonType.system)
                button.addTarget(self, action: #selector(toggleTapped(sender:)), for: .touchUpInside)
                button.setTitle("\(e.key)", for: .normal)
                button.setTitleColor(UIColor(red: 0, green: 0.5, blue: 0.8, alpha: 0.7), for: .normal)
                button.titleLabel?.font = UIFont(name: "HelveticaNeue-Bold", size: 18)!
                return button
        }

        for view in toggles {
            self.topPanel.addArrangedSubview(view)
        }
    }

    private func setupLocateButton() {
        let locateButton = MKUserTrackingButton(mapView: self.mapView)
        locateButton.autoresizingMask = [.flexibleTopMargin, .flexibleLeftMargin]
        locateButton.frame = self.locateButtonContainer.bounds
        self.locateButtonContainer.addSubview(locateButton)

        self.locateButtonContainer.layer.borderColor = UIColor(white: 0.2, alpha: 0.2).cgColor
        self.locateButtonContainer.backgroundColor = UIColor(hue: 0.13, saturation: 0.03, brightness: 0.97, alpha: 1.0)
        self.locateButtonContainer.layer.borderWidth = 0.5
        self.locateButtonContainer.layer.cornerRadius = 8
        self.locateButtonContainer.layer.shadowOffset = CGSize(width: 0, height: 0)
        self.locateButtonContainer.layer.shadowRadius = 2
        self.locateButtonContainer.layer.shadowOpacity = 0.1
    }

    func setupProgrammaticDrawerView() -> DrawerPresentationType {
        // Create the drawer programmatically.
        let drawerView = DrawerView()
        drawerView.attachTo(view: self.view)
        drawerView.delegate = self
        drawerView.snapPositions = [.closed, .open]
        drawerView.insetAdjustmentBehavior = .automatic

        let wwdc = "https://developer.apple.com/videos/play/wwdc2019/239/"
        let request = URLRequest(url: URL(string: wwdc)!)

        let webview = WKWebView()
        webview.load(request)
        webview.frame = drawerView.bounds
        webview.translatesAutoresizingMaskIntoConstraints = false
        drawerView.addSubview(webview)
        webview.autoPinEdgesToSuperview()

        return .drawer(drawerView)
    }

    func setupDarkThemedDrawerView() -> DrawerPresentationType {
        let drawerView = DrawerView()
        drawerView.attachTo(view: self.view)
        drawerView.delegate = self

        drawerView.snapPositions = [.collapsed, .partiallyOpen]
        drawerView.insetAdjustmentBehavior = .automatic
        drawerView.backgroundEffect = UIBlurEffect(style: .dark)
        return .drawer(drawerView)
    }

    func setupTabDrawerView() -> DrawerPresentationType {
        // Attach the drawer with contents of a view controller.
        let vc = self.storyboard!.instantiateViewController(withIdentifier: "TabDrawerViewController") as! DrawerTabViewController
        let drawerView = self.addDrawerView(withViewController: vc)
        vc.drawerView = drawerView

        drawerView.delegate = self

        drawerView.snapPositions = [.collapsed, .open]
        drawerView.insetAdjustmentBehavior = .automatic
        drawerView.backgroundEffect = UIBlurEffect(style: .extraLight)
        drawerView.cornerRadius = 0
        // Set the height to match the default toolbar.
        drawerView.collapsedHeight = 44
        return .drawer(drawerView)
    }
}

extension ViewController: DrawerViewDelegate {

    func drawer(_ drawerView: DrawerView, willTransitionFrom startPosition: DrawerPosition, to targetPosition: DrawerPosition) {
        print("drawer(_:willTransitionFrom: \(startPosition) to: \(targetPosition))")
        if startPosition == .open {
            searchBar.resignFirstResponder()
        }
    }

    func drawer(_ drawerView: DrawerView, didTransitionTo position: DrawerPosition) {
        print("drawerView(_:didTransitionTo: \(position))")
    }

    func drawerWillBeginDragging(_ drawerView: DrawerView) {
        print("drawerWillBeginDragging")
    }

    func drawerWillEndDragging(_ drawerView: DrawerView) {
        print("drawerWillEndDragging")
    }

    func drawerDidMove(_ drawerView: DrawerView, drawerOffset: CGFloat) {
        let maxOffset = drawers
            // Ignore modal for safe area insets.
            .filter { $0.drawer !== drawers["modal"]?.drawer }
            .compactMap { $0.drawer?.drawerOffset }
            .max()
        self.additionalSafeAreaInsets.bottom = min(maxOffset ?? 0, drawerView.partiallyOpenHeight)

        // Round the corners of the toolbar view when open.
        if drawerView === drawers["toolbar"]?.drawer {
            let offset = drawerView.drawerOffset - drawerView.collapsedHeight
            drawerView.cornerRadius = min(offset / 5, 9)
        }
    }
}

extension ViewController: UITableViewDataSource {

    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return items.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell") ?? UITableViewCell(style: .default, reuseIdentifier: "Cell")
        cell.textLabel?.text = "Cell \(items[indexPath.row])"
        cell.backgroundColor = UIColor.clear
        return cell
    }
}

extension ViewController: UITableViewDelegate {

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        drawerView?.setPosition(.collapsed, animated: true)
        //drawers[3].drawer?.setPosition(.partiallyOpen, animated: true)
    }

    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            items.remove(at: indexPath.row)
            tableView.deleteRows(at: [indexPath], with: .fade)
        }
    }
}

extension ViewController: UISearchBarDelegate {

    func searchBarTextDidBeginEditing(_ searchBar: UISearchBar) {
        drawerView?.setPosition(.open, animated: true)
    }
}

extension Sequence where Element == DrawerMapEntry {

    subscript(key: String) -> DrawerMapEntry? {
        return self.first { $0.key == key }
    }
}
