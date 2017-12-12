/*
 * Copyright 2012-2017, Libriciel SCOP.
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


class CircuitTests: XCTestCase {


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


    func testFail() {

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
