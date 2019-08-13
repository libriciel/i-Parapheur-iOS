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
