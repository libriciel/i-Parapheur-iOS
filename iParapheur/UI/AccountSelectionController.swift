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

import Foundation
import UIKit
import os

class AccountSelectionController: UIViewController, UITableViewDataSource, UITableViewDelegate {

    @objc static let NotifSelected = Notification.Name("AccountSelectionControllerAccountSelectionController")
    static let Segue = "AccountListSegue"

    @IBOutlet var backButton: UIBarButtonItem!
    @IBOutlet var accountTableView: UITableView!

    var accountList: Array<Account> = []
    var selectedAccountId: String?


    // <editor-fold desc="LifeCycle"> MARK: - LifeCycle


    override func viewDidLoad() {
        super.viewDidLoad()
        os_log("View loaded : AccountSelectionController", type: .debug)

        ModelsDataController.cleanupAccounts(preferences: UserDefaults.standard)

        accountList = loadAccountList()
        accountTableView.dataSource = self
        accountTableView.delegate = self

        backButton.target = self
        backButton.action = #selector(AccountSelectionController.onBackButtonClicked)

        let preferences: UserDefaults = UserDefaults.standard
        selectedAccountId = preferences.string(forKey: Account.preferenceKeySelectedAccount as String)
    }


    // </editor-fold desc="LifeCycle">


    // <editor-fold desc="Private methods"> MARK: - Private methods


    func loadAccountList() -> Array<Account> {

        var result: Array<Account> = ModelsDataController.fetchAccounts()
        result = result.filter {
            $0.isVisible!.boolValue
        }

        return result
    }


    // </editor-fold desc="Private methods">


    // <editor-fold desc="Button Listeners"> MARK: - Button Listeners


    @objc func onBackButtonClicked() {
        self.dismiss(animated: true, completion: nil)
    }


    // </editor-fold desc="Button Listeners">


    // <editor-fold desc="UITableViewDataSource & UITableViewDelegate"> MARK: - UITableViewDataSource & UITableViewDelegate


    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return accountList.count
    }


    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {

        let account = accountList[indexPath.row]
        let cell = tableView.dequeueReusableCell(withIdentifier: AccountSelectionCell.cellId,
                                                 for: indexPath) as! AccountSelectionCell

        cell.inboxIcon.image = cell.inboxIcon.image!.withRenderingMode(.alwaysTemplate)
        cell.nameLabel.text = account.title

        cell.checkIcon.image = cell.checkIcon.image!.withRenderingMode(.alwaysTemplate)
        cell.checkIcon.isHidden = (selectedAccountId != account.id)

        return cell
    }


    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {

        let accountSelected: Account = accountList[indexPath.row]
        let preferences: UserDefaults = UserDefaults.standard
        preferences.set(accountSelected.id, forKey: Account.preferenceKeySelectedAccount as String)

        NotificationCenter.default.post(name: AccountSelectionController.NotifSelected,
                                        object: nil,
                                        userInfo: ["success": true])
        onBackButtonClicked()
    }


    // </editor-fold desc="UITableViewDataSource & UITableViewDelegate">

}
