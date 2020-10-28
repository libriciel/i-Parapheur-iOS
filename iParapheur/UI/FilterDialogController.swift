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


class FilterDialogController: UIViewController {


    let banettes = [
        "en-preparation": "À transmettre",
        "a-traiter": "À traiter",
        "a-archiver": "En fin de circuit",
        "retournes": "Retournés",
        "en-cours": "En cours",
        "a-venir": "À venir",
        "recuperables": "Récupérables",
        "en-retard": "En retard",
        "traites": "Traités",
        "dossiers-delegues": "Dossiers en délégation",
        "no-corbeille": "Toutes les banettes",
        "no-bureau": "Tout i-Parapheur"]

    // <editor-fold desc="Lifecycle"> MARK: - LifeCycle


    override func viewDidLoad() {
        super.viewDidLoad()
        os_log("View loaded : FilterDialogController", type: .debug)
    }


    // </editor-fold desc="Lifecycle">


}