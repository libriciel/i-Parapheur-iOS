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


class Models_ParapheurType_Tests: XCTestCase {


    func testDecodeFull() {

        let getTypesJsonString = """
        [
            {
                "sousTypes": ["Conges Annuels", "RTT - Recup.", "Conge exceptionnel"],
                "id": "Ddes CONGES"
            }, {
                "sousTypes": ["Actes PKCS7"],
                "id": "ACTES BIS"
            }, {
                "sousTypes": [],
                "id": "MARCHES PUBLICS"
            },{
            }
        ]
        """

        let getTypesJsonData = getTypesJsonString.data(using: .utf8)!

        let jsonDecoder = JSONDecoder()
        let types = try? jsonDecoder.decode([ParapheurType].self,
                                            from: getTypesJsonData)

        // Checks

        XCTAssertNotNil(types)
        XCTAssertEqual(types!.count, 4)
        XCTAssertNotNil(types![0])
        XCTAssertNotNil(types![1])
        XCTAssertNotNil(types![2])

        XCTAssertEqual(types![0].name, "Ddes CONGES")
        XCTAssertEqual(types![0].subTypes.count, 3)
        XCTAssertEqual(types![0].subTypes[0], "Conges Annuels")
        XCTAssertEqual(types![0].subTypes[1], "RTT - Recup.")
        XCTAssertEqual(types![0].subTypes[2], "Conge exceptionnel")

        XCTAssertEqual(types![1].name, "ACTES BIS")
        XCTAssertEqual(types![1].subTypes.count, 1)
        XCTAssertEqual(types![1].subTypes[0], "Actes PKCS7")

        XCTAssertEqual(types![2].name, "MARCHES PUBLICS")
        XCTAssertNotNil(types![2].subTypes)
        XCTAssertEqual(types![2].subTypes.count, 0)

        XCTAssertEqual(types![3].name, "(aucun nom)")
        XCTAssertNotNil(types![3].subTypes)
        XCTAssertEqual(types![3].subTypes.count, 0)
    }

}
