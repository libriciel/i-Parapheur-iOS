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

class SettingsTableViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {

    @IBOutlet var backButton: UIBarButtonItem!
	@IBOutlet var menuTableView: UITableView!

    // TODO : Add filters
    // ("Filtres", "filtersSegue", "ic_filter_outline_white_24dp.png", "ic_filter_white_24dp.png"),
    let menuElements: [(title:String, elements:[(name:String, segue:String, icon:String, iconHighlight:String)])] = [
            ("Général", [("Comptes", "accountsSegue", "ic_account_outline_white_24dp.png", "ic_account_white_24dp.png"),
                         ("Certificats", "certificatesSegue", "ic_verified_user_outline_white_24dp.png", "ic_verified_user_white_24dp.png")]),
            ("À propos", [("Informations légales", "aboutSegue", "ic_info_outline_white_24dp.png", "ic_information_white_24dp.png"),
                          ("Licences tierces", "licencesSegue", "ic_copyright_outline_white_24dp.png", "ic_copyright_white_24dp.png")])
    ]

    // MARK: - LifeCycle

    override func viewWillAppear(animated: Bool) {

        menuTableView.selectRowAtIndexPath(NSIndexPath(forRow: 0, inSection: 0),
                                       animated: false,
                                       scrollPosition: UITableViewScrollPosition.None)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        print("View loaded : SettingsTableViewCoColorntroller")

        backButton.target = self
        backButton.action = #selector(SettingsTableViewController.onBackButtonClicked)

        // Registering cells

        let nib = UINib(nibName: "SettingsTableViewHeaderFooterView", bundle: nil)
		menuTableView.registerNib(nib, forHeaderFooterViewReuseIdentifier: "SettingsMenuHeader")

        menuTableView.registerClass(UITableViewCell.self, forCellReuseIdentifier: "cell")
	}

    // MARK: - Listeners

    func onBackButtonClicked() {
        self.dismissViewControllerAnimated(true, completion: nil)
    }

    // MARK: - UITableViewDataSource & UITableViewDelegate

    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return menuElements.count
    }

    func tableView(tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {

        let header = tableView.dequeueReusableHeaderFooterViewWithIdentifier("SettingsMenuHeader") as! SettingsTableViewHeaderFooterView
        header.label.text = menuElements[section].title
        header.upSeparator.hidden = (section == 0)

        return header
    }

    func tableView(tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 36
    }

    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return menuElements[section].elements.count
    }

    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("SettingsMenuCell", forIndexPath: indexPath)

        if let iconView = cell.viewWithTag(101) as? UIImageView {
            let element = menuElements[indexPath.section].elements[indexPath.row]
            iconView.image = UIImage(named: element.icon)?.imageWithRenderingMode(.AlwaysTemplate)
            iconView.highlightedImage = UIImage(named: element.iconHighlight)?.imageWithRenderingMode(.AlwaysTemplate)
        }

        if let textLabel = cell.viewWithTag(102) as? UILabel {
            textLabel.text = menuElements[indexPath.section].elements[indexPath.row].name
        }

        return cell
    }

    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        performSegueWithIdentifier(menuElements[indexPath.section].elements[indexPath.row].segue, sender: self)
    }

}


