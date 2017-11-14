/*
* Copyright 2012-2016, Adullact-Projet.
*
* contact@adullact-projet.coop
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

@objc class ActionSelectionController: UITableViewController {
	
	static let NotifLaunchAction = Notification.Name("ActionSelectionControllerNotifLaunchAction")
	
	var actions: NSArray! = NSArray()
	var currentDossier: Dossier?
	var signatureEnabled: NSNumber! = 0
	var visaEnabled: NSNumber! = 0

	// MARK: - LifeCycle
	
	override func viewDidLoad() {
		super.viewDidLoad()
		print("View loaded : ActionSelectionController")
		
		// Parse ObjC array

		actions = Dossier.filterActions(dossierList: [currentDossier!])

		//
		
		preferredContentSize = CGSize(width: ActionSelectionCell.PreferredWidth,
		                              height: ActionSelectionCell.PreferredHeight * CGFloat(actions.count))
	}

    // MARK: - TableViewDelegate
	
	override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
		return actions.count
	}
	
	override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
		
		let cell: ActionSelectionCell = tableView.dequeueReusableCell(withIdentifier: ActionSelectionCell.CellId,
		                                                              for: indexPath as IndexPath) as! ActionSelectionCell

        let action : NSString = actions[indexPath.row] as! NSString

        cell.actionLabel.text = StringUtils.actionName(forAction: action as String,
                                                                withPaperSign: currentDossier!.isSignPapier!)

        if (action.isEqual(to: "REJET")) {
            cell.icon.image = UIImage(named: "ic_close_white")?.withRenderingMode(.alwaysTemplate)
        } else {
            cell.icon.image = UIImage(named: "ic_done_white_24dp")?.withRenderingMode(.alwaysTemplate)
        }

		return cell;
	}


    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {

		dismiss(animated: false,
				completion: { () -> Void in
					NotificationCenter.default.post(name: ActionSelectionController.NotifLaunchAction,
													object: self.actions[indexPath.row])
				})
	}

}
