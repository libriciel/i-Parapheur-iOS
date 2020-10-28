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


class ColorUtils: NSObject {


    @objc static let teal: UIColor = UIColor(red: 50 / 255, green: 128 / 255, blue: 127 / 255, alpha: 1)                  // #32807F
    @objc static let aqua: UIColor = UIColor(red: 67 / 255, green: 122 / 255, blue: 255 / 255, alpha: 1)                  // #437AFF
    @objc static let steel: UIColor = UIColor(red: 121 / 255, green: 121 / 255, blue: 121 / 255, alpha: 1)                // #797979
    @objc static let darkGreen: UIColor = UIColor(red: 11 / 255, green: 211 / 255, blue: 24 / 255, alpha: 1)              // #0BD318
    @objc static let darkRed: UIColor = UIColor(red: 255 / 255, green: 56 / 255, blue: 36 / 255, alpha: 1)                // #FF3824
    @objc static let darkOrange: UIColor = UIColor(red: 255 / 255, green: 150 / 255, blue: 0 / 255, alpha: 1)             // #FF9600
    @objc static let darkYellow: UIColor = UIColor(red: 255 / 255, green: 205 / 255, blue: 0 / 255, alpha: 1)             // #FFCD00
    @objc static let darkPurple: UIColor = UIColor(red: 198 / 255, green: 68 / 255, blue: 252 / 255, alpha: 1)            // #C644FC
    @objc static let darkBlue: UIColor = UIColor(red: 0 / 255, green: 118 / 255, blue: 255 / 255, alpha: 1)               // #0076FF
    @objc static let selectedCellGrey: UIColor = UIColor(red: 217 / 255, green: 217 / 255, blue: 217 / 255, alpha: 1)     // #D9D9D9
    @objc static let blueGreySeparator: UIColor = UIColor(red: 200 / 255, green: 199 / 255, blue: 204 / 255, alpha: 1)    // #C8C7CC
    @objc static let salmon: UIColor = UIColor(red: 241 / 255, green: 124 / 255, blue: 121 / 255, alpha: 1)               // #F17C79
    @objc static let lime: UIColor = UIColor(red: 142 / 255, green: 250 / 255, blue: 0 / 255, alpha: 1)                   // #8EFA00
    @objc static let sky: UIColor = UIColor(red: 118 / 255, green: 213 / 255, blue: 255 / 255, alpha: 1)                  // #76D5FF
    @objc static let flora: UIColor = UIColor(red: 115 / 255, green: 250 / 255, blue: 121 / 255, alpha: 1)                // #73FA79
    @objc static let lightGrey: UIColor = UIColor(red: 204 / 255, green: 204 / 255, blue: 204 / 255, alpha: 1)            // #CCCCCC
    @objc static let veryLightGrey: UIColor = UIColor(red: 245 / 255, green: 245 / 255, blue: 245 / 255, alpha: 1)        // #F5F5F5
    @objc static let blue: UIColor = UIColor(red: 62 / 255, green: 129 / 255, blue: 255 / 255, alpha: 1)                  // #F5F5F5

    @objc static let defaultTintColor = aqua


    static func getColor(action: String) -> UIColor {
        switch (action) {
            case "VISA", "SIGNATURE":
                return darkGreen
            case "REJET":
                return darkRed
            case "ARCHIVER":
                return UIColor.black
            default:
                return UIColor.lightGray
        }
    }


}
