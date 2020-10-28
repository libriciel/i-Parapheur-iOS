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

class GlobalSplitViewController: UISplitViewController, UISplitViewControllerDelegate {


    override func viewDidLoad() {
        super.viewDidLoad()
        self.delegate = self

        // UIDevice orientation is not properly set here, we have to fetch the orientation through this
        let isLandscape = (UIApplication.shared.windows.first?.windowScene?.interfaceOrientation.isLandscape ?? false)
        self.preferredDisplayMode = isLandscape ? .automatic : .oneOverSecondary
    }


    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        self.preferredDisplayMode = UIDevice.current.orientation.isLandscape ? .automatic : .oneOverSecondary
    }


    func splitViewController(_ splitViewController: UISplitViewController,
                             collapseSecondary secondaryViewController: UIViewController,
                             onto primaryViewController: UIViewController) -> Bool {
        true
    }


}
