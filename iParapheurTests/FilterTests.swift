/*
 * Copyright 2012-2016, Adullact-Projet.
 *
 * contact@adullact-projet.coop
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


class FilterTests: XCTestCase {
	
	
//	func testGloss() {
//
//		var inputJson: Dictionary<String, Any> = [:]
//
//		// Empty case
//
//		let emptyFilter = Filter(json: inputJson)
//		XCTAssertEqual(emptyFilter!.state, State.A_TRAITER)
//
//		// Full case
//
//		inputJson["id"] = "test_id"
//		inputJson["name"] = "test_name"
//		inputJson["title"] = "test_title"
//		inputJson["typeList"] = ["test_type_list_1", "test_type_list_2"]
//		inputJson["subTypeList"] = ["test_subtype_list_1", "test_subtype_list_2"]
//		inputJson["state"] = State.EN_COURS
//		inputJson["beginDate"] = Date(timeIntervalSince1970: 200)
//		inputJson["endDate"] = Date(timeIntervalSince1970: 400)
//
//        let fullFilter = Filter(json: inputJson)
//		print("fullFilter \(fullFilter?.state)")
//        let fullFilterDeserialized = fullFilter!.toJSON()
//		print("fullFilterDeserialized \(fullFilterDeserialized!["state"])")
//
//        XCTAssertEqual(fullFilterDeserialized!["id"] as! String, "test_id")
//        XCTAssertEqual(fullFilterDeserialized!["name"] as! String, "test_name")
//        XCTAssertEqual(fullFilterDeserialized!["title"] as! String, "test_title")
//        XCTAssertEqual(fullFilterDeserialized!["typeList"] as! [String], ["test_type_list_1", "test_type_list_2"])
//        XCTAssertEqual(fullFilterDeserialized!["subTypeList"] as! [String], ["test_subtype_list_1", "test_subtype_list_2"])
//		XCTAssertEqual(fullFilterDeserialized!["state"] as! String, State.EN_COURS.rawValue)
//        XCTAssertEqual(fullFilterDeserialized!["beginDate"] as! Date, Date(timeIntervalSince1970: 200))
//        XCTAssertEqual(fullFilterDeserialized!["endDate"] as! Date, Date(timeIntervalSince1970: 400))
//    }
	
}
