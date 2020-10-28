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


class InTokenData: Decodable {

    let label:String
    let manufacturerId: String
    let serialNumber: String
    var certificates: [String:Data]
    let description: String
    let version: String


    enum CodingKeys: String, CodingKey {
        case result
    }

    enum ResultKeys: String, CodingKey {
        case token
        case certificates
        case middleware
    }

    enum TokenKeys: String, CodingKey {
        case label
        case manufacturerId
        case serialNumber
    }

    enum MiddlewareKeys: String, CodingKey {
        case description
        case version
    }


    public required init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        let resultContainer = try values.nestedContainer(keyedBy: ResultKeys.self, forKey: .result)

        let tokenContainer = try resultContainer.nestedContainer(keyedBy: TokenKeys.self, forKey: .token)
        label = try tokenContainer.decodeIfPresent(String.self, forKey: .label) ?? ""
        manufacturerId = try tokenContainer.decodeIfPresent(String.self, forKey: .manufacturerId) ?? ""
        serialNumber = try tokenContainer.decodeIfPresent(String.self, forKey: .serialNumber) ?? ""

        certificates = [String:Data]()
        let parsedCertificates = try resultContainer.decodeIfPresent([[String: String]].self, forKey: .certificates) ?? []
        for parsedCertificate in parsedCertificates {
            certificates[parsedCertificate["id"]!] = CryptoUtils.data(hex: parsedCertificate["value"]!)
        }

        let middlewareContainer = try resultContainer.nestedContainer(keyedBy: MiddlewareKeys.self, forKey: .middleware)
        description = try middlewareContainer.decodeIfPresent(String.self, forKey: .description) ?? ""
        version = try middlewareContainer.decodeIfPresent(String.self, forKey: .version) ?? ""
    }

}
