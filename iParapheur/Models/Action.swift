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


enum Action: Codable {

    case visa
    case sign
    case reject
    case secretariat
    case secondOpinion
    case signatureTransfer
    case addSignature
    case mail
    case save
    case suppress
    case journal
    case remorse
    case secureMail
    case archive
    case tdtHelios
    case tdtActes
    case tdt
    case transfer
    case getAttest
    case reset
    case edit
    case chainWorkflow
    case unknown


    // <editor-fold desc="JSON methods"> MARK: - JSON methods


    init(from decoder: Decoder) throws {

        let label = try decoder.singleValueContainer().decode(String.self)
        switch label {

            case "SIGNATURE": self = .sign
            case "REJET": self = .reject
            case "VISA": self = .visa
            case "SECRETARIAT": self = .secretariat
            case "REMORD": self = .remorse
            case "AVIS_COMPLEMENTAIRE": self = .secondOpinion
            case "TRANSFERT_SIGNATURE": self = .signatureTransfer
            case "AJOUT_SIGNATURE": self = .addSignature
            case "EMAIL": self = .mail
            case "ENREGISTRER": self = .save
            case "SUPPRESSION": self = .suppress
            case "JOURNAL": self = .journal
            case "MAILSEC": self = .secureMail
            case "TDT": self = .tdt
            case "TDT_ACTES": self = .tdtActes
            case "TDT_HELIOS": self = .tdtHelios
            case "TRANSFERT_ACTION": self = .transfer
            case "GET_ATTEST": self = .getAttest
            case "RAZ": self = .reset
            case "EDITION": self = .edit
            case "ENCHAINER_CIRCUIT": self = .chainWorkflow
            case "ARCHIVER": self = .archive

            default: self = .unknown
        }
    }


    func encode(to encoder: Encoder) throws {

        var container = encoder.singleValueContainer()
        switch self {

            case .sign: try container.encode("SIGNATURE")
            case .reject: try container.encode("REJET")
            case .visa: try container.encode("VISA")
            case .secretariat: try container.encode("SECRETARIAT")
            case .remorse: try container.encode("REMORD")
            case .secondOpinion: try container.encode("AVIS_COMPLEMENTAIRE")
            case .signatureTransfer: try container.encode("TRANSFERT_SIGNATURE")
            case .addSignature: try container.encode("AJOUT_SIGNATURE")
            case .mail: try container.encode("EMAIL")
            case .save: try container.encode("ENREGISTRER")
            case .suppress: try container.encode("SUPPRESSION")
            case .journal: try container.encode("JOURNAL")
            case .secureMail: try container.encode("MAILSEC")
            case .tdt: try container.encode("TDT")
            case .tdtActes: try container.encode("TDT_ACTES")
            case .tdtHelios: try container.encode("TDT_HELIOS")
            case .transfer: try container.encode("TRANSFERT_ACTION")
            case .getAttest: try container.encode("GET_ATTEST")
            case .reset: try container.encode("RAZ")
            case .edit: try container.encode("EDITION")
            case .chainWorkflow: try container.encode("ENCHAINER_CIRCUIT")
            case .archive: try container.encode("ARCHIVER")

            case .unknown: throw RuntimeError("Action inconnue")
        }
    }


    // </editor-fold desc="JSON methods">


    static func prettyPrint(_ action: Action) -> String {

        switch action {

            case .visa: return "Viser"
            case .sign: return "Signer"
            case .reject: return "Rejeter"

            default: return "Action inconnue"
        }
    }

}
