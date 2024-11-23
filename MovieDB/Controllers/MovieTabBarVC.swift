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
        tabBar.backgroundColor = UIColor(hexString: "#202123")
        tabBar.tintColor = UIColor(hexString: "#FFD130")
        tabBar.unselectedItemTintColor = UIColor(hexString: "#FFFFFF")
    }
    
    private func setupTabs() {
        let dashboard = createNav(image: UIImage(systemName: "house"), vc: DashboardViewController())
        
        let search = createNav(image: UIImage(systemName: "magnifyingglass"), vc: SearchViewController())
        
        let favorite = createNav(image: UIImage(systemName: "heart"), vc: FavoriteViewController())
        
        let menu = createNav(image: UIImage(systemName: "square.grid.2x2"), vc: MenuViewController())
        
        setViewControllers([dashboard, search, favorite, menu], animated: true)
    }
    
    private func createNav(image: UIImage?, vc: UIViewController) -> UINavigationController {
        
        let nav = UINavigationController(rootViewController: vc)
        nav.tabBarItem.image = image
        
        return nav
    }
}
