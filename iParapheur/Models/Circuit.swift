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


public class Circuit: NSObject, Decodable {


    let etapes: [Etape]
    let annotPriv: String?
    let isDigitalSignatureMandatory: Bool
    let isMultiDocument: Bool
    let hasSelectionScript: Bool
    let sigFormat: String?
    let signatureProtocol: String?


    // <editor-fold desc="Json methods">


    enum CodingKeys: String, CodingKey {
        case etapes
        case annotPriv
        case isDigitalSignatureMandatory
        case isMultiDocument
        case hasSelectionScript
        case sigFormat
        case signatureProtocol = "protocol"
    }


    public required init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)

        etapes = try values.decodeIfPresent([Etape].self, forKey: .etapes) ?? []
        annotPriv = try values.decodeIfPresent(String.self, forKey: .annotPriv)
        isDigitalSignatureMandatory = try values.decodeIfPresent(Bool.self, forKey: .isDigitalSignatureMandatory) ?? false
        isMultiDocument = try values.decodeIfPresent(Bool.self, forKey: .isMultiDocument) ?? false
        hasSelectionScript = try values.decodeIfPresent(Bool.self, forKey: .hasSelectionScript) ?? false
        sigFormat = try values.decodeIfPresent(String.self, forKey: .sigFormat)
        signatureProtocol = try values.decodeIfPresent(String.self, forKey: .signatureProtocol)
    }


    // </editor-fold desc="Json methods">

}



