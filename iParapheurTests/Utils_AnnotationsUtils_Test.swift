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
