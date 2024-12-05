//
//  HomeViewController.swift
//  MovieDB
//
//  Created by Adam Daris Ryadhi on 22/11/24.
//

import UIKit

class HomeViewController: UIViewController {
    
    //MARK: - Variables and Constants
    
    private let cellId = "homeCell"
    private let headerId = "homeHeader"
    private let categoryHeaderId = "homeCategoryHeader"
    
    //MARK: - Components
    
    let collectionView: UICollectionView = {
        
        let layout = UICollectionViewCompositionalLayout { (sectionNumber, env) -> NSCollectionLayoutSection in
            
            if sectionNumber == 0 {
                
                let item = NSCollectionLayoutItem(layoutSize: .init(widthDimension: .fractionalWidth(1), heightDimension: .fractionalHeight(1)))
                item.contentInsets.bottom = 30
                
                let group = NSCollectionLayoutGroup.horizontal(layoutSize: .init(widthDimension: .fractionalWidth(1), heightDimension: .estimated(325)), subitems: [item])
                let section = NSCollectionLayoutSection(group: group)
                section.orthogonalScrollingBehavior = .paging
                
                return section
                
            } else {
                
                let item = NSCollectionLayoutItem(layoutSize: .init(widthDimension: .fractionalWidth(1), heightDimension: .fractionalHeight(1)))
                item.contentInsets.trailing = 8
                item.contentInsets.top = 16
                item.contentInsets.bottom = 32
                
                let group = NSCollectionLayoutGroup.horizontal(layoutSize: .init(widthDimension: .estimated(125), heightDimension: .estimated(225)), subitems: [item])
                let section = NSCollectionLayoutSection(group: group)
                section.orthogonalScrollingBehavior = .continuous
                section.contentInsets.leading = 20
                section.boundarySupplementaryItems = [.init(layoutSize: .init(widthDimension: .fractionalWidth(1), heightDimension: .estimated(20)), elementKind: HomeViewController().categoryHeaderId, alignment: .topLeading)]
                
                return section
                
            }
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
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        .lightContent
    }
    
}

//MARK: - Collection View Setup

extension HomeViewController {
    
    private func setupCollectionView() {
        collectionView.dataSource = self
        collectionView.delegate = self
        
        collectionView.backgroundColor = .clear
        collectionView.decelerationRate = .fast
        collectionView.contentInsetAdjustmentBehavior = .never
        collectionView.showsHorizontalScrollIndicator = false
        collectionView.showsVerticalScrollIndicator = false
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        collectionView.register(UICollectionViewCell.self, forCellWithReuseIdentifier: cellId)
        collectionView.register(HomeViewHeader.self, forSupplementaryViewOfKind: categoryHeaderId, withReuseIdentifier: headerId)
        
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

extension HomeViewController: UICollectionViewDataSource {
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        
        if section == 0 {
            return 3
        } else {
            return 6
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: cellId, for: indexPath)
        
        let imageView = UIImageView(frame: cell.contentView.bounds)
        imageView.contentMode = .scaleAspectFit
        imageView.clipsToBounds = true
        
        switch indexPath.section {
        case 0:
            imageView.image = UIImage(named: HomeDummyData.section0Images[indexPath.item])
        case 1:
            imageView.image = UIImage(named: HomeDummyData.section1Images[indexPath.item])
        case 2:
            imageView.image = UIImage(named: HomeDummyData.section2Images[indexPath.item])
        default:
            break
        }
        
        cell.contentView.subviews.forEach { $0.removeFromSuperview() }
        cell.contentView.addSubview(imageView)
        
        return cell
    }
    
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 3
    }
    
    func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        let header = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: headerId, for: indexPath) as! HomeViewHeader
        
        switch indexPath.section {
        case 1:
            header.configure(with: "Popular Movies")
        case 2:
            header.configure(with: "Coming Soon")
        default:
            break
        }
        
        return header
    }
}

//MARK: - Collection View Delegate

extension HomeViewController: UICollectionViewDelegate {
    
    
    
}

//MARK: - Navigation Bar Setup

extension HomeViewController {
    
    private func setupNavbar() {
        
        UINavigationBar.appearance().barTintColor = mdbNavbar
        
        let appLogo = UIImage(named: "logo")?.withRenderingMode(.alwaysOriginal)
        let leftBarButtonItem = UIBarButtonItem(image: appLogo, style: .plain, target: nil, action: nil)
        leftBarButtonItem.imageInsets = UIEdgeInsets(top: 0, left: 15, bottom: 15, right: 0)
        leftBarButtonItem.isEnabled = false
        navigationItem.leftBarButtonItem = leftBarButtonItem
        
        
        let bellImage = UIImage(resource: .notificationBell).withTintColor(.white, renderingMode: .alwaysOriginal)
        let rightBarButtonItem = UIBarButtonItem(image: bellImage, style: .plain, target: self, action: nil)
        rightBarButtonItem.imageInsets = UIEdgeInsets(top: 0, left: 0, bottom: 15, right: 15)
        navigationItem.rightBarButtonItem = rightBarButtonItem
    }
    
}
