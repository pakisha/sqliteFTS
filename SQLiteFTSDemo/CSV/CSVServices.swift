//
//  CSVServices.swift
//  SQLiteFTSDemo
//
//  Created by Pavle Pesic on 9/30/19.
//  Copyright © 2019 Pavle Pesic. All rights reserved.
//

import Foundation
import SwiftCSV

class CSVServices {
    
    // MARK: - Vars & Lets
    
    private let ftsServices: SQLiteFTSServices
    
    // MARK: - Pulic methods
    
    func csvFromLocalFile(completion: @escaping () -> Void) {
        do {
            let url = Bundle.main.url(forResource: "sqlitemedium", withExtension:"csv")
            if let url = url {
                let csvFile: CSV? = try CSV(url: url)
                self.ftsServices.bulkInsert(products: csvFile!.namedRows)
                completion()
            }
        } catch let parseError as CSVParseError {
            print(parseError)
            completion()
        } catch let error {
            print(error)
            completion()
        }
    }
    
    // MARK: - Initialization
    
    init(ftsServices: SQLiteFTSServices) {
        self.ftsServices = ftsServices
    }
    
}


