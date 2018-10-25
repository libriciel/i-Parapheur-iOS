/*
 * Copyright 2012-2017, Libriciel SCOP.
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
import Foundation


@objc class SettingsAccountsController: UIViewController, UITableViewDataSource {

    @IBOutlet var addAccountUIButton: UIButton!
    @IBOutlet var accountTableView: UITableView!
    var accountList: [Account] = []

    // MARK: - Life cycle

    override func viewDidLoad() {
        super.viewDidLoad()
        print("View loaded : SettingsAccountsController")

        accountTableView.allowsSelection = false

        accountList = ModelsDataController.fetchAccounts()
        accountTableView.dataSource = self

        // Registering for popup notifications

        NotificationCenter.default.addObserver(self,
                                               selector: #selector(onAccountSaved),
                                               name: SettingsAccountsEditPopupController.NotifDocumentSaved,
                                               object: nil)

        // Buttons Listeners

        addAccountUIButton.addTarget(self,
                                     action: #selector(onAddAccountButtonClicked),
                                     for: .touchUpInside)
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {

        if (segue.identifier == SettingsAccountsEditPopupController.Segue) {
            let editViewController: SettingsAccountsEditPopupController = segue.destination as! SettingsAccountsEditPopupController

            let senderButton = sender as? UIButton
            if (senderButton !== addAccountUIButton) {
                let buttonPosition: CGPoint = senderButton!.convert(CGPoint.zero, to: accountTableView);
                let indexPath: NSIndexPath = accountTableView.indexPathForRow(at: buttonPosition)! as NSIndexPath;
                editViewController.currentAccount = accountList[indexPath.row]
            }
        }
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }


    // <editor-fold desc="TableView">

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return accountList.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {

        let cell: SettingsAccountsCell = tableView.dequeueReusableCell(withIdentifier: SettingsAccountsCell.CellIdentifier,
                                                                       for: indexPath as IndexPath) as! SettingsAccountsCell

        // Compute data

        let account: Account = accountList[indexPath.row]

        let titlePrint: String = (account.title!.count != 0) ? account.title! : "(Aucun titre)"
        let loginPrint: String = (account.login!.count != 0) ? account.login! : "(Aucun login)"
        let urlPrint: String = (account.url!.count != 0) ? account.url! : "(Aucune URL)"

        // UI set

        cell.titleLabel.text = titlePrint
        cell.infoLabel.text = "\(loginPrint) @ \(urlPrint)"

        cell.deleteButton.isHidden = (account.id! == Account.DEMO_ID)
        cell.deleteButton.addTarget(self,
                                    action: #selector(onDeleteButtonClicked),
                                    for: .touchUpInside)

        cell.editButton.isHidden = (account.id! == Account.DEMO_ID)
        cell.editButton.addTarget(self,
                                  action: #selector(onEditButtonClicked),
                                  for: .touchUpInside)

        cell.visibilityButton.isHidden = (account.id != Account.DEMO_ID)
        cell.visibilityButton.isSelected = (account.isVisible!.boolValue || (accountList.count == 1))

        let imageOff = UIImage(named: "ic_visibility_off_white_24dp")?.withRenderingMode(.alwaysTemplate)
        let imageOn = UIImage(named: "ic_visibility_white_24dp")?.withRenderingMode(.alwaysTemplate)

        cell.visibilityButton.setImage(imageOff, for: .normal)
        cell.visibilityButton.setImage(imageOn, for: .selected)
        cell.visibilityButton.tintColor = ColorUtils.Aqua

        cell.visibilityButton.addTarget(self,
                                        action: #selector(onVisibilityButtonClicked),
                                        for: .touchUpInside)

        return cell
    }

    // </editor-fold desc="TableView">


    // MARK: - Listeners

    @objc func onAccountSaved(notification: NSNotification) {

        let account: Account! = notification.object as! Account
        let accountIndex = accountList.index(of: account)

        if (accountIndex == nil) {

            // Add to UI

            accountList.append(account)
            let newIndexPath = IndexPath(row: accountList.count - 1, section: 0)
            accountTableView.beginUpdates()
            accountTableView.insertRows(at: [newIndexPath], with: UITableView.RowAnimation.fade)
            accountTableView.endUpdates()

        } else {

            // Refresh UI

            let accountIndexPath = IndexPath(row: accountIndex!, section: 0)
            accountTableView.beginUpdates()
            accountTableView.reloadRows(at: [accountIndexPath], with: UITableView.RowAnimation.none)
            accountTableView.endUpdates()
        }

        ModelsDataController.save()
    }

    @objc func onAddAccountButtonClicked(sender: UIBarButtonItem) {
        performSegue(withIdentifier: SettingsAccountsEditPopupController.Segue, sender: sender)
    }

    @objc func onDeleteButtonClicked(sender: UIButton) {

        let buttonPosition: CGPoint = sender.convert(CGPoint.zero, to: accountTableView);
        let indexPath: NSIndexPath = accountTableView.indexPathForRow(at: buttonPosition)! as NSIndexPath;
        let accountToDelete: Account = accountList[indexPath.row]

        // Delete from local DB

        ModelsDataController.context!.delete(accountToDelete)

        // Delete from UITableView

        accountList.remove(at: indexPath.row)
        accountTableView.deleteRows(at: [indexPath as IndexPath], with: .fade)

        // Refresh the demo Account, and forces it to visible, if it's the last one

        if (accountList.count == 1) {
            accountList[0].isVisible = true

            let demoIndexPath = IndexPath(row: 0, section: 0)
            accountTableView.beginUpdates()
            accountTableView.reloadRows(at: [demoIndexPath], with: UITableView.RowAnimation.none)
            accountTableView.endUpdates()
        }

        //

        ModelsDataController.save()
    }

    @objc func onEditButtonClicked(sender: UIButton) {
        performSegue(withIdentifier: SettingsAccountsEditPopupController.Segue, sender: sender)
    }

    @objc func onVisibilityButtonClicked(sender: UIButton) {

        let buttonPosition: CGPoint = sender.convert(CGPoint.zero, to: accountTableView);
        let indexPath: NSIndexPath = accountTableView.indexPathForRow(at: buttonPosition)! as NSIndexPath;

        // Keeping user from hiding the last Account

        if accountList.count == 1 {
            return
        }

        // Default behaviour

        sender.isSelected = !sender.isSelected
        accountList[indexPath.row].isVisible = sender.isSelected as NSNumber
        ModelsDataController.save()

        // TODO : bottom message, maybe ?
//        ViewUtils.logInfoMessage(sender.selected ? "Le compte de démo sera masqué dans la liste de sélection" : "Le compte de démo sera visible dans la liste de sélection",
//                                 title: nil,
//                                 viewController: self)
    }
}
