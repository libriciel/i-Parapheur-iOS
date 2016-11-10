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

@objc class ColorUtils: NSObject {

    static let Teal: UIColor = UIColor(red: 50 / 255, green: 128 / 255, blue: 127 / 255, alpha: 1)                  // #32807F
    static let Aqua: UIColor = UIColor(red: 67 / 255, green: 122 / 255, blue: 255 / 255, alpha: 1)                  // #437AFF
    static let Steel: UIColor = UIColor(red: 121 / 255, green: 121 / 255,blue: 121 / 255, alpha: 1)                 // #797979
    static let DarkGreen: UIColor = UIColor(red: 11 / 255, green: 211 / 255, blue: 24 / 255, alpha: 1)              // #0BD318
    static let DarkRed: UIColor = UIColor(red: 255 / 255, green: 56 / 255, blue: 36 / 255, alpha: 1)                // #FF3824
    static let DarkOrange: UIColor = UIColor(red: 255 / 255, green: 150 / 255, blue: 0 / 255, alpha: 1)             // #FF9600
    static let DarkYellow: UIColor = UIColor(red: 255 / 255, green: 205 / 255, blue: 0 / 255, alpha: 1)             // #FFCD00
    static let DarkPurple: UIColor = UIColor(red: 198 / 255, green: 68 / 255, blue: 252 / 255, alpha: 1)            // #C644FC
    static let DarkBlue: UIColor = UIColor(red: 0 / 255, green: 118 / 255, blue: 255 / 255, alpha: 1)               // #0076FF
    static let SelectedCellGrey: UIColor = UIColor(red: 217 / 255, green: 217 / 255, blue: 217 / 255, alpha: 1)     // #D9D9D9
    static let BlueGreySeparator: UIColor = UIColor(red: 200 / 255, green: 199 / 255, blue: 204 / 255, alpha: 1)    // #C8C7CC
    static let Salmon: UIColor = UIColor(red: 241 / 255, green: 124 / 255, blue: 121 / 255, alpha: 1)               // #F17C79
    static let Lime: UIColor = UIColor(red: 142 / 255, green: 250 / 255, blue: 0 / 255, alpha: 1)                   // #8EFA00
    static let Sky: UIColor = UIColor(red: 118 / 255, green: 213 / 255, blue: 255 / 255, alpha: 1)                  // #76D5FF
    static let Flora: UIColor = UIColor(red: 115 / 255, green: 250 / 255, blue: 121 / 255, alpha: 1)                // #73FA79
    static let LightGrey: UIColor = UIColor(red: 204 / 255, green: 204 / 255, blue: 204 / 255, alpha: 1)            // #CCCCCC

    static let DefaultTintColor = Aqua

    // MARK: - Static methods

    static func colorForAction(action: NSString) -> UIColor {

        if (action.isEqualToString("VISA") || action.isEqualToString("SIGNATURE")) {
            return DarkGreen
        }
        else if (action.isEqualToString("REJET")) {
            return DarkRed
        }
        else if action.isEqualToString("ARCHIVER") {
            return UIKit.UIColor.blackColor()
        }
        else {
            return UIKit.UIColor.lightGrayColor()
        }
    }
}
