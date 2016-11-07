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
	
	static let NotifLaunchAction: NSString! = "ActionSelectionControllerNotifLaunchAction"
	
	var actions: NSArray! = NSArray()
	var currentDossier: Dossier?
	var signatureEnabled: NSNumber! = 0
	var visaEnabled: NSNumber! = 0

	// MARK: - LifeCycle
	
	override func viewDidLoad() {
		super.viewDidLoad()
		print("View loaded : ActionSelectionController")
		
		// Parse ObjC array

		actions = Dossier.filterActions([currentDossier!])

		//
		
		preferredContentSize = CGSizeMake(ActionSelectionCell.PreferredWidth,
		                                  ActionSelectionCell.PreferredHeight * CGFloat(actions.count))
	}


    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject!) {


    }

    // MARK: - TableViewDelegate
	
	override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
		return actions.count
	}
	
	override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
		
		let cell: ActionSelectionCell = tableView.dequeueReusableCellWithIdentifier(ActionSelectionCell.CellId,
		                                                                            forIndexPath: indexPath) as! ActionSelectionCell

        let action : NSString = actions[indexPath.row] as! NSString

        cell.actionLabel.text = StringUtils.actionNameForAction(action as String,
                                                                withPaperSign: currentDossier!.isSignPapier!)

        if (action.isEqualToString("REJET")) {
            cell.icon.image = UIImage(named: "ic_close_white")?.imageWithRenderingMode(.AlwaysTemplate)
        } else {
            cell.icon.image = UIImage(named: "ic_done_white_24dp")?.imageWithRenderingMode(.AlwaysTemplate)
        }

		return cell;
	}


    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        self.dismissViewControllerAnimated(false, completion: {
            () -> Void in
            NSNotificationCenter.defaultCenter().postNotificationName(String(ActionSelectionController.NotifLaunchAction),
                                                                      object: self.actions[indexPath.row])
        })
    }

}