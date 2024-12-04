//
//  HomeCollectionReusableView.swift
//  MovieDB
//
//  Created by Adam Daris Ryadhi on 27/11/24.
//

import UIKit

class HomeCollectionReusableView: UICollectionReusableView {

    let headerLabel = UILabel()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        setupHeader()
        addSubview(headerLabel)
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        headerLabel.frame = bounds
    }
    
    func configure(with title: String) {
        headerLabel.text = title
        headerLabel.textColor = mdbWhite
        headerLabel.font = UIFont.systemFont(ofSize: 20, weight: .bold)
    }
    
    func setupHeader() {
        headerLabel.textColor = mdbWhite
        headerLabel.font = UIFont.systemFont(ofSize: 20, weight: .bold)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
}

