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


@objc public class Etape: NSObject, Decodable {


    @objc let approved: Bool
    @objc let signataire: String?
    @objc let rejected: Bool
    @objc let dateValidation: Date?
    @objc let annotPub: String?
    @objc let parapheurName: String
    let delegueName: String?
    // let signatureInfo:String?,
    let delegateur: String?
    @objc let actionDemandee: String
    let id: String
    let isCurrent: Bool
    // let signatureEtape:Bool


    // <editor-fold desc="Json methods">

    enum CodingKeys: String, CodingKey {
        case approved
        case signataire
        case rejected
        case dateValidation
        case annotPub
        case parapheurName
        case delegueName
        // case signatureInfo
        case delegateur
        case actionDemandee
        case id
        case isCurrent
        // case signatureEtape
    }

    public required init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)

        approved = try values.decodeIfPresent(Bool.self, forKey: .approved) ?? false
        signataire = try values.decodeIfPresent(String.self, forKey: .signataire)
        rejected = try values.decodeIfPresent(Bool.self, forKey: .rejected) ?? false
        dateValidation = try values.decodeIfPresent(Date.self, forKey: .dateValidation)
        annotPub = try values.decodeIfPresent(String.self, forKey: .annotPub)
        parapheurName = try values.decodeIfPresent(String.self, forKey: .parapheurName) ?? ""
        delegueName = try values.decodeIfPresent(String.self, forKey: .delegueName)
        // signatureInfo = try values.decodeIfPresent(String.self, forKey: .signatureInfo)
        delegateur = try values.decodeIfPresent(String.self, forKey: .delegateur)
        actionDemandee = try values.decodeIfPresent(String.self, forKey: .actionDemandee) ?? "VISA"
        id = try values.decodeIfPresent(String.self, forKey: .id) ?? ""
        isCurrent = try values.decodeIfPresent(Bool.self, forKey: .isCurrent) ?? false
        // signatureEtape = try values.decodeIfPresent(String.self, forKey: .signatureEtape) ?? false
    }

    // </editor-fold desc="Json methods">

}
