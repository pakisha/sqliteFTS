//
//  SQLiteFTSServices.swift
//  SQLiteFTSDemo
//
//  Created by Pavle Pesic on 9/30/19.
//  Copyright © 2019 Pavle Pesic. All rights reserved.
//

import Foundation

class SQLiteFTSServices {
    
    // MARK: - Vars & Lets
    
    private let sqliteManager: SQLiteManager
    
    // MARK: - Public methods
    
    func findProducts(searchString: String) -> [Product] {
        if searchString == "" {
            return self.findAllProducts()
        }
        
        var products = [Product]()
        
        var selectStatement: OpaquePointer? = nil
        let selectSql = "SELECT * FROM prductsFTS WHERE prductsFTS MATCH '\(searchString)*' LIMIT 50"
        
        if sqlite3_prepare_v2(self.sqliteManager.sqliteDB, selectSql, -1, &selectStatement, nil) == SQLITE_OK {
            while sqlite3_step(selectStatement) == SQLITE_ROW {
                products.append(Product(productID: String(cString: sqlite3_column_text(selectStatement, 0)), productDescription: String(cString: sqlite3_column_text(selectStatement, 1))))
            }
        }
        
        sqlite3_finalize(selectStatement)
        
        return products
    }
    
    func findAllProducts() -> [Product] {
        var products = [Product]()
        
        var selectStatement: OpaquePointer? = nil
        let selectSql = "select * from prductsFTS LIMIT 100"
        
        if sqlite3_prepare_v2(self.sqliteManager.sqliteDB, selectSql, -1, &selectStatement, nil) == SQLITE_OK {
            while sqlite3_step(selectStatement) == SQLITE_ROW {
                let productID = String(cString: sqlite3_column_text(selectStatement, 0))
                let productDescription = String(cString: sqlite3_column_text(selectStatement, 1))
                products.append(Product(productID: productID, productDescription: productDescription))
            }
        }
        
        sqlite3_finalize(selectStatement)
        
        return products
    }
    
    func bulkInsert(products: [[String: Any]]) {
        var insertStatement: OpaquePointer? = nil
        var statement = "BEGIN EXCLUSIVE TRANSACTION"
        
        if sqlite3_prepare_v2(self.sqliteManager.sqliteDB, statement, -1, &insertStatement, nil) != SQLITE_OK {
            print("db error: %s\n", sqlite3_errmsg(self.sqliteManager.sqliteDB) ?? "")
            return
        }
        
        if sqlite3_step(insertStatement) != SQLITE_DONE {
            sqlite3_finalize(insertStatement)
            print("db error: %s\n", sqlite3_errmsg(self.sqliteManager.sqliteDB) ?? "")
            return
        }
        
        statement = "insert into prductsFTS (productID, productDescription) values(?,?)";
        var compiledStatement: OpaquePointer? = nil
        
        if sqlite3_prepare_v2(self.sqliteManager.sqliteDB, statement, -1, &compiledStatement, nil) == SQLITE_OK {
            for productDict in products {
                let id = productDict["productID"] as! NSString
                let description = productDict["productDescription"] as! NSString
                
                sqlite3_bind_text(compiledStatement, 1, id.utf8String, -1, unsafeBitCast(-1, to: sqlite3_destructor_type.self))
                sqlite3_bind_text(compiledStatement, 2, description.utf8String, -1, unsafeBitCast(-1, to: sqlite3_destructor_type.self)) // Ovde pokusaj da stavis nil kao poslednji parametar ako ne radi
                
                while true {
                    let result = sqlite3_step(compiledStatement)
                    if result == SQLITE_DONE {
                        break
                    } else if result != SQLITE_BUSY {
                        print("db error: %s\n", sqlite3_errmsg(self.sqliteManager.sqliteDB) ?? "")
                        break
                    }
                }
                
                sqlite3_reset(compiledStatement);
            }
        }
        
        // COMMIT
        statement = "COMMIT TRANSACTION";
        var commitStatement: OpaquePointer? = nil
        
        if sqlite3_prepare_v2(self.sqliteManager.sqliteDB, statement, -1, &commitStatement, nil) != SQLITE_OK {
            print("db error: %s\n", sqlite3_errmsg(self.sqliteManager.sqliteDB) ?? "")
        }
        if sqlite3_step(commitStatement) != SQLITE_DONE {
            print("db error: %s\n", sqlite3_errmsg(self.sqliteManager.sqliteDB) ?? "")
        }
        
        sqlite3_finalize(compiledStatement);
        sqlite3_finalize(commitStatement);
    }
    
    // MARK: - Private methods
    
    private func createProductsFTSTable() {
        let errMSG: UnsafeMutablePointer<UnsafeMutablePointer<Int8>?>? = nil
        let sqlStatement = "CREATE VIRTUAL TABLE IF NOT EXISTS prductsFTS USING FTS4(productID, productDescription);"
        
        if sqlite3_exec(self.sqliteManager.sqliteDB, sqlStatement, nil, nil, errMSG) == SQLITE_OK {
            print("created table")
        } else {
            print("failed to create table")
        }
    }

    // MARK: - Initialization
    
    init(sqliteManager: SQLiteManager) {
        self.sqliteManager = sqliteManager
        self.createProductsFTSTable()
    }
    
}
