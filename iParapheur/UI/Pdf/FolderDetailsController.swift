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

        let cell = tableView.dequeueReusableCell(withIdentifier: WorkflowStepCell.cellIdentifier) as! WorkflowStepCell
        guard let step = currentWorkflow?.etapes[indexPath.row] else { return cell }
        let isAlreadyDone = (step.dateValidation != nil)

        // Image

        let imageName = ViewUtils.getImageName(action: step.actionDemandee)
        cell.stepIconImageView.image = UIImage(named: imageName)?.withRenderingMode(.alwaysTemplate)
        cell.stepIconImageView.tintColor = ColorUtils.getColor(action: isAlreadyDone ? step.actionDemandee : "default")

        // Other fields

        cell.deskTextView.text = (step.signataire != nil) ? String(format: "%@ (par %@)", step.parapheurName, step.signataire!) : step.parapheurName
        cell.publicAnnotationTextView.text = step.annotPub;
        cell.dateTextView.text = isAlreadyDone ? StringsUtils.prettyPrint(date: step.dateValidation!) : ""

        return cell
    }


    // </editor-fold desc="TableViewDelegate">

}
