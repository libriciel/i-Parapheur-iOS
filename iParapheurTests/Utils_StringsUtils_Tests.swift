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

class Utils_StringsUtils_Tests: XCTestCase {


    func testGetMessage() {
        let errorBadServer = NSError(domain: "", code: -1011, userInfo: nil)
        let errorUnknown = NSError(domain: "Cause inconnue", code: 974399, userInfo: nil)
        let errorSsl = NSError(domain: "", code: -1204, userInfo: nil)
        let errorNotConnected = NSError(domain: "", code: -1009, userInfo: nil)
        let errorAuthenticationRequired = NSError(domain: "", code: -1013, userInfo: nil)
        let errorCannotFindHost = NSError(domain: "", code: -1003, userInfo: nil)
        let errorTimeOut = NSError(domain: "", code: -1001, userInfo: nil)

        XCTAssertEqual("Erreur d'authentification", StringsUtils.getMessage(error: errorBadServer))
        XCTAssertEqual("L’opération n’a pas pu s’achever. (Cause inconnue erreur 974399.)", StringsUtils.getMessage(error: errorUnknown))
        XCTAssertEqual("Le serveur n'est pas valide", StringsUtils.getMessage(error: errorSsl))
        XCTAssertEqual("La connexion Internet a été perdue.", StringsUtils.getMessage(error: errorNotConnected))
        XCTAssertEqual("Échec d'authentification", StringsUtils.getMessage(error: errorAuthenticationRequired))
        XCTAssertEqual("Le serveur est introuvable", StringsUtils.getMessage(error: errorCannotFindHost))
        XCTAssertEqual("Le serveur ne répond pas dans le délai imparti", StringsUtils.getMessage(error: errorTimeOut))
    }


    func testCleanupServerName() {
        XCTAssertEqual(StringsUtils.cleanupServerName(url: "truc.fr"), "truc.fr")
        XCTAssertEqual(StringsUtils.cleanupServerName(url: "m-truc.fr"), "truc.fr")
        XCTAssertEqual(StringsUtils.cleanupServerName(url: "m.truc.fr"), "truc.fr")
        XCTAssertEqual(StringsUtils.cleanupServerName(url: "M-truc.fr"), "truc.fr")
        XCTAssertEqual(StringsUtils.cleanupServerName(url: "http://truc.fr"), "truc.fr")
        XCTAssertEqual(StringsUtils.cleanupServerName(url: "http://m.truc.fr"), "truc.fr")
        XCTAssertEqual(StringsUtils.cleanupServerName(url: "http://M-TRUC.FR"), "TRUC.FR")
        XCTAssertEqual(StringsUtils.cleanupServerName(url: "http://m-truc.fr"), "truc.fr")
        XCTAssertEqual(StringsUtils.cleanupServerName(url: "https://truc.fr"), "truc.fr")
        XCTAssertEqual(StringsUtils.cleanupServerName(url: "https://m.truc.fr"), "truc.fr")
        XCTAssertEqual(StringsUtils.cleanupServerName(url: "https://M-TRUC.FR"), "TRUC.FR")
        XCTAssertEqual(StringsUtils.cleanupServerName(url: "https://m-truc.fr"), "truc.fr")
        XCTAssertEqual(StringsUtils.cleanupServerName(url: "https://m.truc-truc.m.truc.fr"), "truc-truc.m.truc.fr")
    }


    func testAnnotationDate() {

        let stringBefore = "2018-03-15T17:22:19Z"
        let date = StringsUtils.deserializeAnnotationDate(string: stringBefore)
        let stringAfter = StringsUtils.serializeAnnotationDate(date: date)

        XCTAssertNotNil(date)
        XCTAssertEqual(stringAfter, "2018-03-15T17:22:19Z")
    }


    func testTrim() {

        let plopString = "    p l o p     "
        XCTAssertEqual(StringsUtils.trim(string: plopString), "plop")

        let plopMultiline = """
                                     p
                                     l
                                     o
                                     p
                            """
        XCTAssertEqual(StringsUtils.trim(string: plopMultiline), "plop")
    }


    func testPrettyPrintDate() {

        let stringBefore = "2018-03-15T17:22:19Z"
        let date = StringsUtils.deserializeAnnotationDate(string: stringBefore)

        XCTAssertEqual(StringsUtils.prettyPrint(date: date), "le 15/03/2018 à 17h22")
    }


    func testSplit() {

        let stringShort = "12345"
        let stringLong = "1234567890123456789"

        let resultShort = StringsUtils.split(string: stringShort, length: 5)
        let resultLong = StringsUtils.split(string: stringLong, length: 5)

        XCTAssertEqual(resultShort, ["12345"])
        XCTAssertEqual(resultLong, ["12345", "67890", "12345", "6789"])
    }


    func testDecodeUrlString() {
        XCTAssertEqual(StringsUtils.decodeUrlString(encodedString: ""), "")
        XCTAssertEqual(StringsUtils.decodeUrlString(encodedString: "test%20with%20%28foo_bar%3Awhee%29"), "test with (foo_bar:whee)")
    }


    func testToDataList_ToBase64List() {

        let startList = ["dGVzdA==", "Zm9v", "YmFy"]
        let dataList = StringsUtils.toDataList(base64StringList: startList)

        XCTAssertEqual(dataList.count, 3)

        let base64List = StringsUtils.toBase64List(dataList: dataList)

        XCTAssertEqual(base64List[0], "dGVzdA==")
        XCTAssertEqual(base64List[1], "Zm9v")
        XCTAssertEqual(base64List[2], "YmFy")

        XCTAssertEqual(StringsUtils.toDataList(base64StringList: []), [])
    }

}
