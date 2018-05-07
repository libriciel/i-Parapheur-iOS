/*
 * Copyright 2012-2017, Libriciel SCOP.
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


@objc class WorkflowDialogController: UIViewController, UITableViewDataSource, UITableViewDelegate, UIAlertViewDelegate {

    @objc static let SEGUE = "WorkflowDialogController"
    static let ALERTVIEW_TAG_P12_PASSWORD = 1
    static let ALERTVIEW_TAG_PAPER_SIGNATURE = 2

    @IBOutlet var certificateTableView: UITableView!
    @IBOutlet var certificateSelectionLabel: UILabel!
    @IBOutlet var privateAnnotationTextView: UITextView!
    @IBOutlet var publicAnnotationTextView: UITextView!
    @IBOutlet var paperSignatureButton: UIButton!

    var certificateList: [Certificate] = []
    var selectedCertificate: Certificate?
    var signInfoMap: [String: SignInfo?] = [:]
    @objc var restClient: RestClient?
    @objc var currentAction: String?
    @objc var currentBureau: String?


    // <editor-fold desc="LifeCycle">

    override func viewDidLoad() {
        super.viewDidLoad()

        NotificationCenter.default.addObserver(self,
                                               selector: #selector(onSignatureResult),
                                               name: .signatureResult,
                                               object: nil)

        if (currentAction == "SIGNATURE") {
            for dossierId in signInfoMap.keys {

                restClient?.getSignInfo(dossier: dossierId as NSString,
                                        bureau: currentBureau! as NSString,
                                        onResponse: {
                                            signInfo in
                                            self.signInfoMap[dossierId] = signInfo
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

    /**
        Here, we want to display the certificate list if everything is set
    */
    func refreshCertificateListVisibility() {

        if (!signInfoMap.values.contains {
            $0 == nil
        }) {
            certificateList = ModelsDataController.fetchCertificates()
            certificateTableView.reloadData()
        }
    }

    // <editor-fold desc="Listeners">

    @IBAction func onCancelButtonClicked(_ sender: Any) {
        self.dismiss(animated: true)
    }

    @IBAction func onValidateButtonClicked(_ sender: Any) {

        switch (selectedCertificate!.sourceType) {

            case .imprimerieNationale:

                let jsonDecoder = JSONDecoder()
                let payload: [String: [String]] = try! jsonDecoder.decode([String: [String]].self, from: selectedCertificate!.payload! as Data)
                let certificateId = payload[Certificate.PAYLOAD_CERT_ID_LIST]![0]

                InController.sign(hash: Array(signInfoMap.values)[0]!.hashesToSign[0],
                                  certificateId: certificateId)

            default:

                // P12 signature, to be continued in the UIAlertViewDelegate's alertViewClickedButtonAt
                self.displayPasswordAlert()
        }
    }

    @objc func onSignatureResult(notification: Notification) {
        let signedData: InSignedData = notification.userInfo![InController.NOTIF_USERINFO_SIGNEDDATA] as! InSignedData
        self.sendResult(dossierId: "TODO", // TODO : send an array to IN, and map the results to retrieve dossierId-s
                        signature: signedData.signedData)
    }

    // </editor-fold desc="Listeners">

    @objc func setDossiersToSign(objcArray: NSArray) {
        for dossierId in objcArray as! [String] {
            signInfoMap[dossierId] = nil as SignInfo?
        }
    }

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

    private func generateSignerWrappers() -> [String: [Signer]] {

        do {
            // Compute signature(s) hash(es)

            var signersMap: [String: [Signer]] = [:]

            for (dossierId, signInfo) in signInfoMap {
                let signers = try CryptoUtils.generateSignerWrappers(signInfo: signInfo!,
                                                                     dossierId: dossierId,
                                                                     certificate: self.selectedCertificate!)
                signersMap[dossierId] = signers
            }

            return signersMap

        } catch {
            ViewUtils.logError(message: error.localizedDescription as NSString,
                               title: "Erreur à la signature")
            return [:]
        }
    }

    private func sendResult(dossierId: String,
                            signature: String) {

        print("Adrien -- Sending back signature : \(signature)")

//        restClient?.signDossier(dossierId: dossierId,
//                                bureauId: currentBureau!,
//                                publicAnnotation: publicAnnotationTextView.text,
//                                privateAnnotation: privateAnnotationTextView.text,
//                                signature: signature,
//                                responseCallback: {
//                                    number in
//                                    print("Adrien -- Signature sent !!!")
//                                    // self.dismiss(animated: true)
//                                },
//                                errorCallback: {
//                                    error in
//                                    ViewUtils.logError(message: "\(error.localizedDescription)" as NSString,
//                                                       title: "Erreur à l'envoi de la signature")
//                                })
    }

    // <editor-fold desc="UIAlertViewDelegate">

    func alertView(_ alertView: UIAlertView, clickedButtonAt buttonIndex: Int) {

        if (alertView.tag == WorkflowDialogController.ALERTVIEW_TAG_P12_PASSWORD) {
            if (buttonIndex == 1) {

                let givenPassword = alertView.textField(at: 0)!.text!
                let signaturesTodo = generateSignerWrappers()

                for (dossierId, signers) in signaturesTodo {
                    let signatureResult = try? CryptoUtils.signWithP12(signers: signers,
                                                                       certificate: selectedCertificate!,
                                                                       password: givenPassword)
                    sendResult(dossierId: dossierId,
                               signature: signatureResult!)
                }
            }
        }
    }

    // </editor-fold desc="UIAlertViewDelegate">

}
