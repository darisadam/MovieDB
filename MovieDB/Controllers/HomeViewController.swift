//
//  HomeViewController.swift
//  MovieDB
//
//  Created by Adam Daris Ryadhi on 22/11/24.
//

import UIKit

class HomeViewController: UIViewController {
    
    let cellId = "homeCell"
    let headerId = "homeHeader"
    let categoryHeaderId = "homeCategoryHeader"
    let screenWidth = UIScreen.main.bounds.size.width
    let screenHeight = UIScreen.main.bounds.size.height
    
    let section0Images = ["captainamerica", "captainamerica", "captainamerica"]
    let section1Images = ["split", "rover", "greenbook", "split", "rover", "greenbook"]
    let section2Images = ["cars", "murdermystery", "avengers", "cars", "murdermystery", "avengers"]
    
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
        collectionView.backgroundColor = .clear
        
        return collectionView
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = UIColor(hexString: "#25272A")
        configureNavbar()
        
        collectionViewSetup()
        
        print("home")
    }
    
}

//MARK: - Collection View Setup

extension HomeViewController {
    
    private func collectionViewSetup() {
        collectionView.dataSource = self
        collectionView.delegate = self
        
        collectionView.backgroundColor = .clear
        collectionView.decelerationRate = .fast
        collectionView.contentInsetAdjustmentBehavior = .never
        collectionView.showsHorizontalScrollIndicator = false
        collectionView.showsVerticalScrollIndicator = false
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        collectionView.register(UICollectionViewCell.self, forCellWithReuseIdentifier: cellId)
        collectionView.register(HomeView.self, forSupplementaryViewOfKind: categoryHeaderId, withReuseIdentifier: headerId)
        
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
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        
        switch indexPath.section {
        case 0:
            imageView.image = UIImage(named: section0Images[indexPath.item])
        case 1:
            imageView.image = UIImage(named: section1Images[indexPath.item])
        case 2:
            imageView.image = UIImage(named: section2Images[indexPath.item])
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
        let header = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: headerId, for: indexPath) as! HomeView
        
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

//MARK: - Home Navigation Bar

extension HomeViewController {
    
    private func configureNavbar() {
          
        let appLogo = UIImage(named: "logo")?.withRenderingMode(.alwaysOriginal)
        let leftBarButtonItem = UIBarButtonItem(image: appLogo, style: .plain, target: nil, action: nil)
        leftBarButtonItem.imageInsets = UIEdgeInsets(top: 0, left: 15, bottom: 15, right: 0)
        navigationItem.leftBarButtonItem = leftBarButtonItem
        
        
        let bellImage = UIImage(systemName: "bell")?.withTintColor(.white, renderingMode: .alwaysOriginal)
        let rightBarButtonItem = UIBarButtonItem(image: bellImage, style: .plain, target: self, action: nil)
        rightBarButtonItem.imageInsets = UIEdgeInsets(top: 0, left: 0, bottom: 15, right: 15)
        navigationItem.rightBarButtonItem = rightBarButtonItem
    }
    
}
