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
        
        homeMovieTable.tableHeaderView = UIView(frame: CGRect(x: 0, y: 0, width: view.bounds.width, height: 450))
        
        print("home")
    }
    
    private func configureNavbar() {
        let movieText = NSAttributedString(
            string: "Movie",
            attributes: [
                .foregroundColor: UIColor(hexString: "FFFFFF"),
                .font: UIFont.TextStyle.title2,
                .font: UIFont.Weight.bold,
            ]
        )
        
        let dbText = NSAttributedString(
            string: "DB",
            attributes: [
                .foregroundColor: UIColor(hexString: "FFFFFF"),
                .font: UIFont.TextStyle.title2,
                .font: UIFont.Weight.bold,
            ]
        )
        
        let combinedText = NSMutableAttributedString()
        combinedText.append(movieText)
        combinedText.append(dbText)
        
        let titleLabel = UILabel()
        titleLabel.attributedText = combinedText
        navigationItem.titleView = titleLabel
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        homeMovieTable.frame = view.bounds
    }

}

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
    
}
