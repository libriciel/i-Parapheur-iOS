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
import os


class WorkflowDialogController: UIViewController, UITableViewDataSource, UITableViewDelegate, UIAlertViewDelegate {


    @objc static let segue = "WorkflowDialogController"
    @objc static let notificationActionComplete = Notification.Name("DossierActionComplete")

    static let alertViewTagP12Pass = 1
    static let alertViewTagPaperSignature = 2

    @IBOutlet var certificateLayout: UIStackView!
    @IBOutlet var certificateTableView: UITableView!
    @IBOutlet var privateAnnotationTextView: UITextView!
    @IBOutlet var publicAnnotationTextView: UITextView!
    @IBOutlet var paperSignatureButton: UIButton!

    var restClient: RestClient?
    var currentAction: Action?
    var currentDeskId: String?
    var actionsToPerform: [ActionToPerform] = []
    var certificateList: [Certificate] = []
    var selectedCertificate: Certificate?
    var currentPassword: String?


    // <editor-fold desc="LifeCycle">


    override func viewDidLoad() {
        super.viewDidLoad()
        os_log("View loaded : WorkflowDialogController", type: .info)

        let hasSignature = actionsToPerform.contains(where: { ($0.action == .sign) && !($0.folder.isSignPapier) })
        certificateLayout.isHidden = !hasSignature

        NotificationCenter.default.addObserver(self,
                                               selector: #selector(onSignatureResult),
                                               name: .signatureResult,
                                               object: nil)

        for signatureToPerform in actionsToPerform.filter({ $0.action == .sign }) {

            // If we come from a multi-selection list, the folder is not properly set
            // It misses the document list. That's what we fetch here.

            os_log("getFolder...", type: .debug)
            if signatureToPerform.folder.documents.count == 0 {

                restClient?.getFolder(folder: signatureToPerform.folder.identifier,
                                      desk: currentDeskId ?? "",
                                      onResponse: { folder in
                                          os_log("getFolder response:%@", type: .info, folder)
                                          signatureToPerform.folder.documents = folder.documents
                                          self.checkForCertificateListSetup()
                                      },
                                      onError: { error in
                                          os_log("getFolder error:%@", type: .error, error.localizedDescription)
                                          signatureToPerform.error = error
                                          signatureToPerform.isDone = true
                                      })
            }

            // Then, refreshing certificate list

            checkForCertificateListSetup();
        }
    }


    // </editor-fold desc="LifeCycle">


