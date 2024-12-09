//
//  DetailViewController.swift
//  MovieDB
//
//  Created by Adam Daris Ryadhi on 25/11/24.
//

import UIKit

class DetailViewController: UIViewController {
    
    //MARK: - Variables and Constants
    
    private let cellId = "detailCell"
    private let headerId = "detailHeader"
    private let categoryHeaderId = "detailCategoryHeader"
    
    private let movieDetail = MovieDetailDummyData.movie
    
    //MARK: - Components
    
    let collectionView: UICollectionView = {
        let layout = UICollectionViewCompositionalLayout { (sectionNumber, env) -> NSCollectionLayoutSection in
            
            if sectionNumber == 0 {
                let item = NSCollectionLayoutItem(layoutSize: .init(widthDimension: .fractionalWidth(1), heightDimension: .estimated(300)))
                item.contentInsets.bottom = 30
                
                let group = NSCollectionLayoutGroup.vertical(layoutSize: .init(widthDimension: .fractionalWidth(1), heightDimension: .estimated(300)), subitems: [item])
                let section = NSCollectionLayoutSection(group: group)
                
                return section
                
            } else if sectionNumber == 1 {
                let item = NSCollectionLayoutItem(layoutSize: .init(widthDimension: .fractionalWidth(1), heightDimension: .estimated(200)))
                item.contentInsets.bottom = 30
                
                let group = NSCollectionLayoutGroup.vertical(layoutSize: .init(widthDimension: .fractionalWidth(1), heightDimension: .estimated(200)), subitems: [item])
                let section = NSCollectionLayoutSection(group: group)
                section.contentInsets.leading = 16
                section.contentInsets.trailing = 16
                
                return section
                
            } else {
                let item = NSCollectionLayoutItem(layoutSize: .init(widthDimension: .fractionalWidth(0.333), heightDimension: .fractionalHeight(0.75)))
                item.contentInsets.leading = 5
                item.contentInsets.trailing = 5
                
                let group = NSCollectionLayoutGroup.horizontal(layoutSize: .init(widthDimension: .fractionalWidth(1), heightDimension: .estimated(200)), subitems: [item])
                let section = NSCollectionLayoutSection(group: group)
                section.orthogonalScrollingBehavior = .continuous
                section.boundarySupplementaryItems = [.init(layoutSize: .init(widthDimension: .fractionalWidth(1), heightDimension: .estimated(20)), elementKind: DetailViewController().categoryHeaderId, alignment: .topLeading)]
                
                return section
            }
        }
        
        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        
        return collectionView
    }()
    
    //MARK: - Life Cycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupCollectionView()
        
        view.backgroundColor = mdbBackground
    }
    
    //MARK: - Collection View Setup
    
    private func setupCollectionView() {
        collectionView.dataSource = self
        collectionView.delegate = self
        
        collectionView.backgroundColor = .clear
        collectionView.decelerationRate = .fast
        collectionView.contentInsetAdjustmentBehavior = .never
        collectionView.showsHorizontalScrollIndicator = false
        collectionView.showsVerticalScrollIndicator = false
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        collectionView.register(UICollectionViewCell.self, forCellWithReuseIdentifier: cellId)
        collectionView.register(DetailViewHeader.self, forSupplementaryViewOfKind: categoryHeaderId, withReuseIdentifier: headerId)
        
        view.addSubview(collectionView)
        
        NSLayoutConstraint.activate([
            collectionView.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor),
            collectionView.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor),
            collectionView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            collectionView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }
}

//MARK: - Collection View Data Source

extension DetailViewController: UICollectionViewDataSource {
    
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 3
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        switch section {
        case 0: return 1
        case 1: return 1
        case 2: return movieDetail.movieCast.count
        default: return 0
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: cellId, for: indexPath)
        cell.backgroundColor = .clear
        cell.contentView.subviews.forEach { $0.removeFromSuperview() }
        
