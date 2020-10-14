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

    let format: String?
    let dataToSignBase64List: [String]
    var signaturesBase64List: [String]
    let signatureDateTime: Double?


    public init(format: String?,
                dataToSignBase64List: [String],
                signaturesBase64List: [String],
                signatureDateTime: Double?) {
        self.format = format
        self.dataToSignBase64List = dataToSignBase64List
        self.signaturesBase64List = signaturesBase64List
        self.signatureDateTime = signatureDateTime
    }


    // <editor-fold desc="Json methods">


    enum CodingKeys: String, CodingKey {
        case dataToSignBase64List
        case signatureDateTime
        case format
    }


    public required init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)

        format = try values.decodeIfPresent(String.self, forKey: .format)
        signatureDateTime = try values.decodeIfPresent(Double.self, forKey: .signatureDateTime)

        let dataToSignBase64ListString = try values.decodeIfPresent(String.self, forKey: .dataToSignBase64List)
        dataToSignBase64List = dataToSignBase64ListString?.components(separatedBy: ",") ?? []

        signaturesBase64List = []
    }


    // </editor-fold desc="Json methods">

}
