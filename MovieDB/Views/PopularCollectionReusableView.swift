//
//  PopularCollectionReusableView.swift
//  MovieDB
//
//  Created by Adam Daris Ryadhi on 04/12/24.
//

import UIKit

class PopularCollectionReusableView: UICollectionReusableView {
    
    private let headerLabel = UILabel()
    
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
        headerLabel.font = UIFont.systemFont(ofSize: 16, weight: .regular)
    }
    
    func setupHeader() {
        headerLabel.textColor = mdbWhite
        headerLabel.font = UIFont.systemFont(ofSize: 16, weight: .regular)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
