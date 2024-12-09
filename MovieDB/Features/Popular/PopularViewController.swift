//
//  SearchViewController.swift
//  MovieDB
//
//  Created by Adam Daris Ryadhi on 23/11/24.
//

import UIKit

class PopularViewController: UIViewController {
    
    //MARK: - Variables and Constants
    
    private let cellId = "popularCell"
    private let headerId = "popularHeader"
    private let categoryHeaderId = "popularCategoryHeader"
    private var searchLabel = ""
    private var popularMovies = PopularDummyData.popularMovies
    
    //MARK: - Components
    
    private lazy var customSearchBar: CustomSearchBar = {
        let searchBar = CustomSearchBar()
        searchBar.setSearchButtonAction(target: self, action: #selector(searchButtonTapped))
        return searchBar
    }()
    
    private let collectionView: UICollectionView = {
        
        let layout = UICollectionViewCompositionalLayout { (sectionNumber, env) -> NSCollectionLayoutSection in
            
            let item = NSCollectionLayoutItem.init(layoutSize: .init(widthDimension: .fractionalWidth(0.5), heightDimension: .fractionalHeight(1)))
            item.contentInsets.bottom = 10
            item.contentInsets.top = 10
            item.contentInsets.leading = 10
            item.contentInsets.trailing = 10
            
            let group = NSCollectionLayoutGroup.horizontal(layoutSize: .init(widthDimension: .fractionalWidth(1), heightDimension: .fractionalHeight(0.5)), subitems: [item])
            let section = NSCollectionLayoutSection(group: group)
            section.boundarySupplementaryItems = [.init(layoutSize: .init(widthDimension: .fractionalWidth(1), heightDimension: .estimated(20)), elementKind: PopularViewController().categoryHeaderId, alignment: .topLeading)]
            
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
        collectionView.register(PopularViewHeader.self, forSupplementaryViewOfKind: categoryHeaderId, withReuseIdentifier: headerId)
        
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
        return popularMovies.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: cellId, for: indexPath) as! PopularCollectionViewCell
        cell.backgroundColor = .clear
        
        let popularMovies = popularMovies[indexPath.item]
        cell.configure(with: popularMovies)
        
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        let header = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: headerId, for: indexPath) as! PopularViewHeader
        header.configure(with: "Showing result of ‘\(searchLabel)’")
        
        return header
    }
}

//MARK: - Collection View Delegate

extension PopularViewController: UICollectionViewDelegate {
    
}

//MARK: - Navigation Bar Setup

extension PopularViewController {
    
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
