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


class InSignedData: Decodable {

    var signedData: String


    enum CodingKeys: String, CodingKey {
        case result
    }

    enum ResultKeys: String, CodingKey {
        case signedData
    }


    public required init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        let resultContainer = try values.nestedContainer(keyedBy: ResultKeys.self, forKey: .result)

        signedData = try resultContainer.decodeIfPresent(String.self, forKey: .signedData) ?? ""
    }

}

