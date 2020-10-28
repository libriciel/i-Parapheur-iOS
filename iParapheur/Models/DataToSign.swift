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


public class DataToSign: NSObject, Decodable {

    let dataToSignBase64List: [String]
    let signatureDateTime: Int
    let payload: [String: String]


    public init(dataToSignBase64: [String], signatureDateTime: Int, payload: [String: String]) {
        self.dataToSignBase64List = dataToSignBase64
        self.signatureDateTime = signatureDateTime
        self.payload = payload
    }


    // <editor-fold desc="Json methods">


    enum CodingKeys: String, CodingKey {
        case dataToSignBase64List
        case signatureDateTime
        case payload
    }


    public init(dataToSignBase64 dataToSignB64: [String], signatureDateTime: Int) {
        self.dataToSignBase64List = dataToSignB64
        self.signatureDateTime = signatureDateTime
        self.payload = [:]
    }


    public required init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)

        dataToSignBase64List = try values.decodeIfPresent([String].self, forKey: .dataToSignBase64List) ?? []
        signatureDateTime = try values.decodeIfPresent(Int.self, forKey: .signatureDateTime) ?? -1
        payload = try values.decodeIfPresent([String: String].self, forKey: .payload) ?? [:]
    }


    // </editor-fold desc="Json methods">

}
