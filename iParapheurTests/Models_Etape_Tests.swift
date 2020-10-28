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


class Models_Etape_Tests: XCTestCase {


    func testDecodeFull() {

        let etapeJsonString = """
            {
                "approved":true,
                "signataire":"Administrator Admin",
                "rejected":false,
                "dateValidation":1512039050475,
                "annotPub":"",
                "parapheurName":"Administrateur titre",
                "delegueName":null,
                "signatureInfo":{},
                "delegateur":null,
                "actionDemandee":"VISA",
                "id":"fde86987-7328-4b88-8c18-b850dce3c683",
                "isCurrent":false,
                "signatureEtape":null
            }
        """
        let etapeJsonData = etapeJsonString.data(using: .utf8)!

        let jsonDecoder = JSONDecoder()
        jsonDecoder.dateDecodingStrategy = .millisecondsSince1970
        let etape = try? jsonDecoder.decode(Etape.self,
                                            from: etapeJsonData)

        // Checks

        XCTAssertNotNil(etape)

        XCTAssertEqual(etape!.approved, true)
        XCTAssertEqual(etape!.signataire, "Administrator Admin")
        XCTAssertEqual(etape!.rejected, false)
        XCTAssertEqual(etape!.dateValidation?.description, "2017-11-30 10:50:50 +0000")
        XCTAssertEqual(etape!.annotPub, "")
        XCTAssertEqual(etape!.parapheurName, "Administrateur titre")
        XCTAssertNil(etape!.delegueName)
        // XCTAssertEqual(etape?.signatureInfo, "")
        XCTAssertNil(etape!.delegateur)
        XCTAssertEqual(etape!.actionDemandee, "VISA")
        XCTAssertEqual(etape!.id, "fde86987-7328-4b88-8c18-b850dce3c683")
        XCTAssertEqual(etape!.isCurrent, false)
        // XCTAssertEqual(etape?.signatureEtape, false)
    }


    func testDecodeEmpty() {

        let etapeJsonString = "{}"
        let etapeJsonData = etapeJsonString.data(using: .utf8)!

        let jsonDecoder = JSONDecoder()
        jsonDecoder.dateDecodingStrategy = .millisecondsSince1970
        let etape = try? jsonDecoder.decode(Etape.self,
                                            from: etapeJsonData)

        // Checks

        XCTAssertNotNil(etape)

        XCTAssertEqual(etape!.approved, false)
        XCTAssertEqual(etape!.signataire, nil)
        XCTAssertEqual(etape!.rejected, false)
        XCTAssertNil(etape!.dateValidation)
        XCTAssertEqual(etape!.annotPub, nil)
        XCTAssertEqual(etape!.parapheurName, "")
        XCTAssertNil(etape!.delegueName)
        // XCTAssertEqual(etape?.signatureInfo, "")
        XCTAssertNil(etape!.delegateur)
        XCTAssertEqual(etape!.actionDemandee, "VISA")
        XCTAssertEqual(etape!.id, "")
        XCTAssertEqual(etape!.isCurrent, false)
        // XCTAssertEqual(etape?.signatureEtape, false)
    }


    func testDecodeFail() {

        let etapeJsonString = "{{{"
        let etapeJsonData = etapeJsonString.data(using: .utf8)!

        let jsonDecoder = JSONDecoder()
        jsonDecoder.dateDecodingStrategy = .millisecondsSince1970
        let etape = try? jsonDecoder.decode(Etape.self,
                                            from: etapeJsonData)

        // Checks

        XCTAssertNil(etape)
    }

}

