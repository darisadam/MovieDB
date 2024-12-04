//
//  TabBarController.swift
//  MovieDB
//
//  Created by Adam Daris Ryadhi on 23/11/24.
//

import UIKit

class TabBarController: UITabBarController {

    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupTabs()
    }
    
    private func setupTabs() {
        let tabBarAppearance = UITabBarAppearance()
        tabBarAppearance.configureWithDefaultBackground()
        tabBarAppearance.backgroundColor = mdbTabBar
        UITabBar.appearance().standardAppearance = tabBarAppearance
        UITabBar.appearance().scrollEdgeAppearance = tabBarAppearance
        
        let home = createNav(image: UIImage(resource: .home), vc: HomeViewController())
        let popular = createNav(image: UIImage(resource: .popular), vc: PopularViewController())
        let favorite = createNav(image: UIImage(resource: .favorite), vc: FavoriteViewController())
        let menu = createNav(image: UIImage(resource: .menu), vc: MenuViewController())
        
        setViewControllers([home, popular, favorite, menu], animated: true)
    }
    
    private func createNav(image: UIImage?, vc: UIViewController) -> UINavigationController {
        
        let nav = UINavigationController(rootViewController: vc)
        nav.tabBarItem.image = image
        
        tabBar.backgroundColor = mdbTabBar
        tabBar.tintColor = mdbTabBarIcon
        tabBar.unselectedItemTintColor = mdbWhite
        
        return nav
    }
}
