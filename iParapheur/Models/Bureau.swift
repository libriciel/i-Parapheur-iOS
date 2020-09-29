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
