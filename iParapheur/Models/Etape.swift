/*
 * Copyright 2012-2017, Libriciel SCOP.
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


struct Etape: Decodable {


	let approved: Bool
	let signataire: String?
	let rejected: Bool
	let dateValidation:Date?
	let annotPub:String?
	let parapheurName:String
	let delegueName:String?
    // let signatureInfo:String?,
	let delegateur:String?
	let actionDemandee:String
	let id:String
	let isCurrent:Bool
    // let signatureEtape:Bool


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
	
	init(from decoder: Decoder) throws {
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
}
