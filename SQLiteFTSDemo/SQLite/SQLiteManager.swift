//
//  SQLiteManager.swift
//  SQLiteFTSDemo
//
//  Created by Pavle Pesic on 9/30/19.
//  Copyright © 2019 Pavle Pesic. All rights reserved.
//

import Foundation

class SQLiteManager {
    
    // MARK: - Vars & Lets
    
    var sqliteDB: OpaquePointer? = nil // C pointer
    private let fileManager: FileManager
    private var dbUrl: URL? = nil
    
    // MARK: - Initialization
    
    init(fileManager: FileManager) {
        self.fileManager = fileManager
        do {
            let baseUrl = try self.fileManager.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: false)
            print(baseUrl)
            self.dbUrl = baseUrl.appendingPathComponent("swift.sqlite")
        } catch {
            print(error)
        }
        
        if let dbUrl = self.dbUrl {
            let flags = SQLITE_OPEN_CREATE | SQLITE_OPEN_READWRITE | SQLITE_OPEN_FULLMUTEX
            let status = sqlite3_open_v2(dbUrl.absoluteString.cString(using: String.Encoding.utf8), &sqliteDB, flags, nil)
            
            if status == SQLITE_OK {
                print("Status OK")
            }
        }
    }

}
