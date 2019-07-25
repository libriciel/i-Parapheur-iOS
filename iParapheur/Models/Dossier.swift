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


class Dossier: NSObject, Decodable {

    @objc let identifier: String
    @objc let title: String?
    let bureauName: String?
    let banetteName: String?
    let visibility: String?
    let status: String?

    @objc let type: String
    @objc let subType: String
    let protocole: String?
    let nomTdT: String?
    let xPathSignature: String?

    @objc let actionDemandee: String
    @objc var actions: Array<String>
    @objc let documents: [Document]
    let acteursVariables: [String]
    // TODO let metadatas: [String: Any]
    let emitDate: Date?
    @objc let limitDate: Date?

    let hasRead: Bool
    let includeAnnexes: Bool
    let isRead: Bool
    let isSent: Bool
    let canAdd: Bool
    @objc let isLocked: Bool
    @objc let isSignPapier: Bool
    let isXemEnabled: Bool
    let isReadingMandatory: Bool

    @objc var isDelegue: Bool


    // <editor-fold desc="Json methods">

    enum CodingKeys: String, CodingKey {

        case identifier = "id"
        case title
        case bureauName
        case banetteName
        case visibility
        case status

        case type
        case subType = "sousType"
        case protocole = "protocol"
        case nomTdT
        case xPathSignature

        case actionDemandee
        case actions
        case documents
        case acteursVariables
        case metadatas
        case emitDate = "dateEmission"
        case limitDate = "dateLimite"

        case hasRead
        case includeAnnexes
        case isRead
        case isSent
        case canAdd
        case isLocked = "locked"
        case isSignPapier
        case isXemEnabled
        case isReadingMandatory = "readingMandatory"
    }

    public required init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)

        identifier = try values.decodeIfPresent(String.self, forKey: .identifier) ?? ""
        title = try values.decodeIfPresent(String.self, forKey: .title) ?? "(vide)"
        bureauName = try values.decodeIfPresent(String.self, forKey: .bureauName) ?? "(vide)"
        banetteName = try values.decodeIfPresent(String.self, forKey: .banetteName) ?? ""
        visibility = try values.decodeIfPresent(String.self, forKey: .visibility) ?? ""
        status = try values.decodeIfPresent(String.self, forKey: .status) ?? ""

        type = try values.decodeIfPresent(String.self, forKey: .type) ?? ""
        subType = try values.decodeIfPresent(String.self, forKey: .subType) ?? ""
        protocole = try values.decodeIfPresent(String.self, forKey: .protocole) ?? ""
        nomTdT = try values.decodeIfPresent(String.self, forKey: .nomTdT) ?? ""
        xPathSignature = try values.decodeIfPresent(String.self, forKey: .xPathSignature) ?? ""

        actionDemandee = try values.decodeIfPresent(String.self, forKey: .actionDemandee) ?? "VISA"
        actions = try values.decodeIfPresent([String].self, forKey: .actions) ?? []
        documents = try values.decodeIfPresent([Document].self, forKey: .documents) ?? []
        acteursVariables = try values.decodeIfPresent([String].self, forKey: .acteursVariables) ?? []
        // TODO metadatas = try values.decodeIfPresent([String: Any].self, forKey: .metadatas) ?? [:]

        var emitDateInt = try values.decodeIfPresent(Int.self, forKey: .emitDate)
        if (emitDateInt != nil) {
            emitDateInt = emitDateInt! / 1000
            emitDate = Date(timeIntervalSince1970: TimeInterval(emitDateInt!))
        }
        else {
            emitDate = nil
        }

        var limitDateInt = try values.decodeIfPresent(Int.self, forKey: .limitDate)
        if (limitDateInt != nil) {
            limitDateInt = limitDateInt! / 1000
            limitDate = Date(timeIntervalSince1970: TimeInterval(limitDateInt!))
        }
        else {
            limitDate = nil
        }

        hasRead = try values.decodeIfPresent(Bool.self, forKey: .hasRead) ?? false
        includeAnnexes = try values.decodeIfPresent(Bool.self, forKey: .includeAnnexes) ?? false
        isRead = try values.decodeIfPresent(Bool.self, forKey: .isRead) ?? false
        isSent = try values.decodeIfPresent(Bool.self, forKey: .isSent) ?? false
        canAdd = try values.decodeIfPresent(Bool.self, forKey: .canAdd) ?? false
        isLocked = try values.decodeIfPresent(Bool.self, forKey: .isLocked) ?? false
        isSignPapier = try values.decodeIfPresent(Bool.self, forKey: .isSignPapier) ?? false
        isXemEnabled = try values.decodeIfPresent(Bool.self, forKey: .isXemEnabled) ?? false
        isReadingMandatory = try values.decodeIfPresent(Bool.self, forKey: .isReadingMandatory) ?? false

        // Small fixes

        isDelegue = false

        // Sometimes it happens
        if (!(actions.contains(actionDemandee))) {
            actions.append(actionDemandee)
        }
    }

    // </editor-fold desc="Json methods">


    // MARK: - Glossy

