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
import os


class FirstLoginPopupController: UIViewController {


    static let Segue = "FirstLoginPopupSegue"
    @objc static let NotifDismiss = Notification.Name("FirstLoginPopupControllerNotifDismiss")
    static let PreferredWidth: CGFloat! = 550
    static let PreferredHeight: CGFloat! = 340


    @IBOutlet var saveButton: UIBarButtonItem!
    @IBOutlet var serverUrlTextField: UITextField!
    @IBOutlet var loginTextField: UITextField!
    @IBOutlet var passwordTextField: UITextField!
    @IBOutlet var spinnerView: UIActivityIndicatorView!


    var restClient: RestClient?
    var currentAccount: Account?


    // <editor-fold desc="LifeCycle"> MARK: - LifeCycle


    override func viewDidLoad() {
        super.viewDidLoad()
        os_log("View loaded : FirstLoginPopupController", type: .debug)

        self.preferredContentSize = CGSize(width: FirstLoginPopupController.PreferredWidth,
                                           height: FirstLoginPopupController.PreferredHeight);

        // Change value events

        serverUrlTextField.addTarget(self,
                                     action: #selector(onTextFieldValueChanged),
                                     for: UIControl.Event.editingChanged)

        loginTextField.addTarget(self,
                                 action: #selector(onTextFieldValueChanged),
                                 for: UIControl.Event.editingChanged)

        passwordTextField.addTarget(self,
                                    action: #selector(onTextFieldValueChanged),
                                    for: UIControl.Event.editingChanged)

        // Load existing account (if any)

        let accountList: [Account] = ModelsDataController.fetchAccounts()
        for account in accountList {
            if (account.id == Account.legacyId) {
                currentAccount = account
            }
        }

        if (currentAccount != nil) {
            serverUrlTextField.text = currentAccount!.url
            loginTextField.text = currentAccount!.login
            passwordTextField.text = currentAccount!.password
        }
    }


    deinit {
        serverUrlTextField.removeTarget(self,
                                        action: #selector(onTextFieldValueChanged),
                                        for: UIControl.Event.editingChanged)

        loginTextField.removeTarget(self,
                                    action: #selector(onTextFieldValueChanged),
                                    for: UIControl.Event.editingChanged)

        passwordTextField.removeTarget(self,
                                       action: #selector(onTextFieldValueChanged),
                                       for: UIControl.Event.editingChanged)
    }


    // </editor-fold desc="LifeCycle">


    func validateTextFields() -> Bool! {

        // Cleanup URL

        let properServerUrl = StringsUtils.cleanupServerName(url: serverUrlTextField.text!)
        serverUrlTextField.text = properServerUrl

        // Check fields

        let isServerTextFieldValid: Bool = (serverUrlTextField.text!.count != 0);
        let isLoginTextFieldValid: Bool = (loginTextField.text!.count != 0)
        let isPasswordTextFieldValid: Bool = (passwordTextField.text!.count != 0);

        // Set orange background on text fields.
        // only on connection event, not on change value events

        setBorderOnTextField(textField: serverUrlTextField,
                             alert: (!isServerTextFieldValid))

        setBorderOnTextField(textField: loginTextField,
                             alert: (!isLoginTextFieldValid))

        setBorderOnTextField(textField: passwordTextField,
                             alert: (!isPasswordTextFieldValid))

        //

        return (isServerTextFieldValid && isLoginTextFieldValid && isPasswordTextFieldValid);
    }


    func setBorderOnTextField(textField: UITextField, alert: Bool) {

        if (alert) {
            textField.layer.cornerRadius = 6.0;
            textField.layer.masksToBounds = true;
            textField.layer.borderWidth = 1.0;
            textField.layer.borderColor = ColorUtils.darkOrange.cgColor
            textField.backgroundColor = ColorUtils.darkOrange.withAlphaComponent(0.1)
        }
        else {
            textField.layer.borderColor = UIColor.clear.cgColor
            textField.backgroundColor = UIColor.clear
        }
    }


    func testConnection() {

        // Setup rest client

        if (restClient != nil) {
            restClient!.cancelAllOperations()
        }

        restClient = RestClient(baseUrl: StringsUtils.cleanupServerName(url: serverUrlTextField.text!) as NSString,
                                login: loginTextField.text! as NSString,
                                password: passwordTextField.text! as NSString)

        // Test request

        enableInterface(isEnabled: false)

        restClient!.getApiVersion(onResponse: {
            (level: NSNumber) in

            // Register new account as selected

            let preferences: UserDefaults = UserDefaults.standard
            preferences.set(self.currentAccount!.id, forKey: Account.preferenceKeySelectedAccount as String)

            // UI refresh

            self.enableInterface(isEnabled: true)
            self.dismissWithSuccess(success: true)
        },
                                  onError: {
                                      (error: NSError) in

                                      self.enableInterface(isEnabled: true)

                                      // Warn with orange fields

                                      // TODO : find kCFURLErrorUserAuthenticationRequired swift constant

                                      if (error.code == -1011) {
                                          self.setBorderOnTextField(textField: self.loginTextField, alert: true)
                                          self.setBorderOnTextField(textField: self.passwordTextField, alert: true)
                                      }
                                      else {
                                          self.setBorderOnTextField(textField: self.serverUrlTextField, alert: true)
                                      }

                                      // Setup error message

                                      let localizedDescription = StringsUtils.getMessage(error: error)
                                      ViewUtils.logError(message: localizedDescription, title: "La connexion au serveur a échoué")
                                  }
        )
    }


    func enableInterface(isEnabled: Bool) {

        loginTextField.isEnabled = isEnabled
        passwordTextField.isEnabled = isEnabled
        serverUrlTextField.isEnabled = isEnabled

        isEnabled ? spinnerView.stopAnimating() : spinnerView.startAnimating()
    }


    func dismissWithSuccess(success: Bool) {

        if (restClient != nil) {
            restClient!.cancelAllOperations()
        }

        dismiss(animated: true, completion: nil)

        let result: NSNumber = NSNumber(value: (success ? 1 : 0))
        let userInfo: [NSObject: AnyObject] = ["success" as NSObject: result]
        NotificationCenter.default.post(name: FirstLoginPopupController.NotifDismiss,
                                        object: nil,
                                        userInfo: userInfo)
    }


    // <editor-fold desc="TextField listeners"> MARK: - TextField listeners


    @objc func onTextFieldValueChanged(sender: AnyObject) {
        setBorderOnTextField(textField: sender as! UITextField, alert: false)
    }


    // </editor-fold desc="TextField listeners">


    // <editor-fold desc="Buttons listeners"> MARK: - Buttons listeners


    @IBAction func onCancelButtonClicked(_ sender: Any) {
        dismissWithSuccess(success: false)
    }


    @IBAction func onSaveButtonClicked(_ sender: Any) {

        // Saving data

        if (currentAccount == nil) {
            currentAccount = NSEntityDescription.insertNewObject(forEntityName: Account.entityName,
                                                                 into: ModelsDataController.context!) as? Account

            currentAccount!.id = Account.legacyId
            currentAccount!.isVisible = true
        }

        currentAccount!.title = loginTextField.text
        currentAccount!.url = serverUrlTextField.text
        currentAccount!.login = loginTextField.text
        currentAccount!.password = passwordTextField.text

        ModelsDataController.save()

        //

        if (validateTextFields() == true) {
            testConnection()
        }
    }


    // </editor-fold desc="Buttons listeners"> MARK: - Buttons listeners

}
