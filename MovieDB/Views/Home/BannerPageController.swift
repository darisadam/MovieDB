//
//  BannerPageController.swift
//  MovieDB
//
//  Created by Adam Daris Ryadhi on 26/11/24.
//

import UIKit

extension UIPageControl {
    var page: Int {
        get {
            return currentPage
        }
        set {
            currentPage = newValue
            
            for index in 0..<numberOfPages where index != newValue {
                preferredIndicatorImage = UIImage.captainamerica
            }
            
            setIndicatorImage(UIImage.captainamerica, forPage: page)
        }
    }
}

struct HomeBanner {
    static let one = UIImage.captainamerica
    static let two = UIImage.captainamerica
    static let three = UIImage.captainamerica
    
//    static let page = 
}
