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
