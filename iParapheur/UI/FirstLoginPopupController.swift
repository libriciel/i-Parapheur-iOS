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

@objc class FirstLoginPopupController: UIViewController {

	static let Segue: NSString! = "FirstLoginPopupSegue"
	static let NotifDismiss: NSString! = "FirstLoginPopupControllerNotifDismiss"
    static let PreferredWidth: CGFloat! = 550
    static let PreferredHeight: CGFloat! = 340

	@IBOutlet var saveButton: UIBarButtonItem!
	@IBOutlet var serverUrlTextField: UITextField!
	@IBOutlet var loginTextField: UITextField!
    @IBOutlet var passwordTextField: UITextField!
    @IBOutlet var spinnerView: UIActivityIndicatorView!
    @IBOutlet var errorLabel: UITextView!

    var restClient: RestClientApiV3?
    var currentAccount: Account?

    // MARK: - LifeCycle

    override func viewDidLoad() {
		super.viewDidLoad()
		print("View loaded : FirstLoginPopupController")

        self.preferredContentSize = CGSizeMake(FirstLoginPopupController.PreferredWidth,
                                               FirstLoginPopupController.PreferredHeight);

        // Change value events

        serverUrlTextField.addTarget(self,
                                     action: #selector(onTextFieldValueChanged),
                                     forControlEvents: UIControlEvents.EditingChanged)

        loginTextField.addTarget(self,
                                 action: #selector(onTextFieldValueChanged),
                                 forControlEvents: UIControlEvents.EditingChanged)

        passwordTextField.addTarget(self,
                                    action: #selector(onTextFieldValueChanged),
                                    forControlEvents: UIControlEvents.EditingChanged)

        // Load existing account (if any)

        let accountList: [Account] = ModelsDataController.fetchAccounts()
        for account in accountList {
            if (account.id == Account.FirstAccountId) {
                currentAccount = account
            }
        }

        if (currentAccount != nil) {
            serverUrlTextField.text = currentAccount!.url
            loginTextField.text = currentAccount!.login
            passwordTextField.text = currentAccount!.password
        }

        //
    }

    deinit {
        serverUrlTextField.removeTarget(self,
                                        action: #selector(onTextFieldValueChanged),
                                        forControlEvents: UIControlEvents.EditingChanged)

        loginTextField.removeTarget(self,
                                    action: #selector(onTextFieldValueChanged),
                                    forControlEvents: UIControlEvents.EditingChanged)

        passwordTextField.removeTarget(self,
                                       action: #selector(onTextFieldValueChanged),
                                       forControlEvents: UIControlEvents.EditingChanged)
    }

    // MARK: - Private methods

    func validateTextFields() -> Bool! {

        // Cleanup URL

        let properServerUrl: String = String(StringUtils.cleanupServerName(serverUrlTextField.text))
        serverUrlTextField.text = properServerUrl

        // Check fields

        let isServerTextFieldValid: Bool = (serverUrlTextField.text!.characters.count != 0);
        let isLoginTextFieldValid: Bool = (loginTextField.text!.characters.count != 0)
        let isPasswordTextFieldValid: Bool = (passwordTextField.text!.characters.count != 0);

        // Set orange background on text fields.
        // only on connection event, not on change value events

        setBorderOnTextField(serverUrlTextField,
                             alert:(!isServerTextFieldValid))

        setBorderOnTextField(loginTextField,
                             alert:(!isLoginTextFieldValid))

        setBorderOnTextField(passwordTextField,
                             alert:(!isPasswordTextFieldValid))

        //

        return (isServerTextFieldValid && isLoginTextFieldValid && isPasswordTextFieldValid);
    }

    func setBorderOnTextField(textField: UITextField, alert: Bool) {

        if (alert) {
            textField.layer.cornerRadius = 6.0;
            textField.layer.masksToBounds = true;
            textField.layer.borderWidth = 1.0;
            textField.layer.borderColor = ColorUtils.DarkOrange.CGColor
            textField.backgroundColor = ColorUtils.DarkOrange.colorWithAlphaComponent(0.1)
        }
        else {
            textField.layer.borderColor = UIColor.clearColor().CGColor
            textField.backgroundColor = UIColor.clearColor()
        }
    }

    func testConnection() {

        // Setup rest client

        if (restClient != nil) {
            restClient!.manager.operationQueue.cancelAllOperations()
        }

        restClient = RestClientApiV3(baseUrl: StringUtils.cleanupServerName(serverUrlTextField.text),
                                     login: loginTextField.text!,
                                     password: passwordTextField.text!)

        // Test request

        enableInterface(false)

        restClient!.getApiVersion({
            (level: NSNumber) in

            self.enableInterface(true)
            self.dismissWithSuccess(true)
        },
                                  onError: {
                                      (error: NSError) in

                                      self.enableInterface(true)

                                      // Warn with orange fields

                                      // TODO : find kCFURLErrorUserAuthenticationRequired swift constant
                                      print("Adrien - error code : \(error.code)")

                                      if (error.code == -1011) {
                                          self.setBorderOnTextField(self.loginTextField, alert: true)
                                          self.setBorderOnTextField(self.passwordTextField, alert: true)
                                      }
                                      else {
                                          self.setBorderOnTextField(self.serverUrlTextField, alert: true)
                                      }

                                      // Setup error message

                                      let localizedDescription: NSString = StringUtils.getErrorMessage(error)

                                      if (error.localizedDescription == localizedDescription) {
                                          self.errorLabel.text = "La connexion au serveur a échoué (code \(error.code)"
                                      }
                                      else {
                                          self.errorLabel.text = String(localizedDescription)
                                      }
                                  }
                )
    }

    func enableInterface(enabled: Bool) {

        loginTextField.enabled = enabled
        passwordTextField.enabled = enabled
        serverUrlTextField.enabled = enabled
        errorLabel.hidden = !enabled

        enabled ? spinnerView.stopAnimating() : spinnerView.startAnimating()
    }

    func dismissWithSuccess(success: Bool) {

        if (restClient != nil) {
            restClient!.manager.operationQueue.cancelAllOperations()
        }

        dismissViewControllerAnimated(true, completion: nil)

        let result: NSNumber = NSNumber(integer: (success ? 1 : 0))
        let userInfo: [NSObject: AnyObject] = ["success": result]
        NSNotificationCenter.defaultCenter().postNotificationName(String(FirstLoginPopupController.NotifDismiss),
                                                                  object: nil,
                                                                  userInfo: userInfo)
    }

    // MARK: - TextField listeners

    func onTextFieldValueChanged(sender: AnyObject) {

        errorLabel.text = ""
        setBorderOnTextField(sender as! UITextField, alert:false)
    }

    // MARK: - Buttons listeners

    @IBAction func onCancelButtonClicked(sender: AnyObject) {
        dismissWithSuccess(false)
    }

    @IBAction func onSaveButtonClicked(sender: AnyObject) {

        // Saving data

        if (currentAccount == nil) {
            currentAccount = NSEntityDescription.insertNewObjectForEntityForName(Account.EntityName,
                                                                                 inManagedObjectContext:ModelsDataController.Context!) as! Account

            currentAccount!.id = Account.FirstAccountId
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
}
