//
//  FavoriteViewController.swift
//  MovieDB
//
//  Created by Adam Daris Ryadhi on 23/11/24.
//

import UIKit

class FavoriteViewController: UIViewController {
    
    //MARK: - Variables and Constants
    
    private let cellId = "favoriteCell"
    private var favoriteMovies = FavoriteDummyData.movies
    
    //MARK: - Components
    private let tableView = UITableView()
    
    private lazy var customSearchBar: CustomSearchBar = {
        let searchBar = CustomSearchBar()
        searchBar.setSearchButtonAction(target: self, action: #selector(searchButtonTapped))
        return searchBar
    }()
    
    //MARK: - Life Cycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupNavbar()
        setupTableView()
        
        view.backgroundColor = mdbBackground
    }
    
}

//MARK: - Component Setups

extension FavoriteViewController {
    
    private func setupTableView() {
        tableView.dataSource = self
        tableView.delegate = self
        
        tableView.backgroundColor = .clear
        tableView.allowsSelection = false
        tableView.register(FavoriteTableViewCell.self, forCellReuseIdentifier: cellId)
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

//MARK: - Table View Data Source

extension FavoriteViewController: UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return favoriteMovies.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: cellId, for: indexPath) as? FavoriteTableViewCell else {
            fatalError("Table View error on Favorite")
        }
        let movie = favoriteMovies[indexPath.row]
        cell.configure(with: movie)
        cell.backgroundColor = .clear
        
        return cell
    }
    
}

//MARK: - Table View Delegate

extension FavoriteViewController: UITableViewDelegate {
    
}

//MARK: - Navigation Bar Setup

extension FavoriteViewController {
    
    private func setupNavbar() {
        navigationItem.titleView = customSearchBar
    }
    
    @objc private func searchButtonTapped() {
        
        guard let searchText = customSearchBar.getSearchText(), !searchText.isEmpty else {
            print("No search text entered")
            return
        }
        
        print("Searching for: \(searchText)")
    }
    
}
