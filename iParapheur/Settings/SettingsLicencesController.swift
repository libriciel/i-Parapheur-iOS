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


class SettingsLicencesController: UIViewController, UITableViewDataSource {


    let elements: [(String, String)] = [
        ("AEXML", "Version 4.4.0\nhttps://github.com/tadija/AEXML\nLicenced under the MIT Licence"),
        ("AlamoFire", "Version 4.7.3\nhttps://github.com/Alamofire/Alamofire\nLicenced under the MIT Licence"),
        ("CryptoSwift", "Version 1.0.0\nhttps://github.com/krzyzanowskim/CryptoSwift\nLicenced under the zlib Licence"),
        ("Floaty", "Version 4.2.0\nhttps://github.com/kciter/Floaty\nLicenced under the MIT Licence"),
        ("OpenSSL Universal", "Version 1.0.2.18\nhttps://github.com/krzyzanowskim/OpenSSL\nLicenced under a dual BSD Licence"),
        ("SCNetworkReachability", "Version 2.0.6\nhttps://github.com/belkevich/reachability-ios\nLicenced under the MIT Licence"),
        ("Sentry-Cocoa", "Version 4.4.0\nhttps://github.com/getsentry/sentry-cocoa\nLicenced under the MIT Licence"),
        ("SSZipArchive", "Version 2.2.2\nhttps://github.com/ZipArchive/ZipArchive\nLicenced under the MIT License"),
        ("SwiftMessages", "Version 7.0.0\nhttps://github.com/SwiftKickMobile/SwiftMessages\nLicenced under the MIT Licence"),
        ("Templarian Material Icons", "©Austin Andrews @Templarian\nhttps://github.com/Templarian/MaterialDesign\nLicensed under the SIL Open Font Licence")
    ]


    // <editor-fold desc="LifeCycle"> MARK: - LifeCycle


    override func viewDidLoad() {
        super.viewDidLoad()
        os_log("View loaded : SettingsLicencesController", type: .debug)
    }


    // </editor-fold desc="LifeCycle">


    // <editor-fold desc="UITableViewDataSource"> MARK: - UITableViewDataSource


    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return elements.count
    }


    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {

        let element = elements[indexPath.row]
        let cell = tableView.dequeueReusableCell(withIdentifier: SettingsLicencesTableViewCell.cellId,
                                                 for: indexPath) as! SettingsLicencesTableViewCell

        cell.title.text = element.0
        cell.content.text = element.1
        
        return cell
    }


    // </editor-fold desc="UITableViewDataSource">

}
