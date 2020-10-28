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

@objc class ParapheurType: NSObject, Decodable {

    @objc let name: String
    @objc let subTypes: Array<String>


    // <editor-fold desc="Json methods">

    enum CodingKeys: String, CodingKey {
        case name = "id"
        case subTypes = "sousTypes"
    }

    public required init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)

        name = try values.decodeIfPresent(String.self, forKey: .name) ?? "(aucun nom)"
        subTypes = try values.decodeIfPresent([String].self, forKey: .subTypes) ?? []
    }

    // </editor-fold desc="Json methods">

}
