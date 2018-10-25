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

import UIKit
import Foundation


@objc class SettingsCertificatesController: UIViewController, UITableViewDataSource, UIDocumentInteractionControllerDelegate {


    static let DocumentationPdfName: String = "i-Parapheur_mobile_import_certificats_v2"

    @IBOutlet var certificatesTableView: UITableView!

    var certificateList: [Certificate] = []
    var dateFormatter: DateFormatter!


    // MARK: - Life cycle

    override func viewDidLoad() {
        super.viewDidLoad()
        print("View loaded : SettingsCertificatesController")

        certificateList = ModelsDataController.fetchCertificates()
        print("Adrien - \(certificateList)")
        certificatesTableView.dataSource = self

        dateFormatter = DateFormatter()
        dateFormatter.dateStyle = DateFormatter.Style.short
        dateFormatter.timeStyle = DateFormatter.Style.none
        dateFormatter.locale = NSLocale.current;

        NotificationCenter.default.addObserver(self, selector: #selector(onCertificateImport),
                                               name: .imprimerieNationaleCertificateImport,
                                               object: nil)
    }


    // MARK: - UITableViewDataSource & UITableViewDelegate

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {

        if (certificateList.count == 0) {
            let emptyView: SettingsCertificatesEmptyView = SettingsCertificatesEmptyView.instanceFromNib();
            emptyView.downloadDocButton.addTarget(self,
                                                  action: #selector(downloadDocButton),
                                                  for: UIControl.Event.touchUpInside)
            tableView.backgroundView = emptyView;
        } else {
            tableView.backgroundView = nil;
        }

        return certificateList.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {

        let cell = tableView.dequeueReusableCell(withIdentifier: "CertificateCell", for: indexPath)
        let certificate = certificateList[indexPath.row]

        if let nameLabel = cell.viewWithTag(101) as? UILabel {
            nameLabel.text = certificate.commonName
        }

        if let expirationDateLabel = cell.viewWithTag(102) as? UILabel {

            // For Keystore CoreDataModel v2
            if (certificate.notAfter != nil) {
                expirationDateLabel.isHidden = false
                let notAfterString: String = dateFormatter.string(from: certificate.notAfter! as Date)
                expirationDateLabel.text = expirationDateLabel.text?.replacingOccurrences(of: ":date:", with: notAfterString)

                let notAfterCompare: ComparisonResult = certificate.notAfter!.compare(Date())
                expirationDateLabel.textColor = notAfterCompare == ComparisonResult.orderedAscending ? UIColor.red : UIColor.lightGray
            }
            // For Keystore CoreDataModel v1
            else {
                expirationDateLabel.isHidden = true
            }
        }

        if let deleteButton = cell.viewWithTag(103) as? UIButton {
            deleteButton.addTarget(self,
                                   action: #selector(onDeleteButtonClicked),
                                   for: .touchUpInside)
        }

        return cell
    }


    // MARK: - UIDocumentInteractionControllerDelegate

    func documentInteractionControllerViewControllerForPreview(_ controller: UIDocumentInteractionController) -> UIViewController {
        return self
    }


    // MARK: - Listeners

    @IBAction func onImprimerieNationaleImportButtonClicked(_ sender: UIButton) {
        InController.getTokenData();
    }

    @objc func downloadDocButton(sender: UIButton) {

        let url = Bundle.main.url(forResource: SettingsCertificatesController.DocumentationPdfName, withExtension: "pdf")

        let docController: UIDocumentInteractionController! = UIDocumentInteractionController(url: url!)
        docController.delegate = self
        docController.presentPreview(animated: true)
    }

    @objc func onDeleteButtonClicked(sender: UIButton) {

        let buttonPosition: CGPoint = sender.convert(.zero, to: certificatesTableView);
        let indexPath: IndexPath = certificatesTableView.indexPathForRow(at: buttonPosition)!;

        // Find from NSManagedObjectContext

        var certificateToDelete: NSManagedObject? = nil
        for certificate in  ModelsDataController.fetchCertificates() {
            if (certificate.identifier == certificateList[indexPath.row].identifier) {
                certificateToDelete = certificate
            }
        }

        // Safety check

        if (certificateToDelete == nil) {
            return
        }

        // Delete from local DB, and update UI

        ModelsDataController.context!.delete(certificateToDelete!)
        certificateList = ModelsDataController.fetchCertificates()
        certificatesTableView.deleteRows(at: [indexPath as IndexPath], with: .fade)
        ModelsDataController.save()
    }

    @objc func onCertificateImport() {
        print("Adrien Notification Received")
    }

}
