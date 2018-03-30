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


@objc class Annotation: NSObject, Decodable {

    @objc var author: String
    @objc var identifier: String
    @objc var text: String
    @objc let date: Date
    let secretaire: Bool
    @objc var rect: CGRect

    let fillColor: String?
    let penColor: String?
    @objc let type: String

    @objc var step: Int
    @objc var page: Int
    @objc var documentId: String?
    @objc var editable: Bool


    // MARK: - JSON

    enum CodingKeys: String, CodingKey {
        case author
        case identifier = "id"
        case fillColor
        case penColor
        case date
        case secretaire
        case text
        case type
        case rect
    }

    enum RectKeys: String, CodingKey {
        case topLeft
        case bottomRight
    }

    enum RectCornersKeys: String, CodingKey {
        case x
        case y
    }


    public required init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)

        author = try values.decodeIfPresent(String.self, forKey: .author) ?? "(vide)"
        identifier = try values.decodeIfPresent(String.self, forKey: .identifier)!
        text = try values.decodeIfPresent(String.self, forKey: .text) ?? "(vide)"
        fillColor = try values.decodeIfPresent(String.self, forKey: .fillColor) ?? "undefined"
        penColor = try values.decodeIfPresent(String.self, forKey: .penColor) ?? "undefined"
        type = try values.decodeIfPresent(String.self, forKey: .type) ?? "rect"

        // Secretary, may be string or bool

        do {
            secretaire = try values.decodeIfPresent(Bool.self, forKey: .secretaire) ?? false
        } catch DecodingError.typeMismatch {
            let secretaireString = try values.decodeIfPresent(String.self, forKey: .secretaire) ?? "false"
            secretaire = Bool(secretaireString)!
        }

        // Date, cropping milliseconds

        let dateString = try values.decodeIfPresent(String.self, forKey: .date) ?? "2000-01-01T00:00:00Z"
        date = StringsUtils.deserializeAnnotationDate(string: "\(dateString.prefix(19))Z")

        // Rect

        let rectContainer = try values.nestedContainer(keyedBy: RectKeys.self, forKey: .rect)
        let topLeftContainer = try rectContainer.nestedContainer(keyedBy: RectCornersKeys.self, forKey: .topLeft)
        let bottomRightContainer = try rectContainer.nestedContainer(keyedBy: RectCornersKeys.self, forKey: .bottomRight)

        let topLeftX = StringsUtils.parseNumberOrString(container: topLeftContainer, key: RectCornersKeys.x)
        let topLeftY = StringsUtils.parseNumberOrString(container: topLeftContainer, key: RectCornersKeys.y)
        let bottomRightX = StringsUtils.parseNumberOrString(container: bottomRightContainer, key: RectCornersKeys.x)
        let bottomRightY = StringsUtils.parseNumberOrString(container: bottomRightContainer, key: RectCornersKeys.y)

        let tempRect = CGRect(origin: CGPoint(x: CGFloat(topLeftX),
                                              y: CGFloat(topLeftY)),
                              size: CGSize(width: CGFloat(bottomRightX) - CGFloat(topLeftX),
                                           height: CGFloat(bottomRightY) - CGFloat(topLeftY)))

        rect = ViewUtils.translateDpi(rect: tempRect,
                                      oldDpi: 150,
                                      newDpi: 72)

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

        date = Date()
        secretaire = false
        rect = ViewUtils.translateDpi(rect: CGRect(origin: .zero,
                                                   size: CGSize(width: 150, height: 150)),
                                      oldDpi: 150,
                                      newDpi: 72)
        step = 0
        editable = false
        documentId = ""
        page = currentPage.intValue
    }

}