    // <editor-fold desc="TableView">


    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        certificateList.count
    }


    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {

        let cell = tableView.dequeueReusableCell(withIdentifier: "CertificateCell", for: indexPath)
        let certificate = certificateList[indexPath.row]

        if let imageView = cell.contentView.viewWithTag(101) as? UIImageView {
            imageView.image = imageView.image!.withRenderingMode(.alwaysTemplate)

            switch (certificate.sourceType) {
                case .imprimerieNationale: imageView.image = UIImage(named: "ic_imprimerie_nationale_white_24dp")?.withRenderingMode(.alwaysTemplate)
                default: imageView.image = UIImage(named: "ic_certificate_white_24dp")?.withRenderingMode(.alwaysTemplate)
            }
        }

        if let nameLabel = cell.contentView.viewWithTag(102) as? UILabel {
            nameLabel.text = certificate.commonName
        }

        return cell
    }


    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        selectedCertificate = certificateList[indexPath.row]
    }


    // </editor-fold desc="TableView">


    // <editor-fold desc="UI Listeners">


    @IBAction func onCancelButtonClicked(_ sender: Any) {
        self.dismiss(animated: true)
    }


    @IBAction func onValidateButtonClicked(_ sender: Any) {
        os_log("onValidateButtonClicked", type: .info)

        // Default cases

        guard let deskId = currentDeskId else { return }
        let signaturesToPerform = actionsToPerform.filter { ($0.action as Action) == .sign }

        // Cannot reject without reason

        if (currentAction == .reject) && (publicAnnotationTextView.text.count < 3) {
            ViewUtils.logWarning(message: "Veuillez renseigner une raison en annotation publique.",
                                 title: "Impossible de rejeter le dossier")
            return
        }

        // Special case with P12 password

        if selectedCertificate?.sourceType == .p12File,
           signaturesToPerform.count > 0 {

            // Asking for the p12 password, to be continued in the UIAlertViewDelegate's alertViewClickedButtonAt
            // That will re-call onValidateButtonClicked, and continue...

            if currentPassword == nil {
                displayPasswordAlert()
                return
            }

            // Checking the given password. May interrupt everything if it is wrong
            else {
                guard let certificate = selectedCertificate,
                      let certificateUrl = CryptoUtils.p12LocalUrl(certificate: certificate),
                      let _ = CryptoUtils.pkcs12ReadKey(path: certificateUrl,
                                                        password: currentPassword) else {
                    currentPassword = nil
                    ViewUtils.logError(message: "Erreur de mot de passe ?",
                                       title: "Impossible de récupérer le certificat")
                    return
                }
            }
        }

        // Sending actual action

        for actionToPerform in actionsToPerform {

            switch actionToPerform.action {

                case .sign:

                    guard let pubKeyData = selectedCertificate?.publicKey as Data? else {
                        os_log("pubKey cannot be retrieved", type: .error)
                        return
                    }

                    restClient?.getSignInfo(publicKeyBase64: pubKeyData.base64EncodedString(),
                                            folder: actionToPerform.folder,
                                            bureau: currentDeskId! as NSString,
                                            onResponse: { signInfoList -> Swift.Void in
                                                os_log("getSignInfo result:%@", type: .info, signInfoList)
                                                actionToPerform.signInfoList = signInfoList
                                                self.checkForSignaturesSetup()
                                            },
                                            onError: { error -> Swift.Void in
                                                os_log("getSignInfo error:%@", type: .error, error.localizedDescription)
                                                actionToPerform.error = error
                                                actionToPerform.isDone = true
                                            })

                case .visa:

                    restClient?.visa(folder: actionToPerform.folder,
                                     bureauId: deskId,
                                     publicAnnotation: publicAnnotationTextView.text,
                                     privateAnnotation: privateAnnotationTextView.text,
                                     responseCallback: { number in
                                         actionToPerform.isDone = true
                                         self.checkAndDismissPopup()
                                     },
                                     errorCallback: { error in
                                         actionToPerform.isDone = true
                                         actionToPerform.error = error
                                         ViewUtils.logError(message: "\(error.localizedDescription)" as NSString,
                                                            title: "Erreur à l'envoi du visa")
                                     })

                case .reject:

                    restClient?.reject(folder: actionToPerform.folder,
                                       bureauId: deskId,
                                       publicAnnotation: publicAnnotationTextView.text,
                                       privateAnnotation: privateAnnotationTextView.text,
                                       responseCallback: { number in
                                           actionToPerform.isDone = true
                                           self.checkAndDismissPopup()
                                       },
                                       errorCallback: { error in
                                           actionToPerform.isDone = true
                                           actionToPerform.error = error
                                           ViewUtils.logError(message: "\(error.localizedDescription)" as NSString,
                                                              title: "Erreur à l'envoi du rejet")
                                       })

                default:

                    ViewUtils.logError(message: "Cette action n'est pas disponible sur cette version du client i-Parapheur",
                                       title: "Action impossible")
            }
        }
    }


    // </editor-fold desc="UI Listeners">


    // <editor-fold desc="UIAlertViewDelegate">


    /**
        Yes, UIAlertView are deprecated, but UIAlertController can't be overlapped.
        Since we already are in a popup, we can't show another one to prompt the password.
        This has to stay an UIAlertView, until iOS has a proper replacement.
    */
    private func displayPasswordAlert() {
        os_log("displayPasswordAlert called", type: .debug)

        // Prepare Popup

        let alertView = UIAlertView(title: "Entrer le mot de passe du certificat",
                                    message: "",
                                    delegate: self,
                                    cancelButtonTitle: "Annuler",
                                    otherButtonTitles: "OK")

        alertView.alertViewStyle = .plainTextInput
        alertView.textField(at: 0)!.isSecureTextEntry = true
        alertView.tag = WorkflowDialogController.alertViewTagP12Pass
        alertView.show()
    }


    func alertView(_ alertView: UIAlertView, clickedButtonAt buttonIndex: Int) {

        if (alertView.tag == WorkflowDialogController.alertViewTagP12Pass) {
            if (buttonIndex == 1) {

                guard let textField = alertView.textField(at: 0),
                      let givenPassword = textField.text else { return }

                currentPassword = givenPassword
                onValidateButtonClicked("")
            }
        }
    }


    // </editor-fold desc="UIAlertViewDelegate">


    func checkForCertificateListSetup() {

        if actionsToPerform
                   .filter({ $0.action == .sign })
                   .allSatisfy({ $0.folder.documents.count != 0 }) {

            certificateList = ModelsDataController.fetchCertificates()
            certificateTableView.reloadData()
        }
    }


    func checkForSignaturesSetup() {

        if actionsToPerform
                   .filter({ $0.action == .sign })
                   .allSatisfy({ $0.signInfoList.count > 0 }) {

            signature(signatureToPerform: actionsToPerform)
        }
    }


    func signature(signatureToPerform: [ActionToPerform]) {
        os_log("signature...", type: .info)

        let signaturesToPerform = actionsToPerform.filter({ $0.action == .sign })
        guard let certificate = selectedCertificate,
              signaturesToPerform.count > 0 else { return }

        switch (certificate.sourceType) {

            case .imprimerieNationale:

                // Special case : cannot sign multiple anything here

                if (actionsToPerform
                        .filter({ $0.action == .sign })
                        .flatMap { $0.signInfoList }
                        .compactMap { $0.dataToSignBase64List.count }
                        .reduce(0, +) > 1) {

                    ViewUtils.logError(message: "Le certificat sélectionné ne permet pas la signature multiple (multi-documents ou multi-bordereaux)",
                                       title: "Impossible de signer avec ce certificat")
                    return
                }

                // Sending request through IN middle-ware

                let jsonDecoder = JSONDecoder()
                guard let signatureToPerform = actionsToPerform.filter({ $0.action == .sign }).first,
                      let dataToSignBase64List = signatureToPerform.signInfoList.first?.dataToSignBase64List,
                      let certificatePayload = certificate.payload as Data?,
                      let payload: [String: String] = try? jsonDecoder.decode([String: String].self, from: certificatePayload),
                      let certificateId = payload[Certificate.payloadExternalCertificateId] else {
                    return
                }

                InController.sign(hashes: StringsUtils.toDataList(base64StringList: dataToSignBase64List),
                                  certificateId: certificateId,
                                  signatureAlgorithm: .sha256WithRsa)

            default:

                guard let pass = currentPassword else { return }

                os_log("signing with p12", type: .debug)
                for signatureToPerform in signaturesToPerform {
                    CryptoUtils.signWithP12(folderId: signatureToPerform.folder.identifier,
                                            signInfoList: signatureToPerform.signInfoList,
                                            certificate: certificate,
                                            password: pass)
                }
        }
    }


    @objc func onSignatureResult(notification: Notification) {
        os_log("onSignatureResult userInfo:%@", type: .info, notification.userInfo ?? "nil")

        // Retrieving the signed document, with available information

        var actionToPerform: ActionToPerform?

        if let signatureIndex = notification.userInfo?[CryptoUtils.notifSignatureIndex] as? Int,
           let currentActionToPerform = actionsToPerform.indices.contains(signatureIndex) ? actionsToPerform[signatureIndex] : nil,
           let currentSignedData = notification.userInfo?[CryptoUtils.notifSignedData] as? [Data] {
            os_log("onSignatureResult index:%d", type: .info, signatureIndex)
            actionToPerform = currentActionToPerform
            actionToPerform?.signInfoList[0].signaturesBase64List = currentSignedData.map({ $0.base64EncodedString() })
        }

        if let folderId = notification.userInfo![CryptoUtils.notifFolderId] as? String,
           let currentActionToPerform = actionsToPerform.filter({ $0.folder.identifier == folderId }).first,
           let signedDataList = notification.userInfo?[CryptoUtils.notifSignedData] as? [SignInfo] {
            os_log("onSignatureResult folderId:%@", type: .info, folderId)
            actionToPerform = currentActionToPerform
            actionToPerform?.signInfoList = signedDataList
        }

        guard let currentAtp = actionToPerform else {
            os_log("onSignatureResult something went wrong here", type: .error)
            return
        }

        // Throwing back result

        os_log("Folder signed:%@", type: .info, currentAtp.folder.title ?? currentAtp.folder.identifier)

        self.sendFinalSignatureResult(actionToPerform: currentAtp)
    }


    private func sendFinalSignatureResult(actionToPerform: ActionToPerform) {

        guard let deskId = currentDeskId,
              let pubKey = selectedCertificate?.publicKey?.base64EncodedString() else { return }

        let signatureConcat: [String] = actionToPerform
                .signInfoList
                .flatMap { $0.signaturesBase64List }

        let signatureTimeConcat: [Double] = actionToPerform
                .signInfoList
                .compactMap { $0.signatureDateTime }

        if (actionToPerform.signInfoList.first?.isLegacySigned ?? false) {
            restClient?.signDossierLegacy(dossierId: actionToPerform.folder.identifier,
                                          bureauId: deskId,
                                          publicAnnotation: publicAnnotationTextView.text,
                                          privateAnnotation: privateAnnotationTextView.text,
                                          publicKeyBase64: pubKey,
                                          signatures: signatureConcat,
                                          signaturesTimes: signatureTimeConcat,
                                          responseCallback: { number in
                                              actionToPerform.isDone = true
                                              self.checkAndDismissPopup()
                                          },
                                          errorCallback: { error in
                                              actionToPerform.isDone = true
                                              actionToPerform.error = error
                                              self.checkAndDismissPopup()
                                          })
        }
        else {
            restClient?.signDossier(dossierId: actionToPerform.folder.identifier,
                                    bureauId: deskId,
                                    publicAnnotation: publicAnnotationTextView.text,
                                    privateAnnotation: privateAnnotationTextView.text,
                                    publicKeyBase64: pubKey,
                                    signatures: signatureConcat,
                                    signaturesTimes: signatureTimeConcat,
                                    responseCallback: { number in
                                        actionToPerform.isDone = true
                                        self.checkAndDismissPopup()
                                    },
                                    errorCallback: { error in
                                        actionToPerform.isDone = true
                                        actionToPerform.error = error
                                        self.checkAndDismissPopup()
                                    })
        }
    }


    private func checkAndDismissPopup() {
        if actionsToPerform.allSatisfy({ $0.isDone }) {

            guard let error = actionsToPerform.first(where: { $0.error != nil }) else {

                DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                    DispatchQueue.main.async {
                        NotificationCenter.default.post(name: WorkflowDialogController.notificationActionComplete,
                                                        object: "")
                    }
                }

                self.dismiss(animated: true)
                return
            }

            ViewUtils.logError(message: (error.error?.localizedDescription ?? "") as NSString,
                               title: "Erreur lors de l'envoi de l'action")
        }
    }


}
