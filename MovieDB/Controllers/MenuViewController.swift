//
//  MenuViewController.swift
//  MovieDB
//
//  Created by Adam Daris Ryadhi on 23/11/24.
//

import SwiftUI

class MenuViewController: UICollectionViewController {
    
    init() {
        let layout = UICollectionViewCompositionalLayout { (sectionNumber, env) in
            let item = NSCollectionLayoutItem.init(layoutSize: .init(widthDimension: .fractionalWidth(0.5), heightDimension: .fractionalHeight(1)))
            item.contentInsets.bottom = 10
            item.contentInsets.top = 10
            item.contentInsets.leading = 10
            item.contentInsets.trailing = 10
            
            let group = NSCollectionLayoutGroup.horizontal(layoutSize: .init(widthDimension: .fractionalWidth(1), heightDimension: .absolute(200)), subitems: [item])
            let section = NSCollectionLayoutSection(group: group)
            
            return section
        }
        
        super.init(collectionViewLayout: layout)
    }
    
    private let cellId = "menuCell"
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupCollectionView()
        
        view.backgroundColor = UIColor(hexString: "#25272A")
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
}

extension MenuViewController {
    
    private func setupCollectionView() {
        collectionView.register(UICollectionViewCell.self, forCellWithReuseIdentifier: cellId)
        collectionView.backgroundColor = .clear
    }
    
}

extension MenuViewController {
    
    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return 8
    }
    
    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: cellId, for: indexPath)
        cell.backgroundColor = .red
        return cell
    }
    
}

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

