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
import UIKit
import os

class DocumentSelectionController: UITableViewController {


    static let segue = "showDocumentPopover"
    @objc static let NotifShowDocument = Notification.Name("DocumentSelectionControllerNotifShowDocument")

    var documentList: [Document] = []


    // <editor-fold desc="Lifecycle"> MARK: - LifeCycle


    override func viewDidLoad() {
        super.viewDidLoad()
        os_log("View loaded : DocumentSelectionController", type: .debug)

        preferredContentSize = CGSize(width: DocumentSelectionCell.preferredWidth,
                                      height: DocumentSelectionCell.preferredHeight * CGFloat(documentList.count))
    }


    // </editor-fold desc="Lifecycle">


    // <editor-fold desc="TableViewDelegate"> MARK: - TableViewDelegate


    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return documentList.count
    }


    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {

        let document: Document = documentList[indexPath.row]
        let cell = tableView.dequeueReusableCell(withIdentifier: DocumentSelectionCell.cellId,
                                                 for: indexPath as IndexPath) as! DocumentSelectionCell

        cell.annexeIcon.image = cell.annexeIcon.image!.withRenderingMode(.alwaysTemplate)
        cell.annexeIcon.isHidden = (indexPath.row == 0) || document.isMainDocument
        cell.mainDocIcon.image = cell.mainDocIcon.image!.withRenderingMode(.alwaysTemplate)
        cell.mainDocIcon.isHidden = (indexPath.row != 0) || !document.isMainDocument
        cell.titleLabel.text = document.name

        return cell
    }


    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        dismiss(animated: false,
                completion: { () -> Void in
                    NotificationCenter.default.post(name: DocumentSelectionController.NotifShowDocument,
                                                    object: indexPath.row as NSNumber)
                })
    }


    // </editor-fold desc="TableViewDelegate">

}
