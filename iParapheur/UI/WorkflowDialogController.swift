/*
 * Contributors : SKROBS (2012)
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


@objc class WorkflowDialogController: UIViewController, UITableViewDataSource, UITableViewDelegate {

    @objc static let SEGUE = "WorkflowDialogController"

    @IBOutlet var certificateTableView: UITableView!
    @IBOutlet var certificateSelectionLabel: UILabel!
    @IBOutlet var privateAnnotationTextView: UITextView!
    @IBOutlet var publicAnnotationTextView: UITextView!
    @IBOutlet var paperSignatureButton: UIButton!

    var certificateList: [Certificate] = []
    var selectedCertificate: Certificate?
    @objc var dossiersToSign: [Dossier] = []
    @objc var currentAction: String?


    // <editor-fold desc="LifeCycle">

    override func viewDidLoad() {
        super.viewDidLoad()
        certificateList.append(contentsOf: ModelsDataController.fetchCertificates())
        print("Adrien --> Certificates --> \(certificateList)")
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

    func tableView(_ tableView: UITableView, didDeselectRowAt indexPath: IndexPath) {
        selectedCertificate = certificateList[indexPath.row]
    }

    // </editor-fold desc="TableView">

    // <editor-fold desc="Listeners">

    @IBAction func onCancelButtonClicked(_ sender: Any) {
        self.dismiss(animated: true)
    }

    @IBAction func onValidateButtonClicked(_ sender: Any) {
        InController.sign(hash: "test", certificateId: selectedCertificate!.serialNumber!)
    }

    // </editor-fold desc="Listeners">

}
