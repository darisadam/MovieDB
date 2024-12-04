//
//  FavoriteViewController.swift
//  MovieDB
//
//  Created by Adam Daris Ryadhi on 23/11/24.
//

import UIKit

class FavoriteViewController: UIViewController {
    
    private let tableView = UITableView()
    private let cellId = "favoriteCell"
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupTableView()
        
        view.backgroundColor = UIColor(hexString: "#25272A")
    }
    
    
}

extension FavoriteViewController {
    
    private func setupTableView() {
        tableView.dataSource = self
        tableView.delegate = self
        
        tableView.backgroundColor = .clear
        tableView.allowsSelection = true
        tableView.register(FavoriteView.self, forCellReuseIdentifier: cellId)
        tableView.translatesAutoresizingMaskIntoConstraints = false
        
        view.addSubview(tableView)
        
        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.topAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
        ])
    }
    
}

extension FavoriteViewController: UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 4
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: cellId, for: indexPath) as? FavoriteView else {
            fatalError("Table View error on Favorite")
        }
        cell.textLabel?.text = indexPath.row.description
        cell.textLabel?.textColor = .black
        
        return cell
    }
    
}

extension FavoriteViewController: UITableViewDelegate {
    
}
