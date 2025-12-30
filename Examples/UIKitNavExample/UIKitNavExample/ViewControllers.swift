//
//  ViewControllers.swift
//  UIKitNavExample
//
//  Created by Brandon Sneed on 12/30/25.
//

import UIKit

// MARK: - Navigation Test View Controller

class NavigationTestViewController: UITableViewController {
    
    private let sections = [
        ("Basic Push", ["Detail View", "Another Detail"]),
        ("Value-Based", ["Product: iPhone", "Product: MacBook", "Product: AirPods"]),
        ("Programmatic", ["Push 3 screens"]),
        ("Nested", ["Go to List View"])
    ]
    
    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Navigation Tests"
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "Cell")
    }
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return sections.count
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return sections[section].1.count
    }
    
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return sections[section].0
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath)
        cell.textLabel?.text = sections[indexPath.section].1[indexPath.row]
        cell.accessoryType = .disclosureIndicator
        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        switch (indexPath.section, indexPath.row) {
        case (0, 0):
            let vc = DetailViewController(titleText: "Detail View")
            navigationController?.pushViewController(vc, animated: true)
        case (0, 1):
            let vc = DetailViewController(titleText: "Another Detail")
            navigationController?.pushViewController(vc, animated: true)
        case (1, 0):
            let vc = ProductDetailViewController(product: Product(name: "iPhone", price: 999))
            navigationController?.pushViewController(vc, animated: true)
        case (1, 1):
            let vc = ProductDetailViewController(product: Product(name: "MacBook", price: 1999))
            navigationController?.pushViewController(vc, animated: true)
        case (1, 2):
            let vc = ProductDetailViewController(product: Product(name: "AirPods", price: 249))
            navigationController?.pushViewController(vc, animated: true)
        case (2, 0):
            // Push 3 screens programmatically
            let vc1 = ProductDetailViewController(product: Product(name: "First", price: 1))
            let vc2 = ProductDetailViewController(product: Product(name: "Second", price: 2))
            let vc3 = ProductDetailViewController(product: Product(name: "Third", price: 3))
            navigationController?.pushViewController(vc1, animated: false)
            navigationController?.pushViewController(vc2, animated: false)
            navigationController?.pushViewController(vc3, animated: true)
        case (3, 0):
            let vc = NestedListViewController()
            navigationController?.pushViewController(vc, animated: true)
        default:
            break
        }
    }
}

// MARK: - Detail View Controller

class DetailViewController: UIViewController {
    
    private let titleText: String
    
    init(titleText: String) {
        self.titleText = titleText
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        title = titleText
        view.backgroundColor = .systemBackground
        
        let label = UILabel()
        label.text = "This is \(titleText)"
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(label)
        
        NSLayoutConstraint.activate([
            label.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            label.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ])
    }
}

// MARK: - Product Detail View Controller

struct Product {
    let name: String
    let price: Int
}

class ProductDetailViewController: UIViewController {
    
    private let product: Product
    
    init(product: Product) {
        self.product = product
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        title = product.name
        view.backgroundColor = .systemBackground
        
        let stack = UIStackView()
        stack.axis = .vertical
        stack.spacing = 20
        stack.alignment = .center
        stack.translatesAutoresizingMaskIntoConstraints = false
        
        let nameLabel = UILabel()
        nameLabel.text = product.name
        nameLabel.font = .systemFont(ofSize: 34, weight: .bold)
        
        let priceLabel = UILabel()
        priceLabel.text = "$\(product.price)"
        priceLabel.font = .systemFont(ofSize: 24)
        priceLabel.textColor = .systemGreen
        
        stack.addArrangedSubview(nameLabel)
        stack.addArrangedSubview(priceLabel)
        view.addSubview(stack)
        
        NSLayoutConstraint.activate([
            stack.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            stack.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ])
    }
}

// MARK: - Nested List View Controller

class NestedListViewController: UITableViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Nested List"
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "Cell")
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 3
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath)
        cell.textLabel?.text = "Nested Item \(indexPath.row + 1)"
        cell.accessoryType = .disclosureIndicator
        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let vc = NestedDetailViewController(item: indexPath.row + 1)
        navigationController?.pushViewController(vc, animated: true)
    }
}

