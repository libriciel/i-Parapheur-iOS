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

import UIKit
import CoreData
import Foundation
import os


class SettingsAccountsController: UIViewController, UITableViewDataSource {


    @IBOutlet var addAccountUIButton: UIButton!
    @IBOutlet var accountTableView: UITableView!
    var accountList: [Account] = []


    // <editor-fold desc="LifeCycle"> MARK: - LifeCycle


    override func viewDidLoad() {
        super.viewDidLoad()
        os_log("View loaded : SettingsAccountsController", type: .debug)

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
                let buttonPosition: CGPoint = senderButton!.convert(CGPoint.zero, to: accountTableView)
                let indexPath: NSIndexPath = accountTableView.indexPathForRow(at: buttonPosition)! as NSIndexPath
                editViewController.currentAccount = accountList[indexPath.row]
            }
        }
    }


    // </editor-fold desc="LifeCycle">


    // <editor-fold desc="TableView"> MARK: - TableView


    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return accountList.count
    }


    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {

        let account = accountList[indexPath.row]
        let cell = tableView.dequeueReusableCell(withIdentifier: SettingsAccountsCell.cellIdentifier,
                                                 for: indexPath as IndexPath) as! SettingsAccountsCell

        // Compute data

        let titlePrint: String = (account.title!.count != 0) ? account.title! : "(Aucun titre)"
        let loginPrint: String = (account.login!.count != 0) ? account.login! : "(Aucun login)"
        let urlPrint: String = (account.url!.count != 0) ? account.url! : "(Aucune URL)"

        // UI set

        cell.titleLabel.text = titlePrint
        cell.infoLabel.text = "\(loginPrint) @ \(urlPrint)"

        cell.deleteButton.isHidden = (account.id! == Account.demoId)
        cell.deleteButton.addTarget(self,
                                    action: #selector(onDeleteButtonClicked),
                                    for: .touchUpInside)

        cell.editButton.isHidden = (account.id! == Account.demoId)
        cell.editButton.addTarget(self,
                                  action: #selector(onEditButtonClicked),
                                  for: .touchUpInside)

        cell.visibilityButton.isHidden = (account.id != Account.demoId)
        cell.visibilityButton.isSelected = (account.isVisible!.boolValue || (accountList.count == 1))

        let imageOff = UIImage(named: "ic_visibility_off_white_24dp")?.withRenderingMode(.alwaysTemplate)
        let imageOn = UIImage(named: "ic_visibility_white_24dp")?.withRenderingMode(.alwaysTemplate)

        cell.visibilityButton.setImage(imageOff, for: .normal)
        cell.visibilityButton.setImage(imageOn, for: .selected)
        cell.visibilityButton.tintColor = ColorUtils.aqua

        cell.visibilityButton.addTarget(self,
                                        action: #selector(onVisibilityButtonClicked),
                                        for: .touchUpInside)

        return cell
    }


    // </editor-fold desc="TableView">


    // <editor-fold desc="Listeners"> MARK: - Listeners


    @objc func onAccountSaved(notification: NSNotification) {

        guard let account = notification.object as? Account else { return }
        guard let accountIndex = accountList.firstIndex(of: account) else {

            // Add to UI

            accountList.append(account)
            let newIndexPath = IndexPath(row: accountList.count - 1, section: 0)
            accountTableView.beginUpdates()
            accountTableView.insertRows(at: [newIndexPath], with: .fade)
            accountTableView.endUpdates()
            ModelsDataController.save()
            return
        }

        // Refresh UI

        let accountIndexPath = IndexPath(row: accountIndex, section: 0)
        accountTableView.beginUpdates()
        accountTableView.reloadRows(at: [accountIndexPath], with: .none)
        accountTableView.endUpdates()
        ModelsDataController.save()
    }


    @objc func onAddAccountButtonClicked(sender: UIBarButtonItem) {
        performSegue(withIdentifier: SettingsAccountsEditPopupController.Segue, sender: sender)
    }


    @objc func onDeleteButtonClicked(sender: UIButton) {

        let buttonPosition: CGPoint = sender.convert(CGPoint.zero, to: accountTableView)
        let indexPath: NSIndexPath = accountTableView.indexPathForRow(at: buttonPosition)! as NSIndexPath
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

        let buttonPosition: CGPoint = sender.convert(CGPoint.zero, to: accountTableView)
        let indexPath: NSIndexPath = accountTableView.indexPathForRow(at: buttonPosition)! as NSIndexPath

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


    // <editor-fold desc="Listeners">

}
