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
import Foundation
import os


@objc class SettingsCertificatesController: UIViewController, UITableViewDataSource, UIDocumentInteractionControllerDelegate {


    static let DocumentationPdfName: String = "i-Parapheur_mobile_import_certificats_v2"

    @IBOutlet var certificatesTableView: UITableView!

    var certificateList: [Certificate] = []
    var dateFormatter: DateFormatter!


    // MARK: - Life cycle

    override func viewDidLoad() {
        super.viewDidLoad()
        os_log("View loaded : SettingsCertificatesController", type: .debug)

        certificateList = ModelsDataController.fetchCertificates()
        certificatesTableView.dataSource = self

        dateFormatter = DateFormatter()
        dateFormatter.dateStyle = DateFormatter.Style.short
        dateFormatter.timeStyle = DateFormatter.Style.none
        dateFormatter.locale = NSLocale.current

        NotificationCenter.default.addObserver(self, selector: #selector(onCertificateImport),
                                               name: .imprimerieNationaleCertificateImport,
                                               object: nil)
    }


    // MARK: - UITableViewDataSource & UITableViewDelegate

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {

        if (certificateList.count == 0) {
            let emptyView: SettingsCertificatesEmptyView = SettingsCertificatesEmptyView.instanceFromNib()
            emptyView.downloadDocButton.addTarget(self,
                                                  action: #selector(downloadDocButton),
                                                  for: UIControl.Event.touchUpInside)
            tableView.backgroundView = emptyView
        }
        else {
            tableView.backgroundView = nil
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
        InController.getTokenData()
    }

    @objc func downloadDocButton(sender: UIButton) {

        let url = Bundle.main.url(forResource: SettingsCertificatesController.DocumentationPdfName, withExtension: "pdf")

        let docController: UIDocumentInteractionController! = UIDocumentInteractionController(url: url!)
        docController.delegate = self
        docController.presentPreview(animated: true)
    }

    @objc func onDeleteButtonClicked(sender: UIButton) {

        let buttonPosition: CGPoint = sender.convert(.zero, to: certificatesTableView)
        let indexPath: IndexPath = certificatesTableView.indexPathForRow(at: buttonPosition)!

        // Find from NSManagedObjectContext

        var certificateToDelete: NSManagedObject? = nil
        for certificate in ModelsDataController.fetchCertificates() {
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
        certificateList = ModelsDataController.fetchCertificates()
        certificatesTableView.reloadData()
    }

}
