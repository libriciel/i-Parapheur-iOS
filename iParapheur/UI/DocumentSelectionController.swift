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

@objc class DocumentSelectionController: UITableViewController {

    static let NotifShowDocument: NSString! = "DocumentSelectionControllerNotifShowDocument"

    var documentList: NSArray! = NSArray()
    var docList: [Document]! = []

    // MARK: - LifeCycle

    override func viewDidLoad() {
        super.viewDidLoad()
        print("View loaded : DocumentSelectionController")

        // Parse ObjC array

        for doc in (documentList as! [Document]) {
            docList.append(doc)
        }

        //

        preferredContentSize = CGSizeMake(DocumentSelectionCell.PreferredWidth,
                                          DocumentSelectionCell.PreferredHeight * CGFloat(docList.count))
    }

    // MARK: - TableViewDelegate

    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return docList.count
    }

    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {

        let cell: DocumentSelectionCell = tableView.dequeueReusableCellWithIdentifier(DocumentSelectionCell.CellId,
                                                                                      forIndexPath: indexPath) as! DocumentSelectionCell

        let document: Document = docList[indexPath.row]

        cell.annexeIcon.image = cell.annexeIcon.image!.imageWithRenderingMode(.AlwaysTemplate)
        cell.annexeIcon.hidden = (indexPath.row == 0) || document.isMainDocument
        cell.mainDocIcon.image = cell.mainDocIcon.image!.imageWithRenderingMode(.AlwaysTemplate)
        cell.mainDocIcon.hidden = (indexPath.row != 0) || !document.isMainDocument
        cell.titleLabel.text = document.name

        return cell;
    }

    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        self.dismissViewControllerAnimated(false, completion: {
            () -> Void in
            NSNotificationCenter.defaultCenter().postNotificationName(String(DocumentSelectionController.NotifShowDocument),
                                                                      object: indexPath.row as! NSNumber)
        })
    }

}