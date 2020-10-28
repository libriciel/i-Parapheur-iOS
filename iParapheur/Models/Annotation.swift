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


class Annotation: NSObject, Codable {


    @objc var author: String
    @objc var identifier: String
    @objc var text: String
    @objc var date: Date
    var isSecretary: Bool
    @objc var rect: CGRect

    var fillColor: String?
    var penColor: String?
    @objc var type: String

    @objc var step: Int
    @objc var page: Int
    @objc var documentId: String?
    @objc var isEditable: Bool


    @objc init?(currentPage: Int) {

        author = ""
        identifier = "_new"
        text = ""

        fillColor = "undefined"
        penColor = "undefined"
        type = "rect"

        date = Date()
        isSecretary = false
        rect = CGRect(origin: .zero, size: CGSize(width: 150, height: 150))
        step = 0
        isEditable = false
        documentId = ""
        page = currentPage
    }


    // <editor-fold desc="Json methods">


    enum CodingKeys: String, CodingKey {
        case author
        case identifier = "id"
        case fillColor
        case penColor
        case date
        case secretary = "secretaire"
        case text
        case type
        case rect
        case page
        case uuid
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
        page = try values.decodeIfPresent(Int.self, forKey: .page) ?? -1

        // Secretary, may be string or bool

        do {
            isSecretary = try values.decodeIfPresent(Bool.self, forKey: .secretary) ?? false
        } catch DecodingError.typeMismatch {
            let secretaryString = try values.decodeIfPresent(String.self, forKey: .secretary) ?? "false"
            isSecretary = Bool(secretaryString) ?? false
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

        rect = CGRect(origin: CGPoint(x: CGFloat(topLeftX),
                                      y: CGFloat(topLeftY)),
                      size: CGSize(width: CGFloat(bottomRightX) - CGFloat(topLeftX),
                                   height: CGFloat(bottomRightY) - CGFloat(topLeftY)))

        documentId = ""
        step = 0
        isEditable = true
    }


    func encode(to encoder: Encoder) throws {

        var container = encoder.container(keyedBy: CodingKeys.self)

        // Rect

        var rectContainer = container.nestedContainer(keyedBy: RectKeys.self, forKey: .rect)

        var rectTopLeftContainer = rectContainer.nestedContainer(keyedBy: RectCornersKeys.self, forKey: .topLeft)
        try rectTopLeftContainer.encode(rect.origin.x, forKey: .x)
        try rectTopLeftContainer.encode(rect.origin.y, forKey: .y)

        var rectBottomRightContainer = rectContainer.nestedContainer(keyedBy: RectCornersKeys.self, forKey: .bottomRight)
        try rectBottomRightContainer.encode(rect.origin.x + rect.size.width, forKey: .x)
        try rectBottomRightContainer.encode(rect.origin.y + rect.size.height, forKey: .y)

        // Other values

        // try container.encode(page, forKey: .page)
        try container.encode(text, forKey: .text)
        try container.encode(type, forKey: .type)
        try container.encode(StringsUtils.serializeAnnotationDate(date: date).replacingOccurrences(of: "Z", with: ""), forKey: .date)
        try container.encode(identifier, forKey: .identifier)
        try container.encode(identifier, forKey: .uuid)
        try container.encode(author, forKey: .author)
        try container.encode(page, forKey: .page)
    }


    // </editor-fold desc="Json methods">

}
