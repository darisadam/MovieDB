//
//  PopularCollectionViewCell.swift
//  MovieDB
//
//  Created by Adam Daris Ryadhi on 27/11/24.
//

import UIKit

class PopularCollectionViewCell: UICollectionViewCell {
    // Movie image
    private let movieImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.image = UIImage(named: "mz1") // Assuming "mz1" is in your asset catalog
        imageView.contentMode = .scaleAspectFit
        imageView.clipsToBounds = true
        imageView.translatesAutoresizingMaskIntoConstraints = false
        return imageView
    }()
    
    // Movie title label
    private let titleLabel: UILabel = {
        let label = UILabel()
        label.text = "Maze Runner"
        label.textAlignment = .center
        label.font = UIFont.systemFont(ofSize: 16, weight: .bold)
        label.textColor = mdbWhite
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    // Actors label
    private let actorsLabel: UILabel = {
        let label = UILabel()
        label.text = "Dylan O'Brien, Kaya Scodelario, Will Poulter"
        label.textAlignment = .center
        label.font = UIFont.systemFont(ofSize: 14)
        label.textColor = mdbWhite
        label.numberOfLines = 2
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupCell()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupCell() {
        // Add image and labels to the cell's content view
        contentView.addSubview(movieImageView)
        contentView.addSubview(titleLabel)
        contentView.addSubview(actorsLabel)
        
        // Set up constraints for movie image
        NSLayoutConstraint.activate([
            movieImageView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 10),
            movieImageView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 10),
            movieImageView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -10),
            movieImageView.heightAnchor.constraint(equalToConstant: 150) // Adjust height as needed
        ])
        
        // Set up constraints for title label
        NSLayoutConstraint.activate([
            titleLabel.topAnchor.constraint(equalTo: movieImageView.bottomAnchor, constant: 10),
            titleLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 10),
            titleLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -10)
        ])
        
        // Set up constraints for actors label
        NSLayoutConstraint.activate([
            actorsLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 5),
            actorsLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 10),
            actorsLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -10)
        ])
    }
}
