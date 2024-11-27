//
//  HomeViewController.swift
//  MovieDB
//
//  Created by Adam Daris Ryadhi on 22/11/24.
//

import UIKit

class HomeViewController: UIViewController {
    
    let sectionTitles = ["Popular Movies", "Coming Soon"]
    
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
        
//        homeMovieTable.tableHeaderView = UIView(frame: CGRect(x: 0, y: 0, width: view.bounds.width, height: 275))
        
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
        return sectionTitles.count
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
    
    func tableView(_ tableView: UITableView, willDisplayHeaderView view: UIView, forSection section: Int) {
        guard let header = view as? UITableViewHeaderFooterView else { return }
        header.textLabel?.font = UIFont.systemFont(ofSize: UIFont.preferredFont(forTextStyle: .headline).pointSize, weight: .bold)
        header.textLabel?.frame = CGRect(x: header.bounds.origin.x, y: header.bounds.origin.y, width: 100, height: header.bounds.height)
        header.textLabel?.textColor = UIColor(hexString: "FFFFFF")
        header.textLabel?.text = header.textLabel?.text?.capitalized
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return sectionTitles[section]
    }
    
}

//MARK: - Home Navigation Bar

extension HomeViewController {
    
    private func configureNavbar() {
        let appLogo = UIImage(named: "logo")?.withRenderingMode(.alwaysOriginal)
        navigationItem.leftBarButtonItem = UIBarButtonItem(image: appLogo, style: .plain, target: nil, action: nil)
        
        let bellImage = UIImage(systemName: "bell")?.withTintColor(.white, renderingMode: .alwaysOriginal)
        navigationItem.rightBarButtonItem = UIBarButtonItem(image: bellImage, style: .plain, target: self, action: nil)
    }
    
}
