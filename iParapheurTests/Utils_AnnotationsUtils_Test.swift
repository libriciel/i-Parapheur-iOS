/*
 * Copyright 2012-2017, Libriciel SCOP.
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


class Utils_AnnotationsUtils_Tests: XCTestCase {
    
    func testParseApi4() {
        let value = """
            [
                {
                    "4ff4408c-dafc-4b13-9fce-509bca4232d3": {}
                },
                {
                    "4ff4408c-dafc-4b13-9fce-509bca4232d3": {
                        "0":
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
                    "4ff4408c-dafc-4b13-9fce-509bca4232d3": {}
                }
            ]
        """
        
        let parsedAnnotations = AnnotationsUtils.parseApi4(string: value)
        XCTAssertTrue(parsedAnnotations.count > 0)
        XCTAssertEqual(parsedAnnotations[0].identifier, "a2cdc8f6-d39f-4a4a-8d68-ee50b42c0a2f")
    }
    
}
