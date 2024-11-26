//
//  HomeViewController.swift
//  MovieDB
//
//  Created by Adam Daris Ryadhi on 22/11/24.
//

import UIKit

class HomeViewController: UIViewController {
    
    private let homeMovieTable: UITableView = {
        let table = UITableView(frame: .zero, style: .grouped)
        table.register(HomeTableView.self, forCellReuseIdentifier: HomeTableView.identifier)
        table.backgroundColor = .clear
        return table
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = UIColor(hexString: "#25272A")
        view.addSubview(homeMovieTable)
        
        homeMovieTable.delegate = self
        homeMovieTable.dataSource = self
        
        configureNavbar()
        
        homeMovieTable.tableHeaderView = UIView(frame: CGRect(x: 0, y: 0, width: view.bounds.width, height: 275))
        
        print("home")
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        homeMovieTable.frame = view.bounds
    }

}

//MARK: - Movie List Table View

extension HomeViewController: UITableViewDelegate, UITableViewDataSource {
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 2
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        guard let cell = tableView.dequeueReusableCell(withIdentifier: HomeTableView.identifier, for: indexPath) as? HomeTableView else {
            return UITableViewCell()
        }
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 200
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 40
    }
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        let defaultOffset = view.safeAreaInsets.top
        let offset = scrollView.contentOffset.y + defaultOffset
        
        navigationController?.navigationBar.transform = .init(translationX: 0, y: min(0, -offset))
    }
    
}

//MARK: - Home Navigation Bar

extension HomeViewController {
    private func configureNavbar() {
        // Configure left side title
        let movieText = NSAttributedString(
            string: "Movie",
            attributes: [
                .foregroundColor: UIColor(hexString: "FFFFFF"),
                .font: UIFont.systemFont(ofSize: UIFont.preferredFont(forTextStyle: .title2).pointSize, weight: .bold)
            ]
        )
        
        let dbText = NSAttributedString(
            string: "DB",
            attributes: [
                .foregroundColor: UIColor(hexString: "#FFD130"),
                .font: UIFont.systemFont(ofSize: UIFont.preferredFont(forTextStyle: .title2).pointSize, weight: .bold)
            ]
        )
        
        let combinedText = NSMutableAttributedString()
        combinedText.append(movieText)
        combinedText.append(dbText)
        
        let titleLabel = UILabel()
        titleLabel.attributedText = combinedText
        
        navigationItem.leftBarButtonItem = UIBarButtonItem(customView: titleLabel)
        
        let bellImage = UIImage(systemName: "bell")?.withTintColor(.white, renderingMode: .alwaysOriginal)
        let bellButton = UIBarButtonItem(
            image: bellImage,
            style: .plain,
            target: self,
            action: #selector(bellButtonTapped)
        )
        
        navigationItem.rightBarButtonItem = bellButton
    }
    
    @objc private func bellButtonTapped() {
        // Handle bell button tap
        print("Notification button tapped")
    }
}
