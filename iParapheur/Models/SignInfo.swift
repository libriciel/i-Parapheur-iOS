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
import CoreData


public class SignInfo: NSObject, Decodable {

    let format: String
    let hashesToSign: [String]
    let p7s: String?
    let pesCity: String?
    let pesClaimedRole: String?
    let pesCountryName: String?
    let pesEncoding: String?
    let pesIds: [String]
    let pesPolicyDesc: String?
    let pesPolicyHash: String?
    let pesPolicyId: String?
    let pesPostalCode: String?
    let pesSpuri: String?


    // <editor-fold desc="Json methods">

    enum CodingKeys: String, CodingKey {
        case format
        case hashToSign = "hash"
        case p7s
        case pesCity = "pescity"
        case pesClaimedRole = "pesclaimedrole"
        case pesCountryName = "pescountryname"
        case pesEncoding = "pesencoding"
        case pesId = "pesid"
        case pesPolicyDesc = "pespolicydesc"
        case pesPolicyHash = "pespolicyhash"
        case pesPolicyId = "pespolicyid"
        case pesPostalCode = "pespostalcode"
        case pesSpuri = "pesspuri"
    }


    public init(format: String, hashesToSign: [String]) {
        self.format = format
        self.hashesToSign = hashesToSign
        p7s = nil
        pesCity = nil
        pesClaimedRole = nil
        pesCountryName = nil
        pesEncoding = nil
        pesIds = []
        pesPolicyDesc = nil
        pesPolicyHash = nil
        pesPolicyId = nil
        pesPostalCode = nil
        pesSpuri = nil
    }


    public required init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)

        // Simple values

        format = try values.decodeIfPresent(String.self, forKey: .format) ?? "unknown"
        p7s = try values.decodeIfPresent(String.self, forKey: .p7s)
        pesCity = try values.decodeIfPresent(String.self, forKey: .pesCity)
        pesClaimedRole = try values.decodeIfPresent(String.self, forKey: .pesClaimedRole)
        pesCountryName = try values.decodeIfPresent(String.self, forKey: .pesCountryName)
        pesEncoding = try values.decodeIfPresent(String.self, forKey: .pesEncoding)
        pesPolicyDesc = try values.decodeIfPresent(String.self, forKey: .pesPolicyDesc)
        pesPolicyHash = try values.decodeIfPresent(String.self, forKey: .pesPolicyHash)
        pesPolicyId = try values.decodeIfPresent(String.self, forKey: .pesPolicyId)
        pesPostalCode = try values.decodeIfPresent(String.self, forKey: .pesPostalCode)
        pesSpuri = try values.decodeIfPresent(String.self, forKey: .pesSpuri)

        // Comma-separated values

        if let hashesString = try values.decodeIfPresent(String.self, forKey: .hashToSign) {
            hashesToSign = hashesString.components(separatedBy: ",")
        }
        else {
            hashesToSign = []
        }


        if let pesIdsString = try values.decodeIfPresent(String.self, forKey: .pesId) {
            pesIds = pesIdsString.components(separatedBy: ",")
        }
        else {
            pesIds = []
        }
    }

    // </editor-fold desc="Json methods">

}
