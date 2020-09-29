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


class Document: NSObject, Decodable {


    @objc let identifier: String
    @objc let name: String

    let size: CLong
    let pageCount: Int
    let attestState: Int

    let isMainDocument: Bool
    let isPdfVisual: Bool
    let isLocked: Bool
    let isDeletable: Bool


    // <editor-fold desc="Json methods">


    enum CodingKeys: String, CodingKey {
        case identifier = "id"
        case name
        case size
        case pageCount
        case attestState
        case isMainDocument
        case isPdfVisual = "visuelPdf"
        case isLocked
        case isDeletable = "canDelete"
    }


    public required init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)

        identifier = try values.decodeIfPresent(String.self, forKey: .identifier) ?? ""
        name = try values.decodeIfPresent(String.self, forKey: .name) ?? "(vide)"

        size = try values.decodeIfPresent(Int.self, forKey: .size) ?? -1
        pageCount = try values.decodeIfPresent(Int.self, forKey: .pageCount) ?? -1
        attestState = try values.decodeIfPresent(Int.self, forKey: .attestState) ?? 0

        isMainDocument = try values.decodeIfPresent(Bool.self, forKey: .isMainDocument) ?? false
        isPdfVisual = try values.decodeIfPresent(Bool.self, forKey: .isPdfVisual) ?? false
        isLocked = try values.decodeIfPresent(Bool.self, forKey: .isLocked) ?? false
        isDeletable = try values.decodeIfPresent(Bool.self, forKey: .isDeletable) ?? false
    }


    // </editor-fold desc="Json methods">

}
