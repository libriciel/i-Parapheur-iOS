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


class Models_Document_Tests: XCTestCase {


    func testDecodeFull() {

        let documentJsonString = """
        {
            "size": 740377,
            "visuelPdf": true,
            "isMainDocument": true,
            "pageCount": 20,
            "attestState": 3,
            "id": "5003c38a-b547-4f99-a706-1baffaf8c0c5",
            "name": "IP-DOC-manuel_administration_avancee.pdf",
            "canDelete": true,
            "isLocked": true
        }
        """

        let documentJsonData = documentJsonString.data(using: .utf8)!

        let jsonDecoder = JSONDecoder()
        let document = try? jsonDecoder.decode(Document.self,
                                               from: documentJsonData)

        // Checks

        XCTAssertNotNil(document)

        XCTAssertEqual(document!.identifier, "5003c38a-b547-4f99-a706-1baffaf8c0c5")
        XCTAssertEqual(document!.name, "IP-DOC-manuel_administration_avancee.pdf")

        XCTAssertEqual(document!.pageCount, 20)
        XCTAssertEqual(document!.attestState, 3)
        XCTAssertEqual(document!.size, 740377)

        XCTAssertTrue(document!.isPdfVisual)
        XCTAssertTrue(document!.isDeletable)
        XCTAssertTrue(document!.isLocked)
        XCTAssertTrue(document!.isDeletable)
    }


    func testDecodeEmpty() {

        let documentJsonString = "{}"

        let documentJsonData = documentJsonString.data(using: .utf8)!

        let jsonDecoder = JSONDecoder()
        let document = try? jsonDecoder.decode(Document.self,
                                               from: documentJsonData)

        // Checks

        XCTAssertNotNil(document)

        XCTAssertEqual(document!.identifier, "")
        XCTAssertEqual(document!.name, "(vide)")

        XCTAssertEqual(document!.pageCount, -1)
        XCTAssertEqual(document!.attestState, 0)
        XCTAssertEqual(document!.size, -1)

        XCTAssertFalse(document!.isPdfVisual)
        XCTAssertFalse(document!.isDeletable)
        XCTAssertFalse(document!.isLocked)
        XCTAssertFalse(document!.isDeletable)
    }

}
