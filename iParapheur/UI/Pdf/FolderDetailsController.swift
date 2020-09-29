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
import os


class FolderDetailsController: UIViewController, UITableViewDataSource, UITableViewDelegate {

    public static let segue = "folderDetails"


    @IBOutlet weak var typeTextField: UITextField!
    @IBOutlet weak var subTypeTextField: UITextField!
    @IBOutlet weak var tableView: UITableView!

    var currentWorkflow: Circuit?
    var currentFolder: Dossier?


    // <editor-fold desc="LifeCycle"> MARK: - LifeCycle


    override func viewDidLoad() {
        super.viewDidLoad()
        os_log("View loaded : AnnotationDetailsController", type: .debug)

        // UITableView border like UITextField

        tableView.layer.cornerRadius = 5
        tableView.layer.borderColor = UIColor.gray.withAlphaComponent(0.5).cgColor
        tableView.layer.borderWidth = 0.5
        tableView.clipsToBounds = true

        // Populate other fields

        typeTextField.text = currentFolder?.type
        subTypeTextField.text = currentFolder?.subType
    }


    // </editor-fold desc="LifeCycle">


    // <editor-fold desc="UI Listener"> MARK: - UI Listener


    @IBAction func onCloseButtonClicked(_ sender: Any) {
        self.dismiss(animated: true)
    }


    // </editor-fold desc="UI Listener">


    // <editor-fold desc="TableViewDelegate"> MARK: - TableViewDelegate


    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return currentWorkflow?.etapes.count ?? 0
    }


    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {

        let cell = tableView.dequeueReusableCell(withIdentifier: WorkflowStepCell.cellIdentifier,
                                                 for: indexPath) as! WorkflowStepCell
        guard let step = currentWorkflow?.etapes[indexPath.row] else { return cell }
        let isAlreadyDone = (step.dateValidation != nil)

        // Image

        let imageName = ViewUtils.getImageName(action: step.actionDemandee)
        cell.stepIconImageView.image = UIImage(named: imageName)?.withRenderingMode(.alwaysTemplate)
        cell.stepIconImageView.tintColor = ColorUtils.getColor(action: isAlreadyDone ? step.actionDemandee : "default")

        // Other fields

        cell.deskTextView.text = (step.signataire != nil) ? String(format: "%@ (par %@)", step.parapheurName, step.signataire!) : step.parapheurName
        cell.publicAnnotationTextView.text = step.annotPub
        cell.dateTextView.text = isAlreadyDone ? StringsUtils.prettyPrint(date: step.dateValidation!) : ""

        return cell
    }


    // </editor-fold desc="TableViewDelegate">

}
