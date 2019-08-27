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

    let identifier: String
    let title: String?
    let bureauName: String?
    let banetteName: String?
    let visibility: String?
    let status: String?

    let type: String
    let subType: String
    let protocole: String?
    let nomTdT: String?
    let xPathSignature: String?

    let actionDemandee: Action
    var actions: [Action]
    let documents: [Document]
    let acteursVariables: [String]
    // TODO let metadatas: [String: Any]
    let emitDate: Date?
    let limitDate: Date?

    let hasRead: Bool
    let includeAnnexes: Bool
    let isRead: Bool
    let isSent: Bool
    let canAdd: Bool
    let isLocked: Bool
    var isSignPapier: Bool
    let isXemEnabled: Bool
    let isReadingMandatory: Bool
    var isDelegue: Bool


    // <editor-fold desc="Json methods"> MARK: - Json methods


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


    public init(identifier: String, action: Action, type: String, subType: String) {
        self.identifier = identifier
        self.actionDemandee = action
        self.actions = [action]
        self.type = type
        self.subType = subType

        title = nil
        bureauName = nil
        banetteName = nil
        visibility = nil
        status = nil
        protocole = nil
        nomTdT = nil
        xPathSignature = nil
        documents = []
        acteursVariables = []
        emitDate = nil
        limitDate = nil
        hasRead = false
        includeAnnexes = false
        isRead = false
        isSent = false
        canAdd = false
        isLocked = false
        isSignPapier = false
        isXemEnabled = false
        isReadingMandatory = false
        isDelegue = false
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

        actionDemandee = try values.decodeIfPresent(Action.self, forKey: .actionDemandee) ?? .visa
        actions = try values.decodeIfPresent([Action].self, forKey: .actions) ?? []
        documents = try values.decodeIfPresent([Document].self, forKey: .documents) ?? []
        acteursVariables = try values.decodeIfPresent([String].self, forKey: .acteursVariables) ?? []
        // TODO metadatas = try values.decodeIfPresent([String: Any].self, forKey: .metadatas) ?? [:]

        if var emitDateInt = try? values.decodeIfPresent(Int.self, forKey: .emitDate) {
            emitDateInt /= 1000
            emitDate = Date(timeIntervalSince1970: TimeInterval(emitDateInt))
        }
        else {
            emitDate = nil
        }

        if var limitDateInt = try? values.decodeIfPresent(Int.self, forKey: .limitDate) {
            limitDateInt /= 1000
            limitDate = Date(timeIntervalSince1970: TimeInterval(limitDateInt))
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

        if !(actions.contains(actionDemandee)) {
            actions.append(actionDemandee)
        }

        if actions.contains(.sign) {
            actions = actions.filter { $0 != .visa }
        }

        if actions.contains(.visa) {
            actions.append(.sign)
        }
    }


    // </editor-fold desc="Json methods">


    // <editor-fold desc="Static utils"> MARK: - Static utils

    /**
        Returns the main negative {@link Action} available, by coherent priority.
    */
    static func getPositiveAction(folders: [Dossier]) -> Action? {
        var possibleActions: [Action] = [.visa, .sign] // , "TDT", "MAILSEC", "ARCHIVER"]

        for folder in folders {
            possibleActions = possibleActions.filter { folder.actions.contains($0) }
        }

        return possibleActions.first
    }

    /**
        Returns the main negative {@link Action} available, by coherent priority.
    */
    static func getNegativeAction(folders: [Dossier]) -> Action? {
        var possibleActions: [Action] = [.reject]

        for folder in folders {
            possibleActions = possibleActions.filter { folder.actions.contains($0) }
        }

        return possibleActions.first
    }


    class func getLocalFileUrl(dossierId: String,
                               documentName: String) throws -> URL? {

        // Source folder

        var documentsDirectoryUrl = try FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
                .appendingPathComponent("dossiers", isDirectory: true)
                .appendingPathComponent(dossierId, isDirectory: true)

        try FileManager.default.createDirectory(at: documentsDirectoryUrl, withIntermediateDirectories: true)

        // File name

        var fileName = documentName.replacingOccurrences(of: " ", with: "_")
        fileName = String(format: "%@.bin", fileName)

        documentsDirectoryUrl = documentsDirectoryUrl.appendingPathComponent(fileName)
        return documentsDirectoryUrl
    }


    // </editor-fold desc="Static utils">

}
