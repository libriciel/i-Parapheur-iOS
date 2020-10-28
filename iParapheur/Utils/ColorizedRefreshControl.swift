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

/**
    Fixes the white line between the SearchController bar and the RefreshController
    Taken from there : https://stackoverflow.com/a/50670500/9122113
 */
class ColorizedRefreshControl: UIRefreshControl {


    override var isHidden: Bool {
        get {
            return super.isHidden
        }
        set(hiding) {
            if hiding {
                guard frame.origin.y >= 0 else { return }
                super.isHidden = hiding
            }
            else {
                guard frame.origin.y < 0 else { return }
                super.isHidden = hiding
            }
        }
    }


    override var frame: CGRect {
        didSet {
            if frame.origin.y < 0 {
                isHidden = false
            }
            else {
                isHidden = true
            }
        }
    }


    override func layoutSubviews() {
        super.layoutSubviews()
        let originalFrame = frame
        frame = originalFrame
    }

}