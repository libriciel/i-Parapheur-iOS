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
import Foundation

@objc class SettingsAccountsController: UIViewController, UITableViewDataSource {

    @IBOutlet var addAccountButton: UIBarButtonItem!
    @IBOutlet var accountTableView: UITableView!
    let dataController: ModelsDataController = ModelsDataController()
    var accountList: Array<Account> = []

    // MARK: - Life cycle

    override func viewDidLoad() {
        super.viewDidLoad()

        accountList = loadAccountList()
        accountTableView.dataSource = self
    }

    // MARK: - UITableViewDataSource

    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return accountList.count
    }

    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {

        let cell = tableView.dequeueReusableCellWithIdentifier("AccountCell", forIndexPath: indexPath)
        let account = accountList[indexPath.row]

        if let titleLabel = cell.viewWithTag(101) as? UILabel {

        }

        if let accountLabel = cell.viewWithTag(102) as? UILabel {

        }

        if let deleteButton = cell.viewWithTag(201) as? UIButton {
            deleteButton.addTarget(self,
                                   action: #selector(onDeleteButtonClicked),
                                   forControlEvents: .TouchUpInside)
        }

        if let testButton = cell.viewWithTag(202) as? UIButton {
            testButton.addTarget(self,
                                 action: #selector(onTestButtonClicked),
                                 forControlEvents: .TouchUpInside)
        }

        if let editButton = cell.viewWithTag(203) as? UIButton {
            editButton.addTarget(self,
                                 action: #selector(onEditButtonClicked),
                                 forControlEvents: .TouchUpInside)
        }

        return cell
    }

    // MARK: - Private methods

    func loadAccountList() -> Array<Account> {
        return dataController.fetchAccounts()
    }

    // MARK: - Listeners

    func onTestButtonClicked(sender: UIButton) {
        print("Test pressed")
    }

    func onDeleteButtonClicked(sender: UIButton) {
        print("Delete pressed")

        let buttonPosition: CGPoint = sender.convertPoint(CGPointZero, toView: accountTableView);
        let indexPath: NSIndexPath = accountTableView.indexPathForRowAtPoint(buttonPosition)!;

        // Find from NSManagedObjectContext

//        var privateKeyToDelete: NSManagedObject? = nil
//
//        let appDelegate: RGAppDelegate = (UIApplication.sharedApplication().delegate as! RGAppDelegate)
//        let keystore: ADLKeyStore = appDelegate.keyStore
//        for pkeyManagedObject: NSManagedObject in keystore.listPrivateKeys() as! [NSManagedObject] {
//            if (pkeyManagedObject.valueForKey("serialNumber") as? String == certificateList[indexPath.row].serialNumber) {
//                privateKeyToDelete = pkeyManagedObject
//            }
//        }
//
//        // Safety check
//
//        if (privateKeyToDelete == nil) {
//            return
//        }
//
//        // Delete from NSManagedObjectContext
//
//        let context: NSManagedObjectContext = appDelegate.managedObjectContext!
//        context.deleteObject(privateKeyToDelete!)
//        certificateList.removeAtIndex(indexPath.row)
//        try! context.save()
//
//        // Delete from UITableView
//
//        certificatesTableView.deleteRowsAtIndexPaths([indexPath],
//                                                     withRowAnimation: .Fade)
    }

    func onEditButtonClicked(sender: UIButton) {
        print("Edit pressed")
    }

}
