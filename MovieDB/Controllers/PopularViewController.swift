//
//  SearchViewController.swift
//  MovieDB
//
//  Created by Adam Daris Ryadhi on 23/11/24.
//

import UIKit

class PopularViewController: UIViewController {
    
    //MARK: - Variables and Constants
    
    let cellId = "popularCell"
    
    //MARK: - Components
    
    private let searchController = UISearchController(searchResultsController: nil)
    let collectionView: UICollectionView = {
        
        let layout = UICollectionViewCompositionalLayout { (sectionNumber, env) -> NSCollectionLayoutSection in
            
            let item = NSCollectionLayoutItem.init(layoutSize: .init(widthDimension: .fractionalWidth(0.5), heightDimension: .fractionalHeight(1)))
            item.contentInsets.bottom = 10
            item.contentInsets.top = 10
            item.contentInsets.leading = 10
            item.contentInsets.trailing = 10
            
            let group = NSCollectionLayoutGroup.horizontal(layoutSize: .init(widthDimension: .fractionalWidth(1), heightDimension: .absolute(250)), subitems: [item])
            let section = NSCollectionLayoutSection(group: group)
            
            return section
        }
        
        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        
        return collectionView
    }()
    
    //MARK: - Life Cycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupNavbar()
        setupCollectionView()
        
        view.backgroundColor = mdbBackground
    }
    
}

//MARK: - Components Setup

extension PopularViewController {
    
    private func setupCollectionView() {
        collectionView.dataSource = self
        collectionView.delegate = self
        
        collectionView.backgroundColor = .clear
        collectionView.decelerationRate = .fast
        collectionView.contentInsetAdjustmentBehavior = .never
        collectionView.showsHorizontalScrollIndicator = false
        collectionView.showsVerticalScrollIndicator = false
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        collectionView.register(PopularCollectionViewCell.self, forCellWithReuseIdentifier: cellId)
        
        view.addSubview(collectionView)
        
        NSLayoutConstraint.activate([
            collectionView.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor),
            collectionView.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor),
            collectionView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            collectionView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }
    
}

//MARK: - Collection View Data Source

extension PopularViewController: UICollectionViewDataSource {
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return 3
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: cellId, for: indexPath) as! PopularCollectionViewCell
        cell.backgroundColor = .clear
        
        return cell
    }
}

//MARK: - Collection View Delegate

extension PopularViewController: UICollectionViewDelegate {
    
}

//MARK: - Navigation Bar Setup

extension PopularViewController: UISearchResultsUpdating {
    
    private func setupSearchController() {
        searchController.searchResultsUpdater = self
        searchController.obscuresBackgroundDuringPresentation = false
        searchController.hidesNavigationBarDuringPresentation = false
        searchController.searchBar.placeholder = "search popular movies"
    }
    
    func updateSearchResults(for searchController: UISearchController) {
        print("debug: \(searchController.searchBar.text ?? "")")
    }
    
    private func setupNavbar() {
        setupSearchController()
        
        navigationItem.searchController = searchController
        navigationItem.hidesSearchBarWhenScrolling = false
        definesPresentationContext = false
    }
}
