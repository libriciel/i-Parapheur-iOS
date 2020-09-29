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


