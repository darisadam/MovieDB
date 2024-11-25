//
//  MovieTabBar.swift
//  MovieDB
//
//  Created by Adam Daris Ryadhi on 23/11/24.
//

import UIKit

class MovieTabBar: UITabBarController {

    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupTabs()
    }
    
    private func setupTabs() {
        let home = createNav(image: UIImage(systemName: "house"), vc: HomeViewController())
        let popular = createNav(image: UIImage(systemName: "magnifyingglass"), vc: PopularViewController())
        let favorite = createNav(image: UIImage(systemName: "heart"), vc: FavoriteViewController())
        let menu = createNav(image: UIImage(systemName: "square.grid.2x2"), vc: MenuViewController())
        
        setViewControllers([home, popular, favorite, menu], animated: true)
    }
    
    private func createNav(image: UIImage?, vc: UIViewController) -> UINavigationController {
        
        let nav = UINavigationController(rootViewController: vc)
        nav.tabBarItem.image = image
        
        tabBar.backgroundColor = UIColor(hexString: "#202123")
        tabBar.tintColor = UIColor(hexString: "#FFD130")
        tabBar.unselectedItemTintColor = UIColor(hexString: "#FFFFFF")
        
        return nav
    }
}
