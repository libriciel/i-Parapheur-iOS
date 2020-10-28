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


class Models_Action_Tests: XCTestCase {


    func testCodable() {

        let jsonString = """
                         [
                           "SIGNATURE",
                           "REJET",
                           "VISA",
                           "SECRETARIAT",
                           "REMORD",
                           "AVIS_COMPLEMENTAIRE",
                           "TRANSFERT_SIGNATURE",
                           "AJOUT_SIGNATURE",
                           "EMAIL",
                           "ENREGISTRER",
                           "SUPPRESSION",
                           "JOURNAL",
                           "MAILSEC",
                           "TDT",
                           "TDT_ACTES",
                           "TDT_HELIOS",
                           "TRANSFERT_ACTION",
                           "GET_ATTEST",
                           "RAZ",
                           "EDITION",
                           "ENCHAINER_CIRCUIT",
                           "ARCHIVER"
                         ]
                         """

        let jsonDecoder = JSONDecoder()
        let actionList = try! jsonDecoder.decode([Action].self, from: jsonString.data(using: .utf8)!)

        let expectedArray: [Action] = [.sign, .reject, .visa, .secretariat, .remorse, .secondOpinion,
                                       .signatureTransfer, .addSignature, .mail, .save, .suppress,
                                       .journal, .secureMail, .tdt, .tdtActes, .tdtHelios, .transfer,
                                       .getAttest, .reset, .edit, .chainWorkflow, .archive]
        XCTAssertEqual(actionList, expectedArray)

        let jsonEncoder = JSONEncoder()
        jsonEncoder.outputFormatting = .prettyPrinted
        let newJsonData = try! jsonEncoder.encode(actionList)
        let newJsonString = String(data: newJsonData, encoding: .utf8)!

        XCTAssertEqual(jsonString, newJsonString)
    }


    func testCodable_fail() {

        let jsonString = """
                         ["NOPE, NOT A REAL ACTION"]
                         """

        let jsonDecoder = JSONDecoder()
        let actionList = try! jsonDecoder.decode([Action].self, from: jsonString.data(using: .utf8)!)

        let expectedArray: [Action] = [.unknown]
        XCTAssertEqual(actionList, expectedArray)

        let jsonEncoder = JSONEncoder()
        jsonEncoder.outputFormatting = .prettyPrinted
        do {
            _ = try jsonEncoder.encode(actionList)
        } catch let error {
            XCTAssertTrue(error is RuntimeError)
        }
    }


    func testPrettyPrint() {
        XCTAssertEqual(Action.prettyPrint(.visa), "Viser")
        XCTAssertEqual(Action.prettyPrint(.sign), "Signer")
        XCTAssertEqual(Action.prettyPrint(.reject), "Rejeter")
        XCTAssertEqual(Action.prettyPrint(.unknown), "Action inconnue")
    }

}
