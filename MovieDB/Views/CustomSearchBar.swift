//
//  CustomSearchBar.swift
//  MovieDB
//
//  Created by Adam Daris Ryadhi on 05/12/24.
//

import UIKit

class CustomSearchBar: UIView {
    
    // MARK: - Properties
    
    private let searchTextField: UITextField = {
        let textField = UITextField()
        textField.translatesAutoresizingMaskIntoConstraints = false
        textField.attributedPlaceholder = NSAttributedString(string: "Search", attributes: [NSAttributedString.Key.foregroundColor : mdbWhite])
        textField.textColor = mdbWhite
        textField.borderStyle = .none
        textField.backgroundColor = .clear
        textField.leftView = UIView(frame: CGRect(x: 0, y: 0, width: 10, height: 40))
        textField.leftViewMode = .always
        
        let clearButton = UIButton(type: .custom)
        clearButton.setImage(UIImage(systemName: "multiply.circle.fill")?.withTintColor(mdbWhite, renderingMode: .alwaysOriginal), for: .normal)
        clearButton.frame = CGRect(x: 0, y: 0, width: 25, height: 25)
        textField.clearButtonMode = .whileEditing
        textField.rightView = clearButton
        textField.rightViewMode = .whileEditing
        
        return textField
    }()
    
    private let magnifyButton: UIButton = {
        let button = UIButton(type: .system)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setImage(UIImage(systemName: "magnifyingglass"), for: .normal)
        button.tintColor = mdbYellow
        return button
    }()
    
    private let dividerLine: UIView = {
        let line = UIView()
        line.translatesAutoresizingMaskIntoConstraints = false
        line.backgroundColor = mdbWhite.withAlphaComponent(0.4)
        return line
    }()
    
    // MARK: - Initializers
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupView()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupView()
    }
    
    // MARK: - Setup Methods
    
    private func setupView() {
        translatesAutoresizingMaskIntoConstraints = false
        backgroundColor = .clear
        
        addSubview(searchTextField)
        addSubview(magnifyButton)
        addSubview(dividerLine)
        
        setupConstraints()
    }
    
    private func setupConstraints() {
        NSLayoutConstraint.activate([
            
            widthAnchor.constraint(equalToConstant: 360),
            heightAnchor.constraint(equalToConstant: 40),
            
            searchTextField.leadingAnchor.constraint(equalTo: leadingAnchor),
            searchTextField.topAnchor.constraint(equalTo: topAnchor),
            searchTextField.bottomAnchor.constraint(equalTo: dividerLine.topAnchor),
            searchTextField.trailingAnchor.constraint(equalTo: magnifyButton.leadingAnchor, constant: -25),
            
            magnifyButton.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -15),
            magnifyButton.centerYAnchor.constraint(equalTo: searchTextField.centerYAnchor),
            magnifyButton.widthAnchor.constraint(equalToConstant: 25),
            magnifyButton.heightAnchor.constraint(equalToConstant: 25),

            dividerLine.leadingAnchor.constraint(equalTo: leadingAnchor),
            dividerLine.trailingAnchor.constraint(equalTo: trailingAnchor),
            dividerLine.bottomAnchor.constraint(equalTo: bottomAnchor),
            dividerLine.heightAnchor.constraint(equalToConstant: 1)
        ])
    }
    
    // MARK: - Public Methods
    
    func setSearchButtonAction(target: Any?, action: Selector) {
        magnifyButton.addTarget(target, action: action, for: .touchUpInside)
    }
    
    func getSearchText() -> String? {
        return searchTextField.text
    }
    
}
