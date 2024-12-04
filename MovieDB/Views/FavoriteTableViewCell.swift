//
//  FavoriteTableViewCell.swift
//  MovieDB
//
//  Created by Adam Daris Ryadhi on 27/11/24.
//

import UIKit

class FavoriteTableViewCell: UITableViewCell {
    
    private let movieImage: UIImageView = {
        let image = UIImageView()
        image.contentMode = .scaleAspectFit
        image.image = UIImage(resource: .cars3)
        
        return image
    }()
    
    private let movieLabel: UILabel = {
        let label = UILabel()
        label.textColor = mdbWhite
        label.textAlignment = .left
        label.font = .systemFont(ofSize: 16, weight: .regular)
        label.text = "Cars 3"
        return label
    }()
    
    private let movieYear: UILabel = {
        let label = UILabel()
        label.textColor = mdbWhite
        label.textAlignment = .left
        label.font = .systemFont(ofSize: 14, weight: .regular)
        label.text = "2020"
        return label
    }()
    
    private let movieGenre: UILabel = {
        let label = UILabel()
        label.textColor = mdbWhite
        label.textAlignment = .left
        label.font = .systemFont(ofSize: 12, weight: .regular)
        label.text = "Kids, Comedy, Racing"
        return label
    }()
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        self.setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupUI() {
        contentView.addSubview(movieImage)
        contentView.addSubview(movieLabel)
        contentView.addSubview(movieYear)
        contentView.addSubview(movieGenre)
        
        movieImage.translatesAutoresizingMaskIntoConstraints = false
        movieLabel.translatesAutoresizingMaskIntoConstraints = false
        movieYear.translatesAutoresizingMaskIntoConstraints = false
        movieGenre.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            movieImage.topAnchor.constraint(equalTo: contentView.layoutMarginsGuide.topAnchor),
            movieImage.bottomAnchor.constraint(equalTo: contentView.layoutMarginsGuide.bottomAnchor),
            movieImage.leadingAnchor.constraint(equalTo: contentView.layoutMarginsGuide.leadingAnchor),
            movieImage.heightAnchor.constraint(equalToConstant: 100),
            movieImage.widthAnchor.constraint(equalToConstant: 225),
            
            movieLabel.topAnchor.constraint(equalTo: contentView.topAnchor),
            movieLabel.bottomAnchor.constraint(equalTo: movieYear.topAnchor),
            movieLabel.leadingAnchor.constraint(equalTo: movieImage.trailingAnchor, constant: 10),
            movieLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            
            movieYear.topAnchor.constraint(equalTo: movieLabel.bottomAnchor),
            movieYear.bottomAnchor.constraint(equalTo: movieGenre.topAnchor),
            movieYear.leadingAnchor.constraint(equalTo: movieImage.trailingAnchor, constant: 10),
            movieYear.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            
            movieGenre.topAnchor.constraint(equalTo: movieYear.bottomAnchor),
            movieGenre.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
            movieGenre.leadingAnchor.constraint(equalTo: movieImage.trailingAnchor, constant: 10),
            movieGenre.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
        ])
    }
    
}
