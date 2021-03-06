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
