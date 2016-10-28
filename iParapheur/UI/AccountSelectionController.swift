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

import Foundation
import UIKit

@objc class AccountSelectionController: UIViewController, UITableViewDataSource, UITableViewDelegate {

	@IBOutlet var backButton: UIBarButtonItem!
	@IBOutlet var accountTableView: UITableView!

    var accountList: Array<Account> = []
    var selectedAccountId: String?

	// MARK: - LifeCycle

	override func viewDidLoad() {
		super.viewDidLoad()
		print("View loaded : AccountSelectionController")

        ModelsDataController.cleanupAccounts()

        accountList = loadAccountList()
        accountTableView.dataSource = self
        accountTableView.delegate = self

		backButton.target = self
		backButton.action = #selector(AccountSelectionController.onBackButtonClicked)

        let preferences: NSUserDefaults = NSUserDefaults.standardUserDefaults()
        selectedAccountId = preferences.stringForKey(Account.PreferencesKeySelectedAccount as String)
	}

    // MARK: - Private methods

    func loadAccountList() -> Array<Account> {

        var result: Array<Account> = ModelsDataController.fetchAccounts()
        result = result.filter{ $0.isVisible!.boolValue }

        return result
    }

    // MARK: - Button Listeners

    func onBackButtonClicked() {
        self.dismissViewControllerAnimated(true, completion: nil)
    }

    // MARK: - UITableViewDataSource & UITableViewDelegate

    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return accountList.count
    }

    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {

        let cell = tableView.dequeueReusableCellWithIdentifier("AccountCell", forIndexPath: indexPath)
        let account = accountList[indexPath.row]

        if let titleLabel = cell.viewWithTag(101) as? UILabel {
            titleLabel.text = account.title
        }

        if let inboxIcon = cell.viewWithTag(201) as? UIImageView {
            inboxIcon.image = inboxIcon.image!.imageWithRenderingMode(.AlwaysTemplate)
        }

        if let checkIcon = cell.viewWithTag(202) as? UIImageView {
            checkIcon.image = checkIcon.image!.imageWithRenderingMode(.AlwaysTemplate)
            checkIcon.hidden = (selectedAccountId != account.id)
        }

        return cell
    }

    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {

        let accountSelected: Account = accountList[indexPath.row]
        let preferences: NSUserDefaults = NSUserDefaults.standardUserDefaults()
        preferences.setObject(accountSelected.id, forKey: Account.PreferencesKeySelectedAccount as String)

        NSNotificationCenter.defaultCenter().postNotificationName("loginPopupDismiss",
                                                                  object: nil,
                                                                  userInfo: ["success": true])
        onBackButtonClicked()
    }

}