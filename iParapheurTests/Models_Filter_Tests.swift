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


class Models_Filter_Tests: XCTestCase {


    func testToJson() {

        // Prepare

//        let filter = NSEntityDescription.insertNewObject(forEntityName: Filter.EntityName,
//                                                         into: ModelsDataController.Context!) as! Filter
//        filter.id = "test_id"
//        filter.name = "test_name"
//        filter.title = "test_title"
//        filter.typeList = ["test_type_list_1", "test_type_list_2"] as [String]
//        filter.subTypeList = ["test_subtype_list_1", "test_subtype_list_2"] as [String]
//        filter.state = State.EN_COURS.rawValue
//        filter.beginDate = Date(timeIntervalSince1970: 200) as NSDate
//        filter.endDate = Date(timeIntervalSince1970: 400) as NSDate
//
//        // Test
//
//        let jsonEncoder = JSONEncoder()
//        jsonEncoder.dateEncodingStrategy = .iso8601
//
//        let jsonData = try! jsonEncoder.encode(filter)
//        let jsonString = String(data: jsonData, encoding: .utf8)
//
//        // TODO : Proper tests
//        XCTAssertNotNil(jsonString)
//        XCTAssertTrue(jsonString!.count > 50)
//
//        // Cleanup
//
//        ModelsDataController.Context!.delete(filter)
    }

}
