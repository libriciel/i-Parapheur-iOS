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
import PDFKit
@testable import iParapheur


class Utils_AnnotationsUtils_Tests: XCTestCase {


    func testParseApi4() {
        let value = """
                        [
                            {
                                "22222222-dafc-4b13-9fce-509bca4232d2": {}
                            },
                            {
                                "4ff4408c-dafc-4b13-9fce-509bca4232d3": {
                                    "8":
                                        [
                                            {
                                                "id": "a2cdc8f6-d39f-4a4a-8d68-ee50b42c0a2f",
                                                "secretaire": false,
                                                "type": "rect",
                                                "date": "2018-03-15T17:22:19Z",
                                                "author": "Administrator Admin",
                                                "penColor": "undefined",
                                                "text": "",
                                                "fillColor": "undefined",
                                                "rect": {
                                                    "topLeft": {
                                                        "x": 0,
                                                        "y": 0
                                                    },
                                                    "bottomRight": {
                                                        "x": 275.625,
                                                        "y": 307.8409090909091
                                                    }
                                                }
                                            }
                                        ],
                                    "1": []
                                }
                            },
                            {
                                "66666666-dafc-4b13-9fce-509bca4232d3": {}
                            }
                        ]
                    """

        let parsedAnnotations = AnnotationsUtils.parse(string: value)
        XCTAssertTrue(parsedAnnotations.count > 0)
        XCTAssertEqual(parsedAnnotations[0].identifier, "a2cdc8f6-d39f-4a4a-8d68-ee50b42c0a2f")
        XCTAssertEqual(parsedAnnotations[0].page, 8)
        XCTAssertEqual(parsedAnnotations[0].documentId, "4ff4408c-dafc-4b13-9fce-509bca4232d3")
    }


    func testParseApi3() {
        let value = """
                        [
                            {},
                            {
                                "5": [
                                    {
                                        "id": "9a23ddea-a835-40fc-8bf9-57b4c0569924",
                                        "secretaire": "false",
                                        "type": "rect",
                                        "date": "2018-03-30T11:45:11.912+02:00",
                                        "author": "Administrator admin",
                                        "penColor": "undefined",
                                        "text": "Test annotation 01",
                                        "fillColor": "undefined",
                                        "rect": {
                                            "topLeft": {
                                                "x": 133.73974208675264,
                                                "y": 108.98922949461475
                                            },
                                            "bottomRight": {
                                                "x": 495.70926143024616,
                                                "y": 357.4846727423364
                                            }
                                        }
                                    }
                                ]
                            },
                            {}
                        ]
                    """

        let parsedAnnotations = AnnotationsUtils.parse(string: value)
        XCTAssertTrue(parsedAnnotations.count > 0)
        XCTAssertEqual(parsedAnnotations[0].identifier, "9a23ddea-a835-40fc-8bf9-57b4c0569924")
        XCTAssertEqual(parsedAnnotations[0].page, 5)
        XCTAssertEqual(parsedAnnotations[0].documentId, nil)
    }


    func testTranslateToXXXAnnotation() {

        let annotation = Annotation(currentPage: 5)!
        annotation.text = "Text"
        annotation.identifier = "Id"
        annotation.author = "Author"
        annotation.fillColor = "red"
        annotation.date = Date(timeIntervalSince1970: 1546344000)

        let pdfAnnotation = AnnotationsUtils.toPdfAnnotation(annotation, pageHeight: 1080, pdfPage: PDFPage(image: UIImage())!)
        let parsedAnnotation = AnnotationsUtils.fromPdfAnnotation(pdfAnnotation, pageNumber: annotation.page, pageHeight: 1080)

        XCTAssertEqual(parsedAnnotation.text, "Text")
        XCTAssertEqual(parsedAnnotation.text, "Text")
        XCTAssertEqual(parsedAnnotation.author, "Author")
        XCTAssertEqual(parsedAnnotation.identifier, "Id")
        XCTAssertEqual(parsedAnnotation.page, 5)
        XCTAssertEqual(parsedAnnotation.date.timeIntervalSince1970, 1546344000)
    }

}
