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


class Bureau: NSObject, Decodable {

    let identifier: String
    @objc let name: String
    let collectivite: String?
    let desc: String?
    @objc let nodeRef: String?
    let shortName: String?
    // let image: String?
    // let habilitation: [String: Bool?]

    let enPreparation: Int
    @objc let enRetard: Int
    let aArchiver: Int
    @objc let aTraiter: Int
    @objc let dossiersDelegues: Int
    let retournes: Int

    let hasSecretaire: Bool
    // let showAVenir: Bool?
    let isSecretaire: Bool


    // <editor-fold desc="Json methods">

    enum CodingKeys: String, CodingKey {
        case name
        case collectivite
        case desc = "description"
        case nodeRef
        case shortName
        // case image
        case identifier = "id"
        // case habilitation
        case enPreparation = "en-preparation"
        case enRetard = "en-retard"
        case aArchiver = "a-archiver"
        case aTraiter = "a-traiter"
        case hasSecretaire
        // case showAVenir = "show_a_venir"
        case isSecretaire = "isSecretaire"
        case retournes
        case dossiersDelegues = "dossiers-delegues"
    }

    public required init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)

        nodeRef = try values.decodeIfPresent(String.self, forKey: .nodeRef)?
                .replacingOccurrences(of: "workspace://SpacesStore/", with: "", options: .literal)

        identifier = try values.decodeIfPresent(String.self, forKey: .identifier) ?? ""
        name = try values.decodeIfPresent(String.self, forKey: .name) ?? "(aucun nom)"
        collectivite = try values.decodeIfPresent(String.self, forKey: .collectivite)
        desc = try values.decodeIfPresent(String.self, forKey: .desc)
        shortName = try values.decodeIfPresent(String.self, forKey: .shortName)
        // image = try values.decodeIfPresent(String.self, forKey: .image)

        enPreparation = try values.decodeIfPresent(Int.self, forKey: .enPreparation) ?? 0
        enRetard = try values.decodeIfPresent(Int.self, forKey: .enRetard) ?? 0
        aArchiver = try values.decodeIfPresent(Int.self, forKey: .aArchiver) ?? 0
        aTraiter = try values.decodeIfPresent(Int.self, forKey: .aTraiter) ?? 0
        dossiersDelegues = try values.decodeIfPresent(Int.self, forKey: .dossiersDelegues) ?? 0
        retournes = try values.decodeIfPresent(Int.self, forKey: .retournes) ?? 0

        hasSecretaire = try values.decodeIfPresent(Bool.self, forKey: .hasSecretaire) ?? false
        // showAVenir = try values.decodeIfPresent(Bool.self, forKey: .showAVenir) // ?? false
        isSecretaire = try values.decodeIfPresent(Bool.self, forKey: .isSecretaire) ?? false
    }

    // </editor-fold desc="Json methods">

}
