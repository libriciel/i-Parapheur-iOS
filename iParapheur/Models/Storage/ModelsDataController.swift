/*
 * Copyright 2012-2019, Libriciel SCOP.
 *
 * contact@libriciel.coop
 *
 * This software is a computer program whose purpose is to manage and sign
 * digital documents on an authorized iParapheur.
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

import UIKit
import CoreData
import os

/**
    Taken from
    https://developer.apple.com/library/content/documentation/Cocoa/Conceptual/CoreData/
        -> InitializingtheCoreDataStack.html#//apple_ref/doc/uid/TP40001075-CH4-SW1
*/
class ModelsDataController: NSObject {


    @objc static let notificationModelsDataControllerLoaded = Notification.Name("ModelsDataController_loaded")
    @objc static var context: NSManagedObjectContext? = nil


    // <editor-fold desc="Utils">


    @objc static func loadManagedObjectContext() {

        // Default case

        if (ModelsDataController.context != nil) {
            return
        }

        // This resource is the same name as your xcdatamodeld contained in your project.
        guard let modelURL = Bundle.main.url(forResource: "Models", withExtension: "momd") else {
            fatalError("Error loading model from bundle")
        }

        // The managed object model for the application.
        // It is a fatal error for the application not to be able to find and load its model.
        guard let mom = NSManagedObjectModel(contentsOf: modelURL) else {
            fatalError("Error initializing mom from: \(modelURL)")
        }

        let psc = NSPersistentStoreCoordinator(managedObjectModel: mom)
        ModelsDataController.context = NSManagedObjectContext(concurrencyType: .mainQueueConcurrencyType)
        ModelsDataController.context!.persistentStoreCoordinator = psc

        DispatchQueue.global(qos: .background).async {
            DispatchQueue.main.async {

                let docURL = try! FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: false)

                // The directory the application uses to store the Core Data store file.
                // This code uses a file named "DataModel.sqlite" in the application's documents directory.
                let storeURL = docURL.appendingPathComponent("DataModel.sqlite")
                let options = [NSInferMappingModelAutomaticallyOption: true,
                               NSMigratePersistentStoresAutomaticallyOption: true]

                do {
                    try psc.addPersistentStore(ofType: NSSQLiteStoreType, configurationName: nil, at: storeURL, options: options)
                } catch {
                    fatalError("Error migrating store: \(error)")
                }

                // Patches
                cleanupCertificates()

                // Callback on UI thread
                DispatchQueue.global(qos: .default).async {
                    DispatchQueue.main.async {
                        NotificationCenter.default.post(name: ModelsDataController.notificationModelsDataControllerLoaded,
                                                        object: ["success": true])
                    }
                }
            }
        }
    }


    @objc static func save() {
        do {
            try ModelsDataController.context!.save()
        } catch let error as NSError {
            os_log("Could not save %@, %@", type: .error, error, error.userInfo)
        }
    }


    // </editor-fold desc="Utils">


    @objc static func fetchAccounts() -> [Account] {
        var result: [Account] = []

        do {
            let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: Account.entityName)
            result = try ModelsDataController.context!.fetch(fetchRequest) as! [Account]
        } catch {
            os_log("Could not fetch Accounts", type: .error)
            return result
        }

        return result
    }


    @objc static func fetchCertificates() -> [Certificate] {
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: Certificate.entityName)

        guard let result = try? ModelsDataController.context!.fetch(fetchRequest) as? [Certificate] else {
            os_log("Could not fetch Certificate", type: .error)
            return []
        }

        return result
    }


    static func fetchFilters() -> [Filter] {
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: Filter.entityName)

        guard let result = try? ModelsDataController.context!.fetch(fetchRequest) as? [Filter] else {
            os_log("Could not fetch Filters", type: .error)
            return []
        }

        return result
    }


    @objc static func cleanupAccounts(preferences: UserDefaults) {

        var isSaveNeeded = false

        // Setup demo account

        let result: [Account] = fetchAccounts()
        if result.count == 0 {

            let demoAccount = NSEntityDescription.insertNewObject(forEntityName: Account.entityName,
                                                                  into: ModelsDataController.context!) as! Account
            demoAccount.id = Account.demoId as String
            demoAccount.title = Account.demoTitle
            demoAccount.url = Account.demoUrl
            demoAccount.login = Account.demoLogin
            demoAccount.password = Account.demoPass
            demoAccount.isVisible = true

            isSaveNeeded = true
        }

        // Backup legacy settings

        if preferences.string(forKey: "settings_login") != nil {
            let legacyAccount = NSEntityDescription.insertNewObject(forEntityName: Account.entityName,
                                                                    into: ModelsDataController.context!) as! Account
            legacyAccount.id = Account.legacyId
            legacyAccount.title = preferences.string(forKey: "settings_login")
            legacyAccount.url = preferences.string(forKey: "settings_server_url")
            legacyAccount.login = preferences.string(forKey: "settings_login")
            legacyAccount.password = preferences.string(forKey: "settings_password")
            legacyAccount.isVisible = true

            preferences.set(legacyAccount.id, forKey: Account.preferenceKeySelectedAccount as String)
            preferences.removeObject(forKey: "settings_login")
            preferences.removeObject(forKey: "settings_password")
            preferences.removeObject(forKey: "settings_server_url")

            isSaveNeeded = true
        }

        // Saving twice in a row is a buggy
        // We have to use a boolean

        if isSaveNeeded {
            save()
        }
    }

    /**
        Merging old xcdatamodel into the new Model one.
        The old one is still based on the appDelegate objc way,
        the new one is on the iOS9-static swift way.

        FIXME : Delete this method in 2020, and the old KeyStore data model too.
        Everybody would have been patched then.
    */
    static func cleanupCertificates() {

        let appDelegate: RGAppDelegate = UIApplication.shared.delegate as! RGAppDelegate
        let oldKeystore: ADLKeyStore = appDelegate.keyStore
        for oldPrivateKey in oldKeystore.listPrivateKeys() as! [NSManagedObject] {

            let newCertificate = NSEntityDescription.insertNewObject(forEntityName: Certificate.entityName,
                                                                     into: context!) as! Certificate

            print("Legacy PrivateKey found = \(String(describing: oldPrivateKey.value(forKey: "caName")))")
            newCertificate.identifier = UUID().uuidString
            newCertificate.caName = oldPrivateKey.value(forKey: "caName") as? String
            newCertificate.commonName = oldPrivateKey.value(forKey: "commonName") as? String
            newCertificate.notAfter = oldPrivateKey.value(forKey: "notAfter") as? NSDate

            var payload: [String: String] = [:]
            payload[Certificate.payloadP12FileName] = oldPrivateKey.value(forKey: "p12Filename") as? String
            let jsonEncoder = JSONEncoder()
            let payloadData = try? jsonEncoder.encode(payload)

            newCertificate.payload = payloadData! as NSData
            newCertificate.publicKey = oldPrivateKey.value(forKey: "publicKey") as? NSData
            newCertificate.serialNumber = oldPrivateKey.value(forKey: "serialNumber") as? String
            newCertificate.sourceType = .p12File
            save()

            let oldContext: NSManagedObjectContext = appDelegate.managedObjectContext!
            oldContext.delete(oldPrivateKey)
            try! oldContext.save()
        }
    }

}
