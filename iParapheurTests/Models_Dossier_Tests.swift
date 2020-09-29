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

import XCTest
@testable import iParapheur


class Models_Dossier_Tests: XCTestCase {


    func testDecodeFull() {

        let getDossiersJsonString = """
        [
            {
                "emitby": "Maire",
                "creator": "Administrator Admin",
                "pendingFile": 0,
                "includeAnnexes": true,
                "isRead": true,
                "sousType": "Document",
                "isSent": true,
                "isXemEnabled": true,
                "title": "Test Pades 04",
                "type": "Signature PADES",
                "banetteName": "Dossiers à traiter",
                "skipped": 15,
                "isSignPapier": true,
                "actionDemandee": "SIGNATURE",
                "protocol": "aucun",
                "total": 15,
                "dateEmission": 1527518906257,
                "hasRead": true,
                "canAdd": true,
                "documentsPrincipaux": [{
                    "name": "IP-DOC-manuel_administration_avancee.pdf",
                    "id": "5003c38a-b547-4f99-a706-1baffaf8c0c5"
                }],
                "id": "daa73d4d-5582-4375-a911-bb17a2bd9542",
                "locked": true,
                "actions": ["ENREGISTRER", "EMAIL", "SIGNATURE"],
                "bureauName": "Maire",
                "visibility": "PUBLIC",
                "status": "en_cours",
                "nomTdT": "S2LOW",
                "xPathSignature": "//Bordereau",
                "readingMandatory": true
            }, {
                "id": "daa73d4d-5582-4375-a911-bb17a2bd9565"
            }
        ]
        """

        let getDossiersJsonData = getDossiersJsonString.data(using: .utf8)!

        let jsonDecoder = JSONDecoder()
        let dossiers = try? jsonDecoder.decode([Dossier].self,
                                               from: getDossiersJsonData)

        // Checks

        XCTAssertNotNil(dossiers)
        XCTAssertEqual(dossiers!.count, 2)

        //

        XCTAssertNotNil(dossiers![0])

        XCTAssertEqual(dossiers![0].identifier, "daa73d4d-5582-4375-a911-bb17a2bd9542")
        XCTAssertEqual(dossiers![0].title, "Test Pades 04")
        XCTAssertEqual(dossiers![0].bureauName, "Maire")
        XCTAssertEqual(dossiers![0].banetteName, "Dossiers à traiter")
        XCTAssertEqual(dossiers![0].visibility, "PUBLIC")
        XCTAssertEqual(dossiers![0].status, "en_cours")

        XCTAssertEqual(dossiers![0].type, "Signature PADES")
        XCTAssertEqual(dossiers![0].subType, "Document")
        XCTAssertEqual(dossiers![0].protocole, "aucun")
        XCTAssertEqual(dossiers![0].nomTdT, "S2LOW")
        XCTAssertEqual(dossiers![0].xPathSignature, "//Bordereau")

        XCTAssertEqual(dossiers![0].actionDemandee, .sign)
        XCTAssertEqual(dossiers![0].actions, [.save, .mail, .sign])
        XCTAssertEqual(dossiers![0].documents, [])
        XCTAssertTrue(dossiers![0].acteursVariables.isEmpty)
        // XCTAssertTrue(dossiers![0].metadatas.isEmpty)
        XCTAssertEqual(dossiers![0].emitDate!.timeIntervalSince1970, 1527518906)
        XCTAssertNil(dossiers![0].limitDate)

        XCTAssertTrue(dossiers![0].hasRead)
        XCTAssertTrue(dossiers![0].includeAnnexes)
        XCTAssertTrue(dossiers![0].isRead)
        XCTAssertTrue(dossiers![0].isSent)
        XCTAssertTrue(dossiers![0].canAdd)
        XCTAssertTrue(dossiers![0].isLocked)
        XCTAssertTrue(dossiers![0].isSignPapier)
        XCTAssertTrue(dossiers![0].isXemEnabled)
        XCTAssertTrue(dossiers![0].isReadingMandatory)

        //

        XCTAssertNotNil(dossiers![1])

        XCTAssertEqual(dossiers![1].identifier, "daa73d4d-5582-4375-a911-bb17a2bd9565")
        XCTAssertEqual(dossiers![1].title, "(vide)")
        XCTAssertEqual(dossiers![1].bureauName, "(vide)")
        XCTAssertEqual(dossiers![1].banetteName, "")
        XCTAssertEqual(dossiers![1].visibility, "")
        XCTAssertEqual(dossiers![1].status, "")

        XCTAssertEqual(dossiers![1].type, "")
        XCTAssertEqual(dossiers![1].subType, "")
        XCTAssertEqual(dossiers![1].protocole, "")
        XCTAssertEqual(dossiers![1].nomTdT, "")
        XCTAssertEqual(dossiers![1].xPathSignature, "")

        XCTAssertEqual(dossiers![1].actionDemandee, .visa)
        XCTAssertEqual(dossiers![1].actions, [.visa, .sign])
        XCTAssertEqual(dossiers![1].documents, [])
        XCTAssertTrue(dossiers![1].acteursVariables.isEmpty)
        // XCTAssertTrue(dossiers![1].metadatas.isEmpty)
        XCTAssertNil(dossiers![1].emitDate)
        XCTAssertNil(dossiers![1].limitDate)

        XCTAssertFalse(dossiers![1].hasRead)
        XCTAssertFalse(dossiers![1].includeAnnexes)
        XCTAssertFalse(dossiers![1].isRead)
        XCTAssertFalse(dossiers![1].isSent)
        XCTAssertFalse(dossiers![1].canAdd)
        XCTAssertFalse(dossiers![1].isLocked)
        XCTAssertFalse(dossiers![1].isSignPapier)
        XCTAssertFalse(dossiers![1].isXemEnabled)
        XCTAssertFalse(dossiers![1].isReadingMandatory)
    }

}
