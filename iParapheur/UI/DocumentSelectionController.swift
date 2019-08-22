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
import UIKit
import os

class DocumentSelectionController: UITableViewController {


    static let segue = "showDocumentPopover"
    @objc static let NotifShowDocument = Notification.Name("DocumentSelectionControllerNotifShowDocument")

    var documentList: [Document] = []


    // <editor-fold desc="Lifecycle" MARK: - LifeCycle


    override func viewDidLoad() {
        super.viewDidLoad()
        os_log("View loaded : DocumentSelectionController", type: .debug)

        preferredContentSize = CGSize(width: DocumentSelectionCell.PreferredWidth,
                                      height: DocumentSelectionCell.PreferredHeight * CGFloat(documentList.count))
    }


    // </editor-fold desc="Lifecycle" MARK: - LifeCycle


    // <editor-fold desc="TableViewDelegate" MARK: - TableViewDelegate


    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return documentList.count
    }


    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {

        let cell: DocumentSelectionCell = tableView.dequeueReusableCell(withIdentifier: DocumentSelectionCell.CellId,
                                                                        for: indexPath as IndexPath) as! DocumentSelectionCell

        let document: Document = documentList[indexPath.row]

        cell.annexeIcon.image = cell.annexeIcon.image!.withRenderingMode(.alwaysTemplate)
        cell.annexeIcon.isHidden = (indexPath.row == 0) || document.isMainDocument
        cell.mainDocIcon.image = cell.mainDocIcon.image!.withRenderingMode(.alwaysTemplate)
        cell.mainDocIcon.isHidden = (indexPath.row != 0) || !document.isMainDocument
        cell.titleLabel.text = document.name

        return cell;
    }


    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        dismiss(animated: false,
                completion: {
                    () -> Void in
                    NotificationCenter.default.post(name: DocumentSelectionController.NotifShowDocument,
                                                    object: indexPath.row as NSNumber)
                })
    }


    // </editor-fold desc="TableViewDelegate" MARK: - TableViewDelegate

}
