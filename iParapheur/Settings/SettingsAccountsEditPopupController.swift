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


@objc class SettingsAccountsEditPopupController: UIViewController {


    static let NotifDocumentSaved = Notification.Name("SettingsAccountsEditPopupControllerNotifDocumentSaved")
    static let Segue: String! = "EditAccountSegue"
    static let PreferredWidth: CGFloat = 500
    static let PreferredHeight: CGFloat = 252

    @IBOutlet var cancelButton: UIButton!
    @IBOutlet var testButton: UIButton!
    @IBOutlet var saveButton: UIButton!

    @IBOutlet var titleTextView: UITextField!
    @IBOutlet var urlTextView: UITextField!
    @IBOutlet var loginTextView: UITextField!
    @IBOutlet var passwordTextView: UITextField!

    var currentAccount: Account?
    var currentRestClient: RestClient?


    // MARK: - Life cycle

    override func viewDidLoad() {
        super.viewDidLoad()
        os_log("View loaded : SettingsAccountsEditPopupController", type: .debug)

        self.preferredContentSize = CGSize(width: SettingsAccountsEditPopupController.PreferredWidth,
                                           height: SettingsAccountsEditPopupController.PreferredHeight)

        // Values

        if (currentAccount != nil) {
            titleTextView.text = currentAccount!.title
            urlTextView.text = currentAccount!.url
            loginTextView.text = currentAccount!.login
            passwordTextView.text = currentAccount!.password
        }

        // Listeners

        cancelButton.addTarget(self,
                               action: #selector(onCancelButtonClicked),
                               for: .touchUpInside)

        testButton.addTarget(self,
                             action: #selector(onTestButtonClicked),
                             for: .touchUpInside)

        saveButton.addTarget(self,
                             action: #selector(onSaveButtonClicked),
                             for: .touchUpInside)
    }

    // MARK: - Listeners

    @objc func onCancelButtonClicked(sender: UIButton) {
        dismiss(animated: true, completion: nil)
    }

    @objc func onTestButtonClicked(sender: UIButton) {

        // Cleanup

        urlTextView.text = StringsUtils.cleanupServerName(url: urlTextView.text!)

        //

        if (currentRestClient != nil) {
            currentRestClient!.cancelAllOperations()
        }

        currentRestClient = RestClient(baseUrl: NSString(string: urlTextView.text!),
                                       login: NSString(string: loginTextView.text!),
                                       password: NSString(string: passwordTextView.text!))

        currentRestClient!.getApiVersion(onResponse:
                                         { (result: NSNumber) in
                                             ViewUtils.logSuccess(message: "Connexion réussie",
                                                                  title: nil)
                                         },
                                         onError: { (error: Error) in
                                             ViewUtils.logError(message: StringsUtils.getMessage(error: error as NSError),
                                                                title: nil)
                                         })
    }

    @objc func onSaveButtonClicked(sender: UIButton) {

        // Cleanup

        urlTextView.text = StringsUtils.cleanupServerName(url: urlTextView.text!)

        // Update model

        if (currentAccount == nil) {
            currentAccount = NSEntityDescription.insertNewObject(forEntityName: Account.entityName,
                                                                 into: ModelsDataController.context!) as? Account

            currentAccount!.id = NSUUID().uuidString
            currentAccount!.isVisible = true
        }

        currentAccount!.title = titleTextView.text
        currentAccount!.url = urlTextView.text
        currentAccount!.login = loginTextView.text
        currentAccount!.password = passwordTextView.text

        // Callback and dismiss

        NotificationCenter.default.post(name: SettingsAccountsEditPopupController.NotifDocumentSaved,
                                        object: currentAccount!)

        dismiss(animated: true, completion: nil)
    }

}