//    required init?(json: JSON) {
//        identifier = ("id" <~~ json) ?? ""
//        title = ("title" <~~ json) ?? "(vide)"
//        bureauName = ("bureauName" <~~ json) ?? "(vide)"
//        banetteName = ("banetteName" <~~ json) ?? ""
//        visibility = ("visibility" <~~ json) ?? ""
//        status = ("status" <~~ json) ?? ""
//
//        type = ("type" <~~ json) ?? ""
//        subType = ("sousType" <~~ json) ?? ""
//        protocole = ("protocole" <~~ json) ?? ""
//        nomTdT = ("nomTdT" <~~ json) ?? ""
//        xPathSignature = ("xPathSignature" <~~ json) ?? ""
//
//        actionDemandee = ("actionDemandee" <~~ json) ?? "VISA"
//        actions = ("actions" <~~ json) ?? []
//        documents = ("documents" <~~ json) ?? []
//        acteursVariables = ("acteursVariables" <~~ json) ?? []
//        metadatas = ("metadatas" <~~ json) ?? [:]
//        emitDate = ("dateEmission" <~~ json) ?? -1
//        limitDate = ("dateLimite" <~~ json) ?? 0
//
//        hasRead = ("hasRead" <~~ json) ?? false
//        includeAnnexes = ("includeAnnexes" <~~ json) ?? false
//        isRead = ("isRead" <~~ json) ?? false
//        isSent = ("isSent" <~~ json) ?? false
//        canAdd = ("canAdd" <~~ json) ?? false
//        isLocked = ("locked" <~~ json) ?? false
//        isSignPapier = ("isSignPapier" <~~ json) ?? false
//        isXemEnabled = ("isXemEnabled" <~~ json) ?? false
//        isReadingMandatory = ("readingMandatory" <~~ json) ?? false
//
//        isDelegue = false
//
//        // Sometimes it happens
//        if (!(actions.contains(actionDemandee))) {
//            actions.append(actionDemandee)
//        }
//    }
//
//    func toJSON() -> JSON? {
//        return nil /* Not used */
//    }


    // MARK: - Static utils

    /**
        Returns the main negative {@link Action} available, by coherent priority.
    */
    static func getPositiveAction(folders: [Dossier]) -> String? {

        var possibleActions = ["SIGNATURE", "VISA"] // , "TDT", "MAILSEC", "ARCHIVER"]

        for folder in folders {
            possibleActions = possibleActions.filter({ folder.actions.contains($0) })
        }

        return (possibleActions.count > 0) ? possibleActions[0] : nil
    }

    /**
        Returns the main negative {@link Action} available, by coherent priority.
    */
    @objc static func getNegativeAction(folders: [Dossier]) -> String? {

        var possibleActions = ["REJET"]

        for folder in folders {
            possibleActions = possibleActions.filter({ folder.actions.contains($0) })
        }

        return (possibleActions.count > 0) ? possibleActions[0] : nil
    }

    class func filterActions(dossierList: NSArray) -> [String] {

        var result: [String] = []

        // Compute values

        var hasVisa: Bool = true
        var hasSignature: Bool = true
        var hasOnlyVisa: Bool = true
        var hasRejet: Bool = true
        var hasTDT: Bool = true

        for dossierItem in dossierList {
            if let dossier = dossierItem as? Dossier {
                hasVisa = hasVisa && dossier.actions.contains("VISA")
                hasSignature = hasSignature && (dossier.actions.contains("SIGNATURE") || dossier.actions.contains("VISA"))
                hasOnlyVisa = hasOnlyVisa && !dossier.actions.contains("SIGNATURE")
                hasRejet = hasRejet && dossier.actions.contains("REJET")
                hasTDT = hasTDT && dossier.actions.contains("TDT")
            }
        }

        hasSignature = hasSignature && !hasOnlyVisa

        // Build result

        if (hasSignature) {
            result.append("SIGNATURE")
        }
        else if (hasVisa) {
            result.append("VISA")
        }

        if (hasRejet) {
            result.append("REJET")
        }

        if (hasTDT) {
            result.append("TDT")
        }

        return result
    }
}
