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
