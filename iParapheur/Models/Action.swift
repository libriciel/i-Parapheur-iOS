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
    case securizedMail
    case archive
    case tdtHelios
    case tdtActes
    case tdt
    case actionTransfert
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
            case "MAILSEC": self = .securizedMail
            case "TDT": self = .tdt
            case "TDT_ACTES": self = .tdtActes
            case "TDT_HELIOS": self = .tdtHelios
            case "TRANSFERT_ACTION": self = .actionTransfert
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
            case .securizedMail: try container.encode("MAILSEC")
            case .tdt: try container.encode("TDT")
            case .tdtActes: try container.encode("TDT_ACTES")
            case .tdtHelios: try container.encode("TDT_HELIOS")
            case .actionTransfert: try container.encode("TRANSFERT_ACTION")
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
