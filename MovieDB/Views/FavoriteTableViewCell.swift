//
//  FavoriteTableViewCell.swift
//  MovieDB
//
//  Created by Adam Daris Ryadhi on 27/11/24.
//

import UIKit

class FavoriteTableViewCell: UITableViewCell {
    
    private var isFavorited = true
    
    //MARK: - Components
    
    private let movieImage: UIImageView = {
        let image = UIImageView()
        image.contentMode = .scaleAspectFit
        image.image = UIImage(resource: .cars3)
        return image
    }()
    
    private let movieTitle: UILabel = {
        let label = UILabel()
        label.textColor = mdbWhite
        label.textAlignment = .left
        label.font = .systemFont(ofSize: 16, weight: .regular)
        label.text = "Cars 3"
        return label
    }()
    
    private let movieYear: UILabel = {
        let label = UILabel()
        label.textColor = mdbWhite.withAlphaComponent(0.7)
        label.textAlignment = .left
        label.font = .systemFont(ofSize: 14, weight: .regular)
        label.text = "2020"
        return label
    }()
    
    private let movieGenre: UILabel = {
        let label = UILabel()
        label.textColor = mdbWhite.withAlphaComponent(0.4)
        label.textAlignment = .justified
        label.font = .systemFont(ofSize: 12, weight: .regular)
        label.numberOfLines = 2
        label.text = "Kids, Comedy, Racing"
        return label
    }()
    
    private lazy var favoriteButton: UIButton = {
        var button = UIButton()
        updateButtonAppearance(button: button)
        
        button.addTarget(self, action: #selector(toggleFavoriteButton), for: .touchUpInside)
        
        return button
    }()
    
    func configure(with movie: FavoriteData) {
        movieImage.image = UIImage(named: movie.imageName)
        movieTitle.text = movie.title
        movieYear.text = movie.year
        movieGenre.text = movie.genre
        isFavorited = movie.isFavorited
        updateButtonAppearance(button: favoriteButton)
    }
    
    //MARK: - Update Button Appearance
    
    private func updateButtonAppearance(button: UIButton) {
        var configuration = UIButton.Configuration.plain()
        
        if isFavorited {
            var symbolConfig = UIImage.SymbolConfiguration(paletteColors: [mdbYellow, mdbDarkYellow])
            symbolConfig = symbolConfig.applying(UIImage.SymbolConfiguration(pointSize: 16))
            configuration.image = UIImage(systemName: "heart.circle.fill", withConfiguration: symbolConfig)
        } else {
            let symbolConfig = UIImage.SymbolConfiguration(pointSize: 12)
            configuration.image = UIImage(systemName: "heart", withConfiguration: symbolConfig)
            configuration.baseForegroundColor = mdbYellow
        }
        
        button.configuration = configuration
    }
    
    @objc private func toggleFavoriteButton() {
        isFavorited.toggle()
        updateButtonAppearance(button: favoriteButton)
    }
    
    //MARK: - Initializer
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        self.setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    //MARK: - UI Setup
    
    private func setupUI() {
        contentView.addSubview(movieImage)
        contentView.addSubview(movieTitle)
        contentView.addSubview(movieYear)
        contentView.addSubview(movieGenre)
        contentView.addSubview(favoriteButton)
        
        movieImage.translatesAutoresizingMaskIntoConstraints = false
        movieTitle.translatesAutoresizingMaskIntoConstraints = false
        movieYear.translatesAutoresizingMaskIntoConstraints = false
        movieGenre.translatesAutoresizingMaskIntoConstraints = false
        favoriteButton.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            movieImage.topAnchor.constraint(equalTo: contentView.layoutMarginsGuide.topAnchor),
            movieImage.bottomAnchor.constraint(equalTo: contentView.layoutMarginsGuide.bottomAnchor),
            movieImage.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            movieImage.heightAnchor.constraint(equalToConstant: 100),
            movieImage.widthAnchor.constraint(equalToConstant: 225),
            
            movieTitle.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 20),
            movieTitle.bottomAnchor.constraint(equalTo: movieYear.topAnchor, constant: -10),
            movieTitle.leadingAnchor.constraint(equalTo: movieImage.trailingAnchor, constant: 1),
            movieTitle.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            
            movieYear.topAnchor.constraint(equalTo: movieTitle.bottomAnchor),
            movieYear.bottomAnchor.constraint(equalTo: movieGenre.topAnchor, constant: -10),
            movieYear.leadingAnchor.constraint(equalTo: movieImage.trailingAnchor, constant: 1),
            movieYear.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            
            movieGenre.topAnchor.constraint(equalTo: movieYear.bottomAnchor),
            movieGenre.leadingAnchor.constraint(equalTo: movieImage.trailingAnchor, constant: 1),
            movieGenre.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            
            favoriteButton.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 15),
            favoriteButton.trailingAnchor.constraint(equalTo: contentView.layoutMarginsGuide.trailingAnchor),
        ])
    }
    
}
