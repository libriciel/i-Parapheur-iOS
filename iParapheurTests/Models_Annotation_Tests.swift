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
import os
@testable import iParapheur


class Models_Annotation_Tests: XCTestCase {


    func testEncodeFull() {

        let annotation = Annotation(currentPage: 99)!
        annotation.identifier = "a2cdc8f6-d39f-4a4a-8d68-ee50b42c0a2f"
        annotation.author = "Administrator Admin"
        annotation.fillColor = "undefined"
        annotation.penColor = "undefined"
        annotation.isSecretary = true
        //StringsUtils.serializeAnnotationDate(date: annotation.date), "2018-03-15T17:22:19Z")
        annotation.text = "plop"
        annotation.type = "rect"
        annotation.date = Date(timeIntervalSince1970: 1546344000)
        annotation.rect = CGRect(x: 15, y: 30, width: 150, height: 300)

        let jsonEncoder = JSONEncoder()
        jsonEncoder.outputFormatting = .prettyPrinted
        let annotationJson = try! jsonEncoder.encode(annotation)
        let annotationString = String(data: annotationJson, encoding: .utf8)!

        XCTAssertEqual(annotationString, """
                                         {
                                           "author" : "Administrator Admin",
                                           "id" : "a2cdc8f6-d39f-4a4a-8d68-ee50b42c0a2f",
                                           "date" : "2019-01-01T13:00:00",
                                           "uuid" : "a2cdc8f6-d39f-4a4a-8d68-ee50b42c0a2f",
                                           "rect" : {
                                             "topLeft" : {
                                               "x" : 15,
                                               "y" : 30
                                             },
                                             "bottomRight" : {
                                               "x" : 165,
                                               "y" : 330
                                             }
                                           },
                                           "type" : "rect",
                                           "text" : "plop",
                                           "page" : 99
                                         }
                                         """)
    }


    func testDecodeFull() {

        let annotationJsonString = """
                                       {
                                           "author": "Administrator Admin",
                                           "date": "2018-03-15T17:22:19Z",
                                           "fillColor": "undefined",
                                           "id": "a2cdc8f6-d39f-4a4a-8d68-ee50b42c0a2f",
                                           "penColor": "undefined",
                                           "rect": {
                                               "bottomRight": {
                                                   "x": "127.5",
                                                   "y": "140.5"
                                               },
                                               "topLeft": {
                                                   "x": 10,
                                                   "y": 15
                                               }
                                           },
                                           "secretaire": true,
                                           "text": "plop",
                                           "type": "rect"
                                       }
                                   """
        let annotationJsonData = annotationJsonString.data(using: .utf8)!

        let jsonDecoder = JSONDecoder()
        let annotation = try! jsonDecoder.decode(Annotation.self,
                                                 from: annotationJsonData)

        // Checks

        XCTAssertNotNil(annotation)

        XCTAssertEqual(annotation.identifier, "a2cdc8f6-d39f-4a4a-8d68-ee50b42c0a2f")
        XCTAssertEqual(annotation.author, "Administrator Admin")
        XCTAssertEqual(annotation.fillColor, "undefined")
        XCTAssertEqual(annotation.penColor, "undefined")
        XCTAssertEqual(annotation.isSecretary, true)
        XCTAssertEqual(StringsUtils.serializeAnnotationDate(date: annotation.date), "2018-03-15T17:22:19Z")
        XCTAssertEqual(annotation.text, "plop")
        XCTAssertEqual(annotation.type, "rect")

        XCTAssertEqual(annotation.rect.width, 117.5, accuracy: 0.1)
        XCTAssertEqual(annotation.rect.height, 125.5, accuracy: 0.1)
        XCTAssertEqual(annotation.rect.origin.x, 10, accuracy: 0.1)
        XCTAssertEqual(annotation.rect.origin.y, 15, accuracy: 0.1)
    }

}