class NestedDetailViewController: UIViewController {
    
    private let item: Int
    
    init(item: Int) {
        self.item = item
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Item \(item)"
        view.backgroundColor = .systemBackground
        
        let label = UILabel()
        label.text = "Nested Item \(item) Detail"
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(label)
        
        NSLayoutConstraint.activate([
            label.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            label.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ])
    }
}

// MARK: - Sheet Test View Controller

class SheetTestViewController: UITableViewController {
    
    private let options = ["Show Sheet", "Show Full Screen"]
    
    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Sheet Tests"
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "Cell")
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return options.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath)
        cell.textLabel?.text = options[indexPath.row]
        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        switch indexPath.row {
        case 0:
            let vc = SheetContentViewController()
            let nav = UINavigationController(rootViewController: vc)
            if let sheet = nav.sheetPresentationController {
                sheet.detents = [.medium(), .large()]
            }
            present(nav, animated: true)
        case 1:
            let vc = FullScreenContentViewController()
            let nav = UINavigationController(rootViewController: vc)
            nav.modalPresentationStyle = .fullScreen
            present(nav, animated: true)
        default:
            break
        }
    }
}

class SheetContentViewController: UIViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Sheet View"
        view.backgroundColor = .systemBackground
        
        navigationItem.rightBarButtonItem = UIBarButtonItem(
            barButtonSystemItem: .done,
            target: self,
            action: #selector(doneTapped)
        )
        
        let stack = UIStackView()
        stack.axis = .vertical
        stack.spacing = 20
        stack.alignment = .center
        stack.translatesAutoresizingMaskIntoConstraints = false
        
        let label = UILabel()
        label.text = "This is a sheet!"
        label.font = .systemFont(ofSize: 17, weight: .semibold)
        
        let button = UIButton(type: .system)
        button.setTitle("Navigate inside sheet", for: .normal)
        button.addTarget(self, action: #selector(navigateTapped), for: .touchUpInside)
        
        stack.addArrangedSubview(label)
        stack.addArrangedSubview(button)
        view.addSubview(stack)
        
        NSLayoutConstraint.activate([
            stack.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            stack.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ])
    }
    
    @objc private func doneTapped() {
        dismiss(animated: true)
    }
    
    @objc private func navigateTapped() {
        let vc = SheetDetailViewController()
        navigationController?.pushViewController(vc, animated: true)
    }
}

class SheetDetailViewController: UIViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Sheet Detail"
        view.backgroundColor = .systemBackground
        
        let label = UILabel()
        label.text = "Pushed inside sheet!"
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(label)
        
        NSLayoutConstraint.activate([
            label.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            label.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ])
    }
}

class FullScreenContentViewController: UIViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Full Screen"
        view.backgroundColor = .systemBackground
        
        navigationItem.leftBarButtonItem = UIBarButtonItem(
            barButtonSystemItem: .close,
            target: self,
            action: #selector(closeTapped)
        )
        
        let label = UILabel()
        label.text = "Full screen cover!"
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(label)
        
        NSLayoutConstraint.activate([
            label.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            label.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ])
    }
    
    @objc private func closeTapped() {
        dismiss(animated: true)
    }
}

// MARK: - Settings View Controller (No title set!)

class SettingsViewController: UITableViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Intentionally NO title here - let's see what we capture
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "Cell")
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 4
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath)
        if indexPath.row < 3 {
            cell.textLabel?.text = "Setting \(indexPath.row + 1)"
            cell.accessoryType = .none
        } else {
            cell.textLabel?.text = "About"
            cell.accessoryType = .disclosureIndicator
        }
        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        if indexPath.row == 3 {
            let vc = AboutViewController()
            navigationController?.pushViewController(vc, animated: true)
        }
    }
}

class AboutViewController: UIViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        title = "About"
        view.backgroundColor = .systemBackground
        
        let label = UILabel()
        label.text = "UIKitNavExample v1.0"
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(label)
        
        NSLayoutConstraint.activate([
            label.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            label.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ])
    }
}
