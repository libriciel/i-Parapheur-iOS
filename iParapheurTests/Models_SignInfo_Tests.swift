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


class Models_SignInfo_Tests: XCTestCase {

    func testDecodeFromJsonFull() {

        let getSignInfoJsonString = """
            {
                "signatureInformations" : {
                    "pesid":"test",
                    "hash":"3a922b5c63bd40021439dcbfe432e87cb4ee9d25",
                    "pespolicydesc":"Politique de Signature de l'Agent",
                    "pescountryname":"France",
                    "pespostalcode":"34000",
                    "format":"XADES-env",
                    "pesspuri":"http://www.s2low.org/PolitiqueSignature-Agent",
                    "pesencoding":"UTF-8",
                    "pesclaimedrole":"Pastell",
                    "pespolicyid":"urn:oid:1.2.250.1.5.3.1.1.10",
                    "pespolicyhash":"G4CqRa9R5c9Yg+dzMH3gbEc4Kqo=",
                    "p7s":null,
                    "pescity":"Montpellier" 
                }
            }
        """
        let getSignInfoJsonData = getSignInfoJsonString.data(using: .utf8)!
        let jsonDecoder = JSONDecoder()
		let signInfoDict = try? jsonDecoder.decode([String: SignInfoLegacy].self,
                                                   from: getSignInfoJsonData)
		
        XCTAssertNotNil(signInfoDict)
        XCTAssertEqual(signInfoDict!.keys.count, 1)
        let signInfo = signInfoDict!["signatureInformations"]
        XCTAssertNotNil(signInfo)
		
        XCTAssertEqual(signInfo!.pesIds.count, 1)
        XCTAssertEqual(signInfo!.pesIds[0], "test")
        XCTAssertEqual(signInfo!.hashesToSign.count, 1)
        XCTAssertEqual(signInfo!.hashesToSign[0], "3a922b5c63bd40021439dcbfe432e87cb4ee9d25")
        XCTAssertEqual(signInfo!.pesPolicyDesc, "Politique de Signature de l'Agent")
        XCTAssertEqual(signInfo!.pesCountryName, "France")
        XCTAssertEqual(signInfo!.pesPostalCode, "34000")
        XCTAssertEqual(signInfo!.format, "XADES-env")
        XCTAssertEqual(signInfo!.pesSpuri, "http://www.s2low.org/PolitiqueSignature-Agent")
        XCTAssertEqual(signInfo!.pesEncoding, "UTF-8")
        XCTAssertEqual(signInfo!.pesClaimedRole, "Pastell")
        XCTAssertEqual(signInfo!.pesPolicyId, "urn:oid:1.2.250.1.5.3.1.1.10")
        XCTAssertEqual(signInfo!.pesPolicyHash, "G4CqRa9R5c9Yg+dzMH3gbEc4Kqo=")
        XCTAssertNil(signInfo!.p7s)
        XCTAssertEqual(signInfo!.pesCity, "Montpellier")
    }


