/*
 * Copyright 2012-2017, Libriciel SCOP.
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


@objc class ColorUtils: NSObject {


    @objc static let Teal: UIColor = UIColor(red: 50 / 255, green: 128 / 255, blue: 127 / 255, alpha: 1)                  // #32807F
    @objc static let Aqua: UIColor = UIColor(red: 67 / 255, green: 122 / 255, blue: 255 / 255, alpha: 1)                  // #437AFF
    @objc static let Steel: UIColor = UIColor(red: 121 / 255, green: 121 / 255,blue: 121 / 255, alpha: 1)                 // #797979
    @objc static let DarkGreen: UIColor = UIColor(red: 11 / 255, green: 211 / 255, blue: 24 / 255, alpha: 1)              // #0BD318
    @objc static let DarkRed: UIColor = UIColor(red: 255 / 255, green: 56 / 255, blue: 36 / 255, alpha: 1)                // #FF3824
    @objc static let DarkOrange: UIColor = UIColor(red: 255 / 255, green: 150 / 255, blue: 0 / 255, alpha: 1)             // #FF9600
    @objc static let DarkYellow: UIColor = UIColor(red: 255 / 255, green: 205 / 255, blue: 0 / 255, alpha: 1)             // #FFCD00
    @objc static let DarkPurple: UIColor = UIColor(red: 198 / 255, green: 68 / 255, blue: 252 / 255, alpha: 1)            // #C644FC
    @objc static let DarkBlue: UIColor = UIColor(red: 0 / 255, green: 118 / 255, blue: 255 / 255, alpha: 1)               // #0076FF
    @objc static let SelectedCellGrey: UIColor = UIColor(red: 217 / 255, green: 217 / 255, blue: 217 / 255, alpha: 1)     // #D9D9D9
    @objc static let BlueGreySeparator: UIColor = UIColor(red: 200 / 255, green: 199 / 255, blue: 204 / 255, alpha: 1)    // #C8C7CC
    @objc static let Salmon: UIColor = UIColor(red: 241 / 255, green: 124 / 255, blue: 121 / 255, alpha: 1)               // #F17C79
    @objc static let Lime: UIColor = UIColor(red: 142 / 255, green: 250 / 255, blue: 0 / 255, alpha: 1)                   // #8EFA00
    @objc static let Sky: UIColor = UIColor(red: 118 / 255, green: 213 / 255, blue: 255 / 255, alpha: 1)                  // #76D5FF
    @objc static let Flora: UIColor = UIColor(red: 115 / 255, green: 250 / 255, blue: 121 / 255, alpha: 1)                // #73FA79
    @objc static let LightGrey: UIColor = UIColor(red: 204 / 255, green: 204 / 255, blue: 204 / 255, alpha: 1)            // #CCCCCC

    @objc static let DefaultTintColor = Aqua


    // MARK: - Static methods

    @objc static func getColor(action: NSString) -> UIColor {

        switch (action) {
            
        case "VISA", "SIGNATURE":
            return DarkGreen
        
        case "REJET":
            return DarkRed
        
        case "ARCHIVER":
            return UIKit.UIColor.black
        
        default:
            return UIKit.UIColor.lightGray
        }
    }
}
