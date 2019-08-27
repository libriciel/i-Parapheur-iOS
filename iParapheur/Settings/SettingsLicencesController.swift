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
