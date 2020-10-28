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

class SignatureRequest: Encodable {

    var bureauCourant: String = ""
    var certificate: String = ""
    var annotPriv: String? = nil
    var annotPub: String? = nil
    var signatureBase64List: [String] = []
    var signatureTimeList: [Double] = []


    init(bureauCourant: String,
         certificate: String,
         annotPriv: String?,
         annotPub: String?,
         signatureBase64List: [String],
         signatureTimeList: [Double]) {

        self.bureauCourant = bureauCourant
        self.certificate = certificate
        self.annotPriv = annotPriv
        self.annotPub = annotPub
        self.signatureBase64List = signatureBase64List
        self.signatureTimeList = signatureTimeList
    }


    // <editor-fold desc="Json methods">


    enum CodingKeys: String, CodingKey {
        case bureauCourant
        case certificate
        case annotPriv
        case annotPub
        case signature
    }


    enum SignatureKeys: String, CodingKey {
        case signature
        case signatureDateTime
    }


    func encode(to encoder: Encoder) throws {

        var container = encoder.container(keyedBy: CodingKeys.self)

        try container.encode(bureauCourant, forKey: .bureauCourant)
        try container.encode(certificate, forKey: .certificate)
        try container.encode(annotPriv, forKey: .annotPriv)
        try container.encode(annotPub, forKey: .annotPub)

        var signatureContainer = container.nestedContainer(keyedBy: SignatureKeys.self, forKey: .signature)
        try signatureContainer.encode(signatureBase64List, forKey: .signature)
        try signatureContainer.encode(signatureTimeList, forKey: .signatureDateTime)
    }


    // </editor-fold desc="Json methods">


}