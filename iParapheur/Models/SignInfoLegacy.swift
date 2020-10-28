/*
 * Copyright 2012-2019, Libriciel SCOP.
 *
 * contact@libriciel.coop
 *
 * This software is a computer program whose purpose is to manage and sign
 * digital documents on an authorized iParapheur.
 *
 * This software is governed by the CeCILL license under French law and
 * abiding by the rules of distribution of free software.  You can  use,
 * modify and/ or redistribute the software under the terms of the CeCILL
 * license as circulated by CEA, CNRS and INRIA at the following URL
 * "http://www.cecill.info".
 *
 * As a counterpart to the access to the source code and  rights to copy,
 * modify and redistribute granted by the license, users are provided only
 * with a limited warranty  and the software's author,  the holder of the
 * economic rights,  and the successive licensors  have only  limited
 * liability.
 *
 * In this respect, the user's attention is drawn to the risks associated
 * with loading,  using,  modifying and/or developing or reproducing the
 * software by the user in light of its specific status of free software,
 * that may mean  that it is complicated to manipulate,  and  that  also
 * therefore means  that it is reserved for developers  and  experienced
 * professionals having in-depth computer knowledge. Users are therefore
 * encouraged to load and test the software's suitability as regards their
 * requirements in conditions enabling the security of their systems and/or
 * data to be ensured and,  more generally, to use and operate it in the
 * same conditions as regards security.
 *
 * The fact that you are presently reading this means that you have had
 * knowledge of the CeCILL license and that you accept its terms.
 */

import Foundation
import CoreData


public class SignInfoLegacy: NSObject, Decodable {

    let format: String
    let hashesToSign: [Data]
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


    public init(format: String, hashesToSign: [Data]) {
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
            hashesToSign = hashesString
                    .components(separatedBy: ",")
                    .map({ CryptoUtils.data(hex: $0) })
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