        switch indexPath.section {
        case 0:
            let stackView = UIStackView()
            stackView.axis = .vertical
            stackView.spacing = 10
            stackView.translatesAutoresizingMaskIntoConstraints = false
            
            let imageView = UIImageView()
            imageView.image = UIImage(named: movieDetail.movieImage)
            imageView.contentMode = .scaleAspectFit
            imageView.heightAnchor.constraint(equalToConstant: 250).isActive = true
            stackView.addArrangedSubview(imageView)
            
            let titleLabel = UILabel()
            titleLabel.text = movieDetail.movieTitle
            titleLabel.font = .boldSystemFont(ofSize: 24)
            titleLabel.textAlignment = .center
            stackView.addArrangedSubview(titleLabel)
            
            let detailsLabel = UILabel()
            detailsLabel.text = "\(movieDetail.movieDuration) • \(movieDetail.movieQuality)"
            detailsLabel.font = .systemFont(ofSize: 16)
            detailsLabel.textAlignment = .center
            stackView.addArrangedSubview(detailsLabel)
            
            let genresLabel = UILabel()
            let genreNames = movieDetail.movieGenre.map { $0.genreName }.joined(separator: " • ")
            genresLabel.text = genreNames
            genresLabel.font = .systemFont(ofSize: 16)
            genresLabel.textAlignment = .center
            stackView.addArrangedSubview(genresLabel)
            
            cell.contentView.addSubview(stackView)
            
            NSLayoutConstraint.activate([
                stackView.topAnchor.constraint(equalTo: cell.contentView.topAnchor),
                stackView.leadingAnchor.constraint(equalTo: cell.contentView.leadingAnchor),
                stackView.trailingAnchor.constraint(equalTo: cell.contentView.trailingAnchor)
            ])
            
        case 1:
            let descriptionLabel = UILabel()
            descriptionLabel.text = movieDetail.movieDescription
            descriptionLabel.numberOfLines = 0
            descriptionLabel.font = .systemFont(ofSize: 16)
            descriptionLabel.translatesAutoresizingMaskIntoConstraints = false
            
            cell.contentView.addSubview(descriptionLabel)
            
            NSLayoutConstraint.activate([
                descriptionLabel.topAnchor.constraint(equalTo: cell.contentView.topAnchor),
                descriptionLabel.leadingAnchor.constraint(equalTo: cell.contentView.leadingAnchor),
                descriptionLabel.trailingAnchor.constraint(equalTo: cell.contentView.trailingAnchor)
            ])
            
        case 2:
            let castMember = movieDetail.movieCast[indexPath.item]
            
            let stackView = UIStackView()
            stackView.axis = .vertical
            stackView.spacing = 5
            stackView.translatesAutoresizingMaskIntoConstraints = false
            
            let imageView = UIImageView()
            imageView.image = UIImage(named: castMember.actorImage)
            imageView.contentMode = .scaleAspectFit
            imageView.layer.cornerRadius = 10
            imageView.clipsToBounds = true
            imageView.heightAnchor.constraint(equalToConstant: 120).isActive = true
            stackView.addArrangedSubview(imageView)
            
            let nameLabel = UILabel()
            nameLabel.text = castMember.actorName
            nameLabel.font = .systemFont(ofSize: 14)
            nameLabel.textAlignment = .center
            stackView.addArrangedSubview(nameLabel)
            
            cell.contentView.addSubview(stackView)
            
            NSLayoutConstraint.activate([
                stackView.topAnchor.constraint(equalTo: cell.contentView.topAnchor),
                stackView.leadingAnchor.constraint(equalTo: cell.contentView.leadingAnchor),
                stackView.trailingAnchor.constraint(equalTo: cell.contentView.trailingAnchor)
            ])
            
        default:
            break
        }
        
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        let header = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: headerId, for: indexPath) as! DetailViewHeader
        
        if indexPath.section == 2 {
            header.configure(with: "Cast")
        }
        
        return header
    }
}

//MARK: - Collection View Delegate

extension DetailViewController: UICollectionViewDelegate {
    
}
