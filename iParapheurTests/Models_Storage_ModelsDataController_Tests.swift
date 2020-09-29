/*
 * i-Parapheur iOS
 * Copyright (C) 2012-2020 Libriciel-SCOP
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU Affero General Public License as
 * published by the Free Software Foundation, either version 3 of the
 * License, or (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU Affero General Public License for more details.
 *
 * You should have received a copy of the GNU Affero General Public License
 * along with this program.  If not, see <https://www.gnu.org/licenses/>.
 */

import XCTest
import CoreData
@testable import iParapheur


class Models_Storage_ModelsDataController_Tests: XCTestCase {

    /**
        Mockup of the database context
        Taken from https://www.andrewcbancroft.com/2015/01/13/unit-testing-model-layer-core-data-swift/
     */
    func setUpInMemoryManagedObjectContext() -> NSManagedObjectContext {

        let managedObjectModel = NSManagedObjectModel.mergedModel(from: [Bundle.main])!
        let persistentStoreCoordinator = NSPersistentStoreCoordinator(managedObjectModel: managedObjectModel)

        do {
            try persistentStoreCoordinator.addPersistentStore(ofType: NSInMemoryStoreType,
                                                              configurationName: nil,
                                                              at: nil,
                                                              options: nil)
        } catch {
            print("Adding in-memory persistent store failed")
        }

        let managedObjectContext = NSManagedObjectContext(concurrencyType: .mainQueueConcurrencyType)
        managedObjectContext.persistentStoreCoordinator = persistentStoreCoordinator

        return managedObjectContext
    }

    func testFetchCertificates() {
        let managedObjectContext = setUpInMemoryManagedObjectContext()
        ModelsDataController.context = managedObjectContext

        XCTAssertEqual(ModelsDataController.fetchCertificates().count, 0)

        _ = NSEntityDescription.insertNewObject(forEntityName: Certificate.entityName, into: managedObjectContext)

        XCTAssertEqual(ModelsDataController.fetchCertificates().count, 1)

        _ = NSEntityDescription.insertNewObject(forEntityName: Certificate.entityName, into: managedObjectContext)
        _ = NSEntityDescription.insertNewObject(forEntityName: Certificate.entityName, into: managedObjectContext)

        XCTAssertEqual(ModelsDataController.fetchCertificates().count, 3)
    }

    func testFetchAccounts() {
        let managedObjectContext = setUpInMemoryManagedObjectContext()
        ModelsDataController.context = managedObjectContext

        XCTAssertEqual(ModelsDataController.fetchAccounts().count, 0)

        _ = NSEntityDescription.insertNewObject(forEntityName: Account.entityName, into: managedObjectContext)

        XCTAssertEqual(ModelsDataController.fetchAccounts().count, 1)

        _ = NSEntityDescription.insertNewObject(forEntityName: Account.entityName, into: managedObjectContext)
        _ = NSEntityDescription.insertNewObject(forEntityName: Account.entityName, into: managedObjectContext)

        XCTAssertEqual(ModelsDataController.fetchAccounts().count, 3)
    }

    func testFetchFilters() {
        let managedObjectContext = setUpInMemoryManagedObjectContext()
        ModelsDataController.context = managedObjectContext

        XCTAssertEqual(ModelsDataController.fetchFilters().count, 0)

        _ = NSEntityDescription.insertNewObject(forEntityName: Filter.entityName, into: managedObjectContext)

        XCTAssertEqual(ModelsDataController.fetchFilters().count, 1)

        _ = NSEntityDescription.insertNewObject(forEntityName: Filter.entityName, into: managedObjectContext)
        _ = NSEntityDescription.insertNewObject(forEntityName: Filter.entityName, into: managedObjectContext)

        XCTAssertEqual(ModelsDataController.fetchFilters().count, 3)
    }

    func testCleanupAccounts() {

        // Mockup DataCore and UserDefaults

        let managedObjectContext = setUpInMemoryManagedObjectContext()
        ModelsDataController.context = managedObjectContext

        let userDefaultsSuiteName = "TestDefaults"
        UserDefaults().removePersistentDomain(forName: userDefaultsSuiteName)
        let userDefaults = UserDefaults(suiteName: userDefaultsSuiteName)

        // Testing empty case

        XCTAssertEqual(ModelsDataController.fetchAccounts().count, 0)

        ModelsDataController.cleanupAccounts(preferences: userDefaults!)

        XCTAssertEqual(ModelsDataController.fetchAccounts().count, 1)
        ModelsDataController.fetchAccounts()[0].id = Account.demoId

        // Adding legacy Account in previous storage position.

        userDefaults?.set("legacy_url", forKey: "settings_server_url")
        userDefaults?.set("legacy_login", forKey: "settings_login")
        userDefaults?.set("legacy_password", forKey: "settings_password")

        ModelsDataController.cleanupAccounts(preferences: userDefaults!)

        XCTAssertEqual(ModelsDataController.fetchAccounts().count, 2)
        ModelsDataController.fetchAccounts()[1].id = Account.legacyId
        ModelsDataController.fetchAccounts()[1].url = "legacy_url"
        ModelsDataController.fetchAccounts()[1].login = "legacy_login"
        ModelsDataController.fetchAccounts()[1].password = "legacy_password"
        XCTAssertNil(userDefaults?.string(forKey: "settings_server_url"))
        XCTAssertNil(userDefaults?.string(forKey: "settings_login"))
        XCTAssertNil(userDefaults?.string(forKey: "settings_password"))
    }

}


