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
    var documents: [Document]
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
