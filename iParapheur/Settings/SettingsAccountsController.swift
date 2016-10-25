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

@objc class SettingsAccountsController: UIViewController, UITableViewDataSource, SettingsAccountsEditPopupControllerDelegate {

    @IBOutlet var addAccountButton: UIBarButtonItem!
    @IBOutlet var accountTableView: UITableView!
    let dataController: ModelsDataController = ModelsDataController()
    var accountList: Array<Account> = []

    // MARK: - Life cycle

    override func viewDidLoad() {
        super.viewDidLoad()

        accountTableView.allowsSelection = false

        accountList = loadAccountList()
        accountTableView.dataSource = self

        addAccountButton.action = #selector(onAddAccountButtonClicked)
        addAccountButton.target = self
    }

    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject!) {

        if (segue.identifier == "EditAccountSegue") {

            let buttonPosition: CGPoint = sender.convertPoint(CGPointZero, toView: accountTableView);
            let indexPath: NSIndexPath = accountTableView.indexPathForRowAtPoint(buttonPosition)!;

            let editViewController: SettingsAccountsEditPopupController = segue.destinationViewController as! SettingsAccountsEditPopupController
            editViewController.currentAccount = accountList[indexPath.row]
            editViewController.delegate = self
        }
    }

    // MARK: - UITableViewDataSource

    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return accountList.count
    }

    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {

        let cell: SettingsAccountCell = tableView.dequeueReusableCellWithIdentifier(SettingsAccountCell.CellIdentifier,
                                                                                    forIndexPath: indexPath) as! SettingsAccountCell

        let account = accountList[indexPath.row]

        cell.titleLabel.text = account.title
        cell.infoLabel.text = "\(account.login!) @ \(account.url!)"

        cell.deleteButton.hidden = (account.id == Account.DemoId)
        cell.deleteButton.addTarget(self,
                                    action: #selector(onDeleteButtonClicked),
                                    forControlEvents: .TouchUpInside)

        cell.editButton.hidden = (account.id == Account.DemoId)
        cell.editButton.addTarget(self,
                                  action: #selector(onEditButtonClicked),
                                  forControlEvents: .TouchUpInside)

        cell.visibilityButton.hidden = (account.id != Account.DemoId)
        cell.visibilityButton.selected = (account.isVisible!.boolValue || (accountList.count == 1))

        let imageOff = UIImage(named: "ic_visibility_off_white_24dp")?.imageWithRenderingMode(.AlwaysTemplate)
        let imageOn = UIImage(named: "ic_visibility_white_24dp")?.imageWithRenderingMode(.AlwaysTemplate)

        cell.visibilityButton.setImage(imageOff, forState: .Normal)
        cell.visibilityButton.setImage(imageOn, forState: .Selected)
        cell.visibilityButton.tintColor = ColorUtils.Aqua

        cell.visibilityButton.addTarget(self,
                                        action: #selector(onVisibilityButtonClicked),
                                        forControlEvents: .TouchUpInside)

        return cell
    }

    // MARK: - Private methods

    func loadAccountList() -> Array<Account> {
        return ModelsDataController.fetchAccounts()
    }

    // MARK: - SettingsAccountsEditPopupControllerDelegate

    func onAccountSaved(account: Account) {

        let accountIndex = accountList.indexOf(account)
        if (accountIndex == nil) {
            return
        }

        let accountIndexPath = NSIndexPath(forRow: accountIndex!, inSection: 0)
        accountTableView.beginUpdates()
        accountTableView.reloadRowsAtIndexPaths([accountIndexPath], withRowAnimation: UITableViewRowAnimation.None)
        accountTableView.endUpdates()

        ModelsDataController.save()
    }

    // MARK: - Listeners

    func onAddAccountButtonClicked(sender: UIButton) {

        // TODO : Show popup

        let newAccount = NSEntityDescription.insertNewObjectForEntityForName(Account.EntityName,
                                                                             inManagedObjectContext:ModelsDataController.Context!) as! Account

        newAccount.id = NSUUID().UUIDString
        newAccount.title = "iParapheur admin"
        newAccount.url = "parapheur.test.adullact.org"
        newAccount.login = "admin"
        newAccount.password = "admin"
        newAccount.isVisible = true

        ModelsDataController.save()

        // Add to UI

        accountList.append(newAccount)
        let newIndexPath = NSIndexPath(forRow: accountList.count - 1, inSection: 0)
        accountTableView.beginUpdates()
        accountTableView.insertRowsAtIndexPaths([newIndexPath], withRowAnimation: UITableViewRowAnimation.Fade)
        accountTableView.endUpdates()
    }

    func onDeleteButtonClicked(sender: UIButton) {

        let buttonPosition: CGPoint = sender.convertPoint(CGPointZero, toView: accountTableView);
        let indexPath: NSIndexPath = accountTableView.indexPathForRowAtPoint(buttonPosition)!;
        let accountToDelete: Account = accountList[indexPath.row]

        // Delete from NSManagedObjectContext

        ModelsDataController.Context!.deleteObject(accountToDelete)

        // Delete from UITableView

        accountList.removeAtIndex(indexPath.row)
        accountTableView.deleteRowsAtIndexPaths([indexPath], withRowAnimation: .Fade)

        // Refresh the demo Account, and forces it to visible, if it's the last one

        if (accountList.count == 1) {
            accountList[0].isVisible = true

            let demoIndexPath = NSIndexPath(forRow: 0, inSection: 0)
            accountTableView.beginUpdates()
            accountTableView.reloadRowsAtIndexPaths([demoIndexPath], withRowAnimation: UITableViewRowAnimation.None)
            accountTableView.endUpdates()
        }

        //

        ModelsDataController.save()
    }

    func onEditButtonClicked(sender: UIButton) {
        performSegueWithIdentifier("EditAccountSegue", sender: sender)
    }

    func onVisibilityButtonClicked(sender: UIButton) {

        let buttonPosition: CGPoint = sender.convertPoint(CGPointZero, toView: accountTableView);
        let indexPath: NSIndexPath = accountTableView.indexPathForRowAtPoint(buttonPosition)!;

        // Keeping user from hiding the last Account

        if accountList.count == 1 {
            return
        }

        // Default behaviour

        sender.selected = !sender.selected
        accountList[indexPath.row].isVisible = sender.selected
        ModelsDataController.save()

        // TODO : bottom message, maybe ?
//        ViewUtils.logInfoMessage(sender.selected ? "Le compte de démo sera masqué dans la liste de sélection" : "Le compte de démo sera visible dans la liste de sélection",
//                                 title: nil,
//                                 viewController: self)
    }
}
