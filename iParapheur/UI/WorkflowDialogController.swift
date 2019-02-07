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


@objc class WorkflowDialogController: UIViewController, UITableViewDataSource, UITableViewDelegate, UIAlertViewDelegate {

    @objc static let SEGUE = "WorkflowDialogController"
    static let ALERTVIEW_TAG_P12_PASSWORD = 1
    static let ALERTVIEW_TAG_PAPER_SIGNATURE = 2

    @IBOutlet var certificateLayout: UIStackView!
    @IBOutlet var certificateTableView: UITableView!
    @IBOutlet var privateAnnotationTextView: UITextView!
    @IBOutlet var publicAnnotationTextView: UITextView!
    @IBOutlet var paperSignatureButton: UIButton!

    var certificateList: [Certificate] = []
    var selectedCertificate: Certificate?
    var signInfoMap: [Dossier: SignInfo?] = [:]
    var signaturesToDo: [String: RemoteHasher] = [:]
    @objc var restClient: RestClient?
    @objc var currentAction: String?
    @objc var currentBureau: String?


    // <editor-fold desc="LifeCycle">


    override func viewDidLoad() {
        super.viewDidLoad()
        os_log("View loaded : WorkflowDialogController", type: .debug)

        self.certificateLayout.isHidden = !(currentAction == "SIGNATURE")

        NotificationCenter.default.addObserver(self,
                                               selector: #selector(onSignatureResult),
                                               name: .signatureResult,
                                               object: nil)

        if (currentAction == "SIGNATURE") {
            for dossier in signInfoMap.keys {

                restClient?.getSignInfo(dossier: dossier,
                                        bureau: currentBureau! as NSString,
                                        onResponse: {
                                            signInfo in
                                            self.signInfoMap[dossier] = signInfo
                                            self.refreshCertificateListVisibility()
                                        },
                                        onError: {
                                            error in
                                            ViewUtils.logError(message: "\(error.localizedDescription)" as NSString,
                                                               title: "Erreur à la récupération des données à signer")
                                        }
                )
            }
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
        switch currentAction {


            case "SIGNATURE":

                signature()


            case "VISA":

                restClient?.visa(dossier: Array(signInfoMap.keys)[0],
                                 bureauId: currentBureau!,
                                 publicAnnotation: publicAnnotationTextView.text,
                                 privateAnnotation: privateAnnotationTextView.text,
                                 responseCallback: {
                                     number in
                                     self.dismissWithRefresh()
                                 },
                                 errorCallback: {
                                     error in
                                     ViewUtils.logError(message: "\(error.localizedDescription)" as NSString,
                                                        title: "Erreur à l'envoi du visa")
                                 })


            case "REJET":

                restClient?.reject(dossier: Array(signInfoMap.keys)[0],
                                   bureauId: currentBureau!,
                                   publicAnnotation: publicAnnotationTextView.text,
                                   privateAnnotation: privateAnnotationTextView.text,
                                   responseCallback: {
                                       number in
                                       self.dismissWithRefresh()
                                   },
                                   errorCallback: {
                                       error in
                                       ViewUtils.logError(message: "\(error.localizedDescription)" as NSString,
                                                          title: "Erreur à l'envoi du rejet")
                                   })


            default:

                ViewUtils.logError(message: "Cette action n'est pas disponible sur cette version du client i-Parapheur",
                                   title: "Action impossible")
        }
    }


    // </editor-fold desc="UI Listeners">


    @objc func setDossiersToSign(objcArray: NSArray) {
        for dossier in objcArray as! [Dossier] {
            signInfoMap[dossier] = nil as SignInfo?
        }
    }


    private func signature() {

        if (selectedCertificate == nil) {
            return
        }

        signaturesToDo = generateHasherWrappers()
        if (signaturesToDo.isEmpty) {
            return
        }

        switch (selectedCertificate!.sourceType) {

            case .imprimerieNationale:

                if ((signaturesToDo.count != 1) || (signaturesToDo.values.count > 1)) {
                    ViewUtils.logError(message: "Le certificat sélectionné ne permet pas la signature multiple (multi-documents ou multi-bordereaux)",
                                       title: "Impossible de signer avec ce certificat")
                    return
                }

                for signatureToDo in signaturesToDo {
                    print(signatureToDo)

                    if ((signatureToDo.value.mSignInfo.hashesToSign.count != 1) || (signatureToDo.value.mSignInfo.hashesToSign.count > 1)) {
                        ViewUtils.logError(message: "Le certificat sélectionné ne permet pas la signature multiple (multi-documents ou multi-bordereaux)",
                                           title: "Impossible de signer avec ce certificat")
                        return
                    }
                }

                let jsonDecoder = JSONDecoder()
                let payload: [String: String] = try! jsonDecoder.decode([String: String].self, from: selectedCertificate!.payload! as Data)
                let certificateId = payload[Certificate.PAYLOAD_EXTERNAL_CERTIFICATE_ID]!
                let hasher: RemoteHasher = Array(signaturesToDo.values)[0]

                hasher.generateHashToSign(onResponse:
                                          {
                                              (result: DataToSign) in

                                              InController.sign(hashes: StringsUtils.toDataList(base64StringList: result.dataToSignBase64List),
                                                                certificateId: certificateId,
                                                                signatureAlgorithm: Array(self.signaturesToDo.values)[0].mSignatureAlgorithm)
                                          },
                                          onError:
                                          {
                                              (error: Error) in
                                              ViewUtils.logError(message: "Vérifier le réseau",
                                                                 title: "Erreur à la récupération du hash à signer")
                                          }
                )

            default:

                for signatureToDo in signaturesToDo {
                    print(signatureToDo)

                    // P12 signature, to be continued in the UIAlertViewDelegate's alertViewClickedButtonAt
                    self.displayPasswordAlert()
                }
        }
    }


    @objc func onSignatureResult(notification: Notification) {

        let signedDataList = notification.userInfo![CryptoUtils.NOTIF_SIGNEDDATA] as! [Data]
        let dossierId: String? = notification.userInfo![CryptoUtils.NOTIF_DOSSIERID] as? String
        let signatureIndex: Int? = notification.userInfo![CryptoUtils.NOTIF_SIGNATUREINDEX] as? Int

        var hasher: RemoteHasher? = nil
        if (dossierId != nil) {
            hasher = signaturesToDo[dossierId!]
        }
        if (signatureIndex != nil) {
            hasher = Array(signaturesToDo.values)[signatureIndex!]
        }

        hasher!.buildDataToReturn(signatureList: signedDataList,
                                  onResponse: {
                                      (result: [Data]) in

                                      let resultBase64List = StringsUtils.toBase64List(dataList: result)
                                      self.sendFinalSignatureResult(dossierId: Array(self.signaturesToDo.keys)[0], signature: resultBase64List)
                                  },
                                  onError: {
                                      (error: Error) in
                                      print(error.localizedDescription)
                                  });
    }


    private func sendFinalSignatureResult(dossierId: String, signature: [String]) {

        let signatureConcat = signature.joined(separator: ",")

        restClient?.signDossier(dossierId: dossierId,
                                bureauId: currentBureau!,
                                publicAnnotation: publicAnnotationTextView.text,
                                privateAnnotation: privateAnnotationTextView.text,
                                signature: signatureConcat,
                                responseCallback: {
                                    number in
                                    self.dismissWithRefresh()
                                },
                                errorCallback: {
                                    error in
                                    ViewUtils.logError(message: "\(error.localizedDescription)" as NSString,
                                                       title: "Erreur à l'envoi de la signature")
                                })
    }


    /**
        Here, we want to display the certificate list if everything is set
    */
    private func refreshCertificateListVisibility() {

        if (!signInfoMap.values.contains {
            $0 == nil
        }) {
            certificateList = ModelsDataController.fetchCertificates()
            certificateTableView.reloadData()
        }
    }

    /**
        Yes, UIAlertView are deprecated, but UIAlertController can't be overlapped.
        Since we already are in a popup, we can't show another one to prompt the password.
        This has to stay an UIAlertView, until iOS has a proper replacement.
    */
    private func displayPasswordAlert() {

        // Prepare Popup

        let alertView = UIAlertView(title: "Entrer le mot de passe du certificat",
                                    message: "",
                                    delegate: self,
                                    cancelButtonTitle: "Annuler",
                                    otherButtonTitles: "OK")

        alertView.alertViewStyle = .plainTextInput
        alertView.textField(at: 0)!.isSecureTextEntry = true
        alertView.tag = WorkflowDialogController.ALERTVIEW_TAG_P12_PASSWORD
        alertView.show()
    }


    private func generateHasherWrappers() -> [String: RemoteHasher] {

        do {
            // Compute signature(s) hash(es)

            var hashersMap: [String: RemoteHasher] = [:]
            for (dossier, signInfo) in signInfoMap {

                let hasher = try CryptoUtils.generateHasherWrappers(signInfo: signInfo!,
                                                                    dossier: dossier,
                                                                    certificate: self.selectedCertificate!,
                                                                    restClient: restClient!)

                hashersMap[dossier.identifier] = hasher
            }

            return hashersMap

        } catch {
            ViewUtils.logError(message: error.localizedDescription as NSString,
                               title: "Erreur à la signature")
            return [:]
        }
    }


    private func dismissWithRefresh() {
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            DispatchQueue.main.async {
                NotificationCenter.default.post(name: Notification.Name("actionOnDossierComplete"),
                                                object: "")
            }
        }

        self.dismiss(animated: true)
    }

    // <editor-fold desc="UIAlertViewDelegate">


    func alertView(_ alertView: UIAlertView, clickedButtonAt buttonIndex: Int) {

        if (alertView.tag == WorkflowDialogController.ALERTVIEW_TAG_P12_PASSWORD) {
            if (buttonIndex == 1) {

                let givenPassword = alertView.textField(at: 0)!.text!

                for (_, hasher) in signaturesToDo {
                    CryptoUtils.signWithP12(hasher: hasher,
                                            certificate: selectedCertificate!,
                                            password: givenPassword)
                }
            }
        }
    }


    // </editor-fold desc="UIAlertViewDelegate">

}
