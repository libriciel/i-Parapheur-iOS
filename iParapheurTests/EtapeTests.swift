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


class EtapeTests: XCTestCase {


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

}
