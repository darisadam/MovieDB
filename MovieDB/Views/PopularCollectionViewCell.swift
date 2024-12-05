//
//  PopularCollectionViewCell.swift
//  MovieDB
//
//  Created by Adam Daris Ryadhi on 27/11/24.
//

import UIKit

class PopularCollectionViewCell: UICollectionViewCell {

    private let movieImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.image = UIImage(named: "mz1")
        imageView.contentMode = .scaleAspectFit
        imageView.clipsToBounds = true
        imageView.translatesAutoresizingMaskIntoConstraints = false
        return imageView
    }()
    
    private let titleLabel: UILabel = {
        let label = UILabel()
        label.text = "Maze Runner"
        label.textAlignment = .justified
        label.font = UIFont.systemFont(ofSize: 12, weight: .regular)
        label.textColor = mdbWhite
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let actorsLabel: UILabel = {
        let label = UILabel()
        label.text = "Dylan O'Brien, Kaya Scodelario, Will Poulter"
        label.textAlignment = .justified
        label.font = UIFont.systemFont(ofSize: 10, weight: .regular)
        label.textColor = mdbWhite.withAlphaComponent(0.6)
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
    
    func configure(with popularMovies: PopularData) {
        movieImageView.image = UIImage(named: popularMovies.imageName)
        titleLabel.text = popularMovies.title
        actorsLabel.text = popularMovies.actors
    }
    
    private func setupCell() {
        contentView.addSubview(movieImageView)
        contentView.addSubview(titleLabel)
        contentView.addSubview(actorsLabel)
        
        NSLayoutConstraint.activate([
            movieImageView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 10),
            movieImageView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 10),
            movieImageView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -10),
            movieImageView.heightAnchor.constraint(equalToConstant: 250)
        ])
        
        NSLayoutConstraint.activate([
            titleLabel.topAnchor.constraint(equalTo: movieImageView.bottomAnchor, constant: 10),
            titleLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 10),
            titleLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -10)
        ])
        
        NSLayoutConstraint.activate([
            actorsLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 5),
            actorsLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 10),
            actorsLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -10)
        ])
    }
}
