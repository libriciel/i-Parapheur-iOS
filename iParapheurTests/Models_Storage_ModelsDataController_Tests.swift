/*
 * Copyright 2012-2019, Libriciel SCOP.
 *
 * contact@libriciel.coop
 *
 * This software is a computer program whose purpose is to manage and sign
 * digital documxents on an authorized iParapheur.
 *
 * This software is governed by the CeCILL license under French law and
 * abiding by the rules of distribution of free software.  You can  use,
 * modify and/ or redistribute the software under the terms of the CeCILL
 * license as circulated by CEA, CNRS and INRIA at the following URL
 * "http://www.cecill.info".
 *
 * As a counterpart to the access to the source code and  rights to copy,
 * modify and redistribute granted by the license, users are provided only
 * with a limited warranty  and the software's author,  the holder of the
 * economic rights,  and the successive licensors  have only  limited
 * liability.
 *
 * In this respect, the user's attention is drawn to the risks associated
 * with loading,  using,  modifying and/or developing or reproducing the
 * software by the user in light of its specific status of free software,
 * that may mean  that it is complicated to manipulate,  and  that  also
 * therefore means  that it is reserved for developers  and  experienced
 * professionals having in-depth computer knowledge. Users are therefore
 * encouraged to load and test the software's suitability as regards their
 * requirements in conditions enabling the security of their systems and/or
 * data to be ensured and,  more generally, to use and operate it in the
 * same conditions as regards security.
 *
 * The fact that you are presently reading this means that you have had
 * knowledge of the CeCILL license and that you accept its terms.
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

        _ = NSEntityDescription.insertNewObject(forEntityName: Certificate.ENTITY_NAME, into: managedObjectContext)

        XCTAssertEqual(ModelsDataController.fetchCertificates().count, 1)

        _ = NSEntityDescription.insertNewObject(forEntityName: Certificate.ENTITY_NAME, into: managedObjectContext)
        _ = NSEntityDescription.insertNewObject(forEntityName: Certificate.ENTITY_NAME, into: managedObjectContext)

        XCTAssertEqual(ModelsDataController.fetchCertificates().count, 3)
    }

    func testFetchAccounts() {
        let managedObjectContext = setUpInMemoryManagedObjectContext()
        ModelsDataController.context = managedObjectContext

        XCTAssertEqual(ModelsDataController.fetchAccounts().count, 0)

        _ = NSEntityDescription.insertNewObject(forEntityName: Account.ENTITY_NAME, into: managedObjectContext)

        XCTAssertEqual(ModelsDataController.fetchAccounts().count, 1)

        _ = NSEntityDescription.insertNewObject(forEntityName: Account.ENTITY_NAME, into: managedObjectContext)
        _ = NSEntityDescription.insertNewObject(forEntityName: Account.ENTITY_NAME, into: managedObjectContext)

        XCTAssertEqual(ModelsDataController.fetchAccounts().count, 3)
    }

    func testFetchFilters() {
        let managedObjectContext = setUpInMemoryManagedObjectContext()
        ModelsDataController.context = managedObjectContext

        XCTAssertEqual(ModelsDataController.fetchFilters().count, 0)

        _ = NSEntityDescription.insertNewObject(forEntityName: Filter.ENTITY_NAME, into: managedObjectContext)

        XCTAssertEqual(ModelsDataController.fetchFilters().count, 1)

        _ = NSEntityDescription.insertNewObject(forEntityName: Filter.ENTITY_NAME, into: managedObjectContext)
        _ = NSEntityDescription.insertNewObject(forEntityName: Filter.ENTITY_NAME, into: managedObjectContext)

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
        ModelsDataController.fetchAccounts()[0].id = Account.DEMO_ID

        // Adding legacy Account in previous storage position.

        userDefaults?.set("legacy_url", forKey: "settings_server_url")
        userDefaults?.set("legacy_login", forKey: "settings_login")
        userDefaults?.set("legacy_password", forKey: "settings_password")

        ModelsDataController.cleanupAccounts(preferences: userDefaults!)

        XCTAssertEqual(ModelsDataController.fetchAccounts().count, 2)
        ModelsDataController.fetchAccounts()[1].id = Account.LEGACY_ID
        ModelsDataController.fetchAccounts()[1].url = "legacy_url"
        ModelsDataController.fetchAccounts()[1].login = "legacy_login"
        ModelsDataController.fetchAccounts()[1].password = "legacy_password"
        XCTAssertNil(userDefaults?.string(forKey: "settings_server_url"))
        XCTAssertNil(userDefaults?.string(forKey: "settings_login"))
        XCTAssertNil(userDefaults?.string(forKey: "settings_password"))
    }

}


