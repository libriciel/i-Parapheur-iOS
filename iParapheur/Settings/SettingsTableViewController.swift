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

class SettingsTableViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {


    @IBOutlet var menuTableView: UITableView!

    let menuElements: [(title: String, elements: [(name: String, segue: String, icon: String, iconHighlight: String)])] = [
        ("Général", [("Comptes", "accountsSegue", "ic_account_outline_white_24dp.png", "ic_account_white_24dp.png"),
                     ("Certificats", "certificatesSegue", "ic_certificate_outline_white_24dp.png", "ic_certificate_white_24dp.png")]),
        // ("Filtres", "filtersSegue", "ic_filter_outline_white_24dp.png", "ic_filter_white_24dp.png")]),
        ("À propos", [("Informations légales", "aboutSegue", "ic_info_outline_white_24dp.png", "ic_information_white_24dp.png"),
                      ("Licences tierces", "licencesSegue", "ic_copyright_outline_white_24dp.png", "ic_copyright_white_24dp.png")])
    ]


    // <editor-fold desc="LifeCycle"> MARK: - LifeCycle


    override func viewDidLoad() {
        super.viewDidLoad()
        os_log("View loaded : SettingsTableViewController", type: .debug)

        // Registering cells

        let nib = UINib(nibName: "SettingsTableViewHeaderFooterView", bundle: nil)
        menuTableView.register(nib, forHeaderFooterViewReuseIdentifier: SettingsTableViewHeaderFooterView.cellId)

        // UI tweaks

        self.splitViewController?.preferredDisplayMode = .allVisible
    }


    override func viewWillAppear(_ animated: Bool) {

        menuTableView.selectRow(at: IndexPath(row: 0, section: 0),
                                animated: false,
                                scrollPosition: UITableView.ScrollPosition.none)
    }


    // </editor-fold desc="LifeCycle">


    // <editor-fold desc="UI Listeners"> MARK: - UI Listeners


    @IBAction func onBackButtonClicked(_ sender: Any) {
        dismiss(animated: true)
    }


    // </editor-fold desc="UI Listeners">


    // <editor-fold desc="UITableViewDataSource & UITableViewDelegate"> MARK: - UITableViewDataSource & UITableViewDelegate


    func numberOfSections(in tableView: UITableView) -> Int {
        return menuElements.count
    }


    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {

        let header = tableView.dequeueReusableHeaderFooterView(withIdentifier: SettingsTableViewHeaderFooterView.cellId) as! SettingsTableViewHeaderFooterView
        header.label.text = menuElements[section].title
        header.upSeparator.isHidden = (section == 0)

        return header
    }


    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return SettingsTableViewHeaderFooterView.preferredHeight
    }


    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return menuElements[section].elements.count
    }


    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {

        let element = menuElements[indexPath.section].elements[indexPath.row]
        let cell = tableView.dequeueReusableCell(withIdentifier: SettingsTableViewCell.cellId,
                                                 for: indexPath) as! SettingsTableViewCell

        cell.iconImage.image = UIImage(named: element.icon)?.withRenderingMode(.alwaysTemplate)
        cell.iconImage.highlightedImage = UIImage(named: element.iconHighlight)?.withRenderingMode(.alwaysTemplate)
        cell.label.text = element.name

        return cell
    }


    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        performSegue(withIdentifier: menuElements[indexPath.section].elements[indexPath.row].segue, sender: self)
    }


    // </editor-fold desc="UITableViewDataSource & UITableViewDelegate">

}


