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


class Models_Circuit_Tests: XCTestCase {


    func testDecodeFull() {

        let getCircuitJsonString = """
        {
        	"circuit":
        	{
        		"etapes": [
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
        				"isCurrent":false,"signatureEtape":null
        			},
        			{
        				"approved":false,
        				"signataire":null,
        				"rejected":false,
        				"dateValidation":null,
        				"annotPub":null,
        				"parapheurName":"Administrateur titre",
        				"delegueName":null,
        				"signatureInfo":{},
        				"delegateur":null,
        				"actionDemandee":"SIGNATURE",
        				"id":"84d5119c-42dc-457b-9d22-3863a46fb581",
        				"isCurrent":true,"signatureEtape":null
        			}
        		],
        		"protocol":"HELIOS",
        		"annotPriv":"",
        		"isDigitalSignatureMandatory":true,
        		"isMultiDocument":false,
        		"hasSelectionScript":false,
        		"sigFormat":"XAdES/enveloped" }
        }
        """
        let getCircuitJsonData = getCircuitJsonString.data(using: .utf8)!

        let jsonDecoder = JSONDecoder()
        jsonDecoder.dateDecodingStrategy = .millisecondsSince1970
        let circuitWrapper = try? jsonDecoder.decode([String: Circuit].self,
                                                     from: getCircuitJsonData)

        // Checks

        XCTAssertNotNil(circuitWrapper)
        let circuit = circuitWrapper!["circuit"]
        XCTAssertNotNil(circuit)

        XCTAssertEqual(circuit!.etapes.count, 2)
        XCTAssertNotNil(circuit!.etapes[0])
        XCTAssertNotNil(circuit!.etapes[1])

        XCTAssertEqual(circuit!.signatureProtocol, "HELIOS")
        XCTAssertEqual(circuit!.annotPriv, "")
        XCTAssertEqual(circuit!.isDigitalSignatureMandatory, true)
        XCTAssertEqual(circuit!.isMultiDocument, false)
        XCTAssertEqual(circuit!.hasSelectionScript, false)
        XCTAssertEqual(circuit!.sigFormat, "XAdES/enveloped")
    }


    func testDecodeEmpty() {

        let getCircuitJsonString = "{\"circuit\":{}}"
        let getCircuitJsonData = getCircuitJsonString.data(using: .utf8)!

        let jsonDecoder = JSONDecoder()
        jsonDecoder.dateDecodingStrategy = .millisecondsSince1970
        let circuitWrapper = try? jsonDecoder.decode([String: Circuit].self,
                                                     from: getCircuitJsonData)

        // Checks

        XCTAssertNotNil(circuitWrapper)
        let circuit = circuitWrapper!["circuit"]
        XCTAssertNotNil(circuit)

        XCTAssertEqual(circuit!.etapes.count, 0)
        XCTAssertEqual(circuit!.signatureProtocol, nil)
        XCTAssertEqual(circuit!.annotPriv, nil)
        XCTAssertEqual(circuit!.isDigitalSignatureMandatory, false)
        XCTAssertEqual(circuit!.isMultiDocument, false)
        XCTAssertEqual(circuit!.hasSelectionScript, false)
        XCTAssertEqual(circuit!.sigFormat, nil)
    }


    func testDecodeFail() {

        let getCircuitJsonString = "{{{"
        let getCircuitJsonData = getCircuitJsonString.data(using: .utf8)!

        let jsonDecoder = JSONDecoder()
        jsonDecoder.dateDecodingStrategy = .millisecondsSince1970
        let circuitWrapper = try? jsonDecoder.decode(Circuit.self,
                                                     from: getCircuitJsonData)

        // Checks

        XCTAssertNil(circuitWrapper)
    }
}
