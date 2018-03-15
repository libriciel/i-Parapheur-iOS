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
import Gloss

@objc class Annotation: NSObject, Glossy {

    @objc var author: String
    @objc var identifier: String
    @objc var text: String
    @objc let date: NSDate
    let secretaire: Int?
    @objc var rect: NSValue

    let fillColor: String?
    let penColor: String?
    @objc let type: String

    @objc var step: Int
    @objc var page: Int
    @objc var documentId: String
    @objc var editable: Bool


    // MARK: - Glossy

    required init?(json: JSON) {

        author = ("author" <~~ json) ?? "(vide)"
        identifier = ("id" <~~ json) ?? ""
        text = ("text" <~~ json) ?? ""

        fillColor = ("fillColor" <~~ json) ?? "undefined"
        penColor = ("penColor" <~~ json) ?? "undefined"
        type = ("type" <~~ json) ?? "rect"

        date = NSDate(timeIntervalSince1970: (("date" <~~ json) ?? -1))
        secretaire = ("secretaire" <~~ json) ?? 0

        if let jsonRect: Dictionary<String, AnyObject>? = "rect" <~~ json {

            let jsonRectTopLeft: Dictionary<String, AnyObject>? = jsonRect!["topLeft"] as! Dictionary<String, AnyObject>?
            let jsonRectBottomRight: Dictionary<String, AnyObject>? = jsonRect!["bottomRight"] as! Dictionary<String, AnyObject>?


            let tempRect = CGRect(origin: CGPoint(x: jsonRectTopLeft!["x"] as! CGFloat,
                                                  y: jsonRectTopLeft!["y"] as! CGFloat),
                                  size: CGSize(width: (jsonRectBottomRight!["x"] as! CGFloat) - (jsonRectTopLeft!["x"] as! CGFloat),
                                               height: (jsonRectBottomRight!["y"] as! CGFloat) - (jsonRectTopLeft!["y"] as! CGFloat)))

            rect = NSValue(cgRect: ViewUtils.translateDpi(rect: tempRect,
                                                          oldDpi: 150,
                                                          newDpi: 72))
        }

        rect = NSValue.init()
        page = -1
        documentId = ""
        step = 0
        editable = true
    }

    @objc init?(currentPage: NSNumber) {

        author = ""
        identifier = "_new"
        text = ""

        fillColor = "undefined"
        penColor = "undefined"
        type = "rect"

        date = NSDate()
        secretaire = 0
        rect = NSValue(cgRect: ViewUtils.translateDpi(rect: CGRect(origin: .zero,
                                                                   size: CGSize(width: 150, height: 150)),
                                                      oldDpi: 150,
                                                      newDpi: 72))
        step = 0
        editable = false
        documentId = ""
        page = currentPage.intValue
    }

    func toJSON() -> JSON? {
        return nil /* Not used */
    }

}
