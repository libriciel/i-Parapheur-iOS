/*
 * Copyright 2012-2019, Libriciel SCOP.
 *
 * contact@libriciel.coop
 *
 * This software is a computer program whose purpose is to manage and sign
 * digital documxents on an authorized iParapheur.
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