    func testDecodeFromJsonMulti() {

        let getSignInfoJsonString = """
            {
                "signatureInformations": {
                    "pesid":"ID20081042008-04-2901,ID20081052008-05-0501,ID20081062008-05-0501,ID20081072008-05-0501,ID20081082008-05-0501,ID20081092008-05-0501",
                    "pespolicydesc":"Politique de Signature de l'Agent",
                    "hash":"dffc6fc6cc0fcc4c4a148feeaf733d12e56b87eb,b347ef7371f145501db54ec01f77bd99cf97e5fd,218cb5a0284e92f8cf314b9984bfb7251031ff8f,68ae1ace827b73f5a0fab468fe2899309e97adab,1078bd1d2dec63416ec6077ebe300e5003960ba4,bc14c8e63c6bf76a9085bd4b994e64915408b77c",
                    "pescountryname":"France",
                    "format":"XADES-env",
                    "pespostalcode":"34000",
                    "pesencoding":"ISO-8859-1",
                    "pesspuri":"http://www.s2low.org/PolitiqueSignature-Agent",
                    "pesclaimedrole":"Maire",
                    "pespolicyhash":"G4CqRa9R5c9Yg+dzMH3gbEc4Kqo=",
                    "pespolicyid":"urn:oid:1.2.250.1.5.3.1.1.10",
                    "p7s":null,
                    "pescity":"Montpellier" 
                }
            }
        """
        let getSignInfoJsonData = getSignInfoJsonString.data(using: .utf8)!
        let jsonDecoder = JSONDecoder()
		let signInfoDict = try? jsonDecoder.decode([String: SignInfoLegacy].self,
                                                   from: getSignInfoJsonData)

        XCTAssertNotNil(signInfoDict)
        XCTAssertEqual(signInfoDict!.keys.count, 1)
        let signInfo = signInfoDict!["signatureInformations"]
        XCTAssertNotNil(signInfo)

        XCTAssertEqual(signInfo!.pesIds.count, 6)
        XCTAssertEqual(signInfo!.pesIds[0], "ID20081042008-04-2901")
        XCTAssertEqual(signInfo!.pesIds[1], "ID20081052008-05-0501")
        XCTAssertEqual(signInfo!.pesIds[2], "ID20081062008-05-0501")
        XCTAssertEqual(signInfo!.pesIds[3], "ID20081072008-05-0501")
        XCTAssertEqual(signInfo!.pesIds[4], "ID20081082008-05-0501")
        XCTAssertEqual(signInfo!.pesIds[5], "ID20081092008-05-0501")
        XCTAssertEqual(signInfo!.pesPolicyDesc, "Politique de Signature de l'Agent")
        XCTAssertEqual(signInfo!.pesCountryName, "France")
        XCTAssertEqual(signInfo!.pesPostalCode, "34000")
        XCTAssertEqual(signInfo!.hashesToSign.count, 6)
        XCTAssertEqual(signInfo!.hashesToSign[0], "dffc6fc6cc0fcc4c4a148feeaf733d12e56b87eb")
        XCTAssertEqual(signInfo!.hashesToSign[1], "b347ef7371f145501db54ec01f77bd99cf97e5fd")
        XCTAssertEqual(signInfo!.hashesToSign[2], "218cb5a0284e92f8cf314b9984bfb7251031ff8f")
        XCTAssertEqual(signInfo!.hashesToSign[3], "68ae1ace827b73f5a0fab468fe2899309e97adab")
        XCTAssertEqual(signInfo!.hashesToSign[4], "1078bd1d2dec63416ec6077ebe300e5003960ba4")
        XCTAssertEqual(signInfo!.hashesToSign[5], "bc14c8e63c6bf76a9085bd4b994e64915408b77c")
        XCTAssertEqual(signInfo!.format, "XADES-env")
        XCTAssertEqual(signInfo!.pesSpuri, "http://www.s2low.org/PolitiqueSignature-Agent")
        XCTAssertEqual(signInfo!.pesEncoding, "ISO-8859-1")
        XCTAssertEqual(signInfo!.pesClaimedRole, "Maire")
        XCTAssertEqual(signInfo!.pesPolicyId, "urn:oid:1.2.250.1.5.3.1.1.10")
        XCTAssertEqual(signInfo!.pesPolicyHash, "G4CqRa9R5c9Yg+dzMH3gbEc4Kqo=")
        XCTAssertNil(signInfo!.p7s)
        XCTAssertEqual(signInfo!.pesCity, "Montpellier")
    }


	func testDecodeFromJsonEmpty() {
		
		let getSignInfoJsonString = "{\"signatureInformations\" : {} }"
		let getSignInfoJsonData = getSignInfoJsonString.data(using: .utf8)!
		let jsonDecoder = JSONDecoder()
		let signInfoDict = try? jsonDecoder.decode([String: SignInfoLegacy].self,
												   from: getSignInfoJsonData)
		
		XCTAssertNotNil(signInfoDict)
		XCTAssertEqual(signInfoDict!.keys.count, 1)
		let signInfo = signInfoDict!["signatureInformations"]
		XCTAssertNotNil(signInfo)

        XCTAssertEqual(signInfo!.pesIds.count, 0)
		XCTAssertEqual(signInfo!.hashesToSign.count, 0)
		XCTAssertNil(signInfo!.pesPolicyDesc)
		XCTAssertNil(signInfo!.pesCountryName)
		XCTAssertNil(signInfo!.pesPostalCode)
		XCTAssertTrue(signInfo!.hashesToSign.isEmpty)
		XCTAssertEqual("unknown", signInfo!.format)
		XCTAssertNil(signInfo!.pesSpuri)
		XCTAssertNil(signInfo!.pesEncoding)
		XCTAssertNil(signInfo!.pesClaimedRole)
		XCTAssertNil(signInfo!.pesPolicyId)
		XCTAssertNil(signInfo!.pesPolicyHash)
		XCTAssertNil(signInfo!.p7s)
		XCTAssertNil(signInfo!.pesCity)
	}
	
}
