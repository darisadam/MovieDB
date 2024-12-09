//
//  MenuViewController.swift
//  MovieDB
//
//  Created by Adam Daris Ryadhi on 23/11/24.
//

import SwiftUI

class MenuViewController: UICollectionViewController {
    
    //MARK: - Variables and Constants
    
    private let cellId = "menuCell"
    
    //MARK: - Initializer
    
    init() {
        let layout = UICollectionViewCompositionalLayout { (sectionNumber, env) in
            let item = NSCollectionLayoutItem.init(layoutSize: .init(widthDimension: .fractionalWidth(0.5), heightDimension: .fractionalHeight(1)))
            item.contentInsets.bottom = 10
            item.contentInsets.top = 10
            item.contentInsets.leading = 10
            item.contentInsets.trailing = 10
            
            let group = NSCollectionLayoutGroup.horizontal(layoutSize: .init(widthDimension: .fractionalWidth(1), heightDimension: .fractionalHeight(0.2)), subitems: [item])
            let section = NSCollectionLayoutSection(group: group)
            
            return section
        }
        
        super.init(collectionViewLayout: layout)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    //MARK: - Life Cycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupNavbar()
        setupCollectionView()
        
        view.backgroundColor = mdbBackground
    }
    
}

//MARK: - Components Setup

extension MenuViewController {
    
    private func setupCollectionView() {
        collectionView.register(MenuCollectionViewCell.self, forCellWithReuseIdentifier: cellId)
        collectionView.backgroundColor = .clear
    }
    
}

//MARK: - Collection View Data Source

extension MenuViewController {
    
    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return 8
    }
    
    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: cellId, for: indexPath) as! MenuCollectionViewCell
        
        // Configure cell based on index
        switch indexPath.item {
        case 0:
            cell.configure(systemImageName: "film", text: "Movies")
        case 1:
            cell.configure(systemImageName: "tv", text: "TV Shows")
        case 2:
            cell.configure(systemImageName: "person", text: "Actors")
        case 3:
            cell.configure(systemImageName: "star", text: "Favorites")
        case 4:
            cell.configure(systemImageName: "globe", text: "Discover")
        case 5:
            cell.configure(systemImageName: "clock", text: "History")
        case 6:
            cell.configure(systemImageName: "arrow.down", text: "Downloads")
        case 7:
            cell.configure(systemImageName: "gear", text: "Settings")
        default:
            break
        }
        
        return cell
    }
    
}

//MARK: - Navigation Bar Setup

extension MenuViewController {
    
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

//MARK: - Preview

struct MenuViewController_Previews: PreviewProvider {
    
    static var previews: some View {
        Container().edgesIgnoringSafeArea(.all)
    }
    
    struct Container: UIViewControllerRepresentable {
        func makeUIViewController(context: Context) -> UIViewController {
            UINavigationController(rootViewController: TabBarController())
        }
        
        func updateUIViewController(_ uiViewController: UIViewControllerType, context: Context) {
            
        }
        
        typealias UIViewControllerType = UIViewController
    }
}
