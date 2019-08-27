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
        os_log("View loaded : WorkflowDialogController", type: .debug)

        self.certificateLayout.isHidden = !(currentAction == .sign)

        NotificationCenter.default.addObserver(self,
                                               selector: #selector(onSignatureResult),
                                               name: .signatureResult,
                                               object: nil)

        for signatureToPerform in actionsToPerform.filter({ $0.action == .sign }) {
            restClient?.getSignInfo(folder: signatureToPerform.folder,
                                    bureau: currentDeskId! as NSString,
                                    onResponse: { signInfo in
                                        signatureToPerform.signInfo = signInfo
                                        self.refreshCertificateListVisibility()
                                    },
                                    onError: { error in
                                        signatureToPerform.error = error
                                        signatureToPerform.isDone = true
                                    }
            )
        }
    }


    // </editor-fold desc="LifeCycle">


    // <editor-fold desc="TableView">


    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return certificateList.count
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

        // Default cases

        guard let deskId = currentDeskId,
              let currentRestClient = restClient else { return }

        let signaturesToPerform = actionsToPerform.filter { ($0.action as Action) == .sign }
        signaturesToPerform.forEach { $0.generateRemoteHasher(restClient: currentRestClient, certificate: self.selectedCertificate) }

        if selectedCertificate?.sourceType == .imprimerieNationale {

            let signatureCount = signaturesToPerform.reduce(into: 0) { count, atp in
                count += atp.signInfo?.hashesToSign.count ?? 0
            }

            if signatureCount > 1 {
                ViewUtils.logError(message: "Le certificat sélectionné ne permet pas la signature multiple (multi-documents ou multi-bordereaux)",
                                   title: "Impossible de signer avec ce certificat")
                return
            }
        }

        // Cannot reject without reason

        if (currentAction == .reject) && (publicAnnotationTextView.text.count < 3) {
            ViewUtils.logWarning(message: "Veuillez renseigner une raison en annotation publique.",
                                 title: "Impossible de rejeter le dossier")
            return
        }

        // Special case on P12 password request

        if selectedCertificate?.sourceType == .p12File,
           signaturesToPerform.count > 0,
           currentPassword == nil {

            // P12 signature, to be continued in the UIAlertViewDelegate's alertViewClickedButtonAt
            displayPasswordAlert()
            return
        }

        // Sending actual action

        for actionToPerform in actionsToPerform {

            switch actionToPerform.action {

                case .sign:
                    signature()

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

        // Prepare Popup

        print("displayPasswordAlert called")
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
                signature()
            }
        }
    }


    // </editor-fold desc="UIAlertViewDelegate">


    func signature() {

        let signaturesToPerform = actionsToPerform.filter({ $0.action == .sign })
        guard let certificate = selectedCertificate,
              signaturesToPerform.count > 0 else { return }

        switch (certificate.sourceType) {

            case .imprimerieNationale:

                let jsonDecoder = JSONDecoder()
                guard let signatureToPerform = signaturesToPerform.first,
                      let hasher = signatureToPerform.remoteHasher,
                      let certificatePayload = certificate.payload as Data?,
                      let payload: [String: String] = try? jsonDecoder.decode([String: String].self, from: certificatePayload),
                      let certificateId = payload[Certificate.payloadExternalCertificateId] else {
                    return
                }

                hasher.generateHashToSign(onResponse:
                                          { (result: DataToSign) in
                                              os_log("signing with IN", type: .debug)
                                              InController.sign(hashes: StringsUtils.toDataList(base64StringList: result.dataToSignBase64List),
                                                                certificateId: certificateId,
                                                                signatureAlgorithm: hasher.signatureAlgorithm)
                                          },
                                          onError: { (error: Error) in
                                              signatureToPerform.isDone = true
                                              signatureToPerform.error = RuntimeError("Erreur à la récupération du hash à signer")
                                              self.checkAndDismissPopup()
                                          }
                )

            default:

                for signatureToPerform in signaturesToPerform {

                    guard let pass = currentPassword,
                          let hasher = signatureToPerform.remoteHasher else { return }

                    os_log("signing with p12", type: .debug)
                    CryptoUtils.signWithP12(hasher: hasher,
                                            certificate: certificate,
                                            password: pass)
                }
        }
    }


    @objc func onSignatureResult(notification: Notification) {
        os_log("onSignatureResult", type: .debug)

        // Retrieving the signed document, with available information

        var actionToPerform: ActionToPerform?

        if let signatureIndex = notification.userInfo![CryptoUtils.notifSignatureIndex] as? Int,
           signatureIndex < actionsToPerform.count,
           signatureIndex >= 0 {
            actionToPerform = actionsToPerform[signatureIndex]
        }

        if let folderId = notification.userInfo![CryptoUtils.notifFolderId] as? String,
           let currentActionToPerform = actionsToPerform.filter({ $0.folder.identifier == folderId }).first {
            actionToPerform = currentActionToPerform
        }

        // Throwing back result

        guard let currentAtp = actionToPerform,
              let currentHasher = currentAtp.remoteHasher,
              let signedDataList = notification.userInfo![CryptoUtils.notifSignedData] as? [Data] else { return }

        os_log("Folder signed:%@ data:%@", currentAtp.folder.title ?? currentAtp.folder.identifier, signedDataList)

        currentHasher.buildDataToReturn(signatureList: signedDataList,
                                        onResponse: { (result: [Data]) in
                                            let resultBase64List = StringsUtils.toBase64List(dataList: result)
                                            self.sendFinalSignatureResult(actionToPerform: currentAtp,
                                                                          signature: resultBase64List)
                                        },
                                        onError: { (error: Error) in
                                            currentAtp.isDone = true
                                            currentAtp.error = error
                                            self.checkAndDismissPopup()
                                        })
    }


    private func sendFinalSignatureResult(actionToPerform: ActionToPerform, signature: [String]) {

        guard let deskId = currentDeskId else { return }
        let signatureConcat = signature.joined(separator: ",")

        restClient?.signDossier(dossierId: actionToPerform.folder.identifier,
                                bureauId: deskId,
                                publicAnnotation: publicAnnotationTextView.text,
                                privateAnnotation: privateAnnotationTextView.text,
                                signature: signatureConcat,
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

    /**
        Here, we want to display the certificate list if everything is set
    */
    private func refreshCertificateListVisibility() {
        let signatureToPerform = actionsToPerform.filter { $0.action == .sign }
        if signatureToPerform.allSatisfy({ $0.signInfo != nil }) {
            certificateList = ModelsDataController.fetchCertificates()
            certificateTableView.reloadData()
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
