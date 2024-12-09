//
//  PopularViewHeader.swift
//  MovieDB
//
//  Created by Adam Daris Ryadhi on 04/12/24.
//

import UIKit

class PopularViewHeader: UICollectionReusableView {
    
    private let headerLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.textColor = mdbWhite
        label.font = UIFont.systemFont(ofSize: 16, weight: .regular)
        return label
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        addSubview(headerLabel)
        
        NSLayoutConstraint.activate([
            headerLabel.topAnchor.constraint(equalTo: topAnchor, constant: 20),
            headerLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 20),
            headerLabel.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])
    }
    
    func configure(with title: String) {
        headerLabel.text = title
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
}
