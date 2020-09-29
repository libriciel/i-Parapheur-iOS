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
