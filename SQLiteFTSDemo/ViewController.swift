//
//  ViewController.swift
//  SQLiteFTSDemo
//
//  Created by Pavle Pesic on 9/28/19.
//  Copyright © 2019 Pavle Pesic. All rights reserved.
//

import UIKit

class ViewController: UIViewController {

    // MARK: - Outelts
        
    @IBOutlet weak var tableVIew: UITableView!
        
    let searchController = UISearchController(searchResultsController: nil)
        
    // MARK: - Vars & Lets
        
    let sqlLiteManager = SQLiteManager(fileManager: FileManager.default)
    lazy var sqlliteFTSServices = SQLiteFTSServices(sqliteManager: sqlLiteManager)
    lazy var networkServices = CSVServices(ftsServices: self.sqlliteFTSServices)
        
    private var products: [Product] = []
    private var isInTheMiddelOfTheSearch = false
    private var lastSearch = ""
        
    // MARK: - Controller lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        self.setupTableView()
        self.setupSearch()
        self.products = self.sqlliteFTSServices.findAllProducts()
        if self.products.count == 0 {
            self.networkServices.csvFromLocalFile {
                self.products = self.sqlliteFTSServices.findAllProducts()
                self.tableVIew.reloadData()
            }
        }
    }
        
    // MARK: - Private methods
        
    private func setupTableView() {
        self.tableVIew.dataSource = self
    }
        
    private func setupSearch() {
        self.searchController.searchResultsUpdater = self
        self.searchController.obscuresBackgroundDuringPresentation = false
        self.searchController.searchBar.placeholder = "Search Products"
        navigationItem.searchController = self.searchController
        definesPresentationContext = true
    }
        
    private func searchProducts(text: String) {

        self.isInTheMiddelOfTheSearch = true
            
        DispatchQueue.global(qos: .userInitiated).async {
            self.products = self.sqlliteFTSServices.findProducts(searchString: text)
                
            DispatchQueue.main.async {
                self.tableVIew.reloadData()
                let text = self.searchController.searchBar.text!
                if text != self.lastSearch {
                    self.lastSearch = text
                    self.searchProducts(text: text)
                } else {
                    self.isInTheMiddelOfTheSearch = false
                }
            }
        }
    }

}

// MARK: - UITableViewDataSource

extension ViewController: UITableViewDataSource {
    
    public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.products.count
    }
    
    public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "SQLIteCell", for: indexPath)
        let product = self.products[indexPath.row]
        cell.textLabel?.text = product.productID
        cell.detailTextLabel?.text = product.productDescription
        return cell
    }
    
}

// MARK: - UISearchResultsUpdating

extension ViewController: UISearchResultsUpdating {
    
    public func updateSearchResults(for searchController: UISearchController) {
        if !self.isInTheMiddelOfTheSearch && searchController.searchBar.text! != self.lastSearch {
            let text = searchController.searchBar.text!
            self.searchProducts(text: text)
            self.lastSearch = text
        }
    }
    
}
