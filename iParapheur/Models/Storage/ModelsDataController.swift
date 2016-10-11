/*
 * Copyright 2012-2016, Adullact-Projet.
 *
 * contact@adullact-projet.coop
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

/**
 * Took from
 * https://developer.apple.com/library/content/documentation/Cocoa/Conceptual/CoreData/InitializingtheCoreDataStack.html#//apple_ref/doc/uid/TP40001075-CH4-SW1
 */
class ModelsDataController: NSObject {

    var managedObjectContext: NSManagedObjectContext

    override init() {

        // This resource is the same name as your xcdatamodeld contained in your project.
        guard let modelURL = NSBundle.mainBundle().URLForResource("Models", withExtension: "momd") else {
            fatalError("Error loading model from bundle")
        }

        // The managed object model for the application.
        // It is a fatal error for the application not to be able to find and load its model.
        guard let mom = NSManagedObjectModel(contentsOfURL: modelURL) else {
            fatalError("Error initializing mom from: \(modelURL)")
        }

        let psc = NSPersistentStoreCoordinator(managedObjectModel: mom)
        managedObjectContext = NSManagedObjectContext(concurrencyType: .MainQueueConcurrencyType)
        managedObjectContext.persistentStoreCoordinator = psc
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0)) {

            let urls = NSFileManager.defaultManager().URLsForDirectory(.DocumentDirectory, inDomains: .UserDomainMask)
            let docURL = urls[urls.endIndex - 1]

            // The directory the application uses to store the Core Data store file.
            // This code uses a file named "DataModel.sqlite" in the application's documents directory.
            let storeURL = docURL.URLByAppendingPathComponent("DataModel.sqlite")
            do {
                try psc.addPersistentStoreWithType(NSSQLiteStoreType, configuration: nil, URL: storeURL, options: nil)
            } catch {
                fatalError("Error migrating store: \(error)")
            }
        }
    }

    // Public methods

    func fetchAccounts() -> [Account] {

        var result: [Account] = []

        // Request

        do {
            let fetchRequest = NSFetchRequest(entityName: Account.EntityName)
            result = try managedObjectContext.executeFetchRequest(fetchRequest) as! [Account]
        } catch {
            print("Could not fetch Accounts")
            return result
        }

        // Default init

        if result.count == 0 {

            var demoAccount = NSEntityDescription.insertNewObjectForEntityForName(Account.EntityName, inManagedObjectContext:managedObjectContext) as! Account
            demoAccount.id = Account.DemoId
            demoAccount.title = Account.DemoTitle
            demoAccount.url = Account.DemoUrl
            demoAccount.login = Account.DemoLogin
            demoAccount.password = Account.DemoPassword
            demoAccount.isVisible = true
            demoAccount.isTested = true

            save()
        }

        //

        return result
    }

    func save() {
        do {
            try managedObjectContext.save()
        } catch let error as NSError  {
            print("Could not save \(error), \(error.userInfo)")
        }
    }

}
