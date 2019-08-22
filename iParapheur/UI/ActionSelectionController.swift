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


@objc protocol ActionSelectionControllerDelegate: class {

    func onActionSelected(action: String)

}

class ActionSelectionController: UITableViewController {

    @objc static let segue = "showActionPopover"

    var actions: [String] = []
    @objc var currentDossier: Dossier?
    @objc var signatureEnabled: NSNumber! = 0
    @objc var visaEnabled: NSNumber! = 0
    var pendingAction: String = ""
    @objc weak var delegate: ActionSelectionControllerDelegate?


    // <editor-fold desc="LifeCycle">


    override func viewDidLoad() {
        super.viewDidLoad()
        os_log("View loaded : ActionSelectionController", type: .debug)

        actions = Dossier.filterActions(dossierList: [currentDossier!])

        preferredContentSize = CGSize(width: ActionSelectionCell.PreferredWidth,
                                      height: ActionSelectionCell.PreferredHeight * CGFloat(actions.count))
    }


    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == WorkflowDialogController.segue {
            if let destinationWorkflowDialogController = segue.destination as? WorkflowDialogController {
                destinationWorkflowDialogController.setDossiersToSign([currentDossier!])
                destinationWorkflowDialogController.currentAction = pendingAction
            }
        }
    }


    // </editor-fold desc="LifeCycle">


    // <editor-fold desc="TableView">


    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return actions.count
    }


    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {

        let cell: ActionSelectionCell = tableView.dequeueReusableCell(withIdentifier: ActionSelectionCell.CellId,
                                                                      for: indexPath as IndexPath) as! ActionSelectionCell

        let action: NSString = actions[indexPath.row] as NSString

        cell.actionLabel.text = NSLocalizedString(action as String, comment: "");

        if (action.isEqual(to: "REJET")) {
            cell.icon.image = UIImage(named: "ic_close_white_24dp")?.withRenderingMode(.alwaysTemplate)
        }
        else {
            cell.icon.image = UIImage(named: "ic_done_white_24dp")?.withRenderingMode(.alwaysTemplate)
        }

        return cell
    }


    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        dismiss(animated: true, completion: {
            if (self.delegate != nil) {
                self.delegate!.onActionSelected(action: self.actions[indexPath.row])
            }
        })
    }


    // </editor-fold desc="TableView">

}
