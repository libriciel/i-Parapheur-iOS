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


class Models_Bureau_Tests: XCTestCase {

    func testDecodeFull() {

        let getBureauxJsonString = """
            [
                {
                    "hasSecretaire": false,
                    "collectivite": "Collectivité 01 \\"\\\\/%@&éè",
                    "description": null,
                    "en-preparation": 0,
                    "nodeRef": "workspace://SpacesStore/44abe93c-16d7-4e00-b561-f6d1b8b6c1d3",
                    "shortName": "C1",
                    "en-retard": 5,
                    "image": "",
                    "show_a_venir": null,
                    "habilitation": {
                         "traiter": true,
                         "secretariat": false,
                         "archivage": true,
                         "transmettre": true
                    },
                    "a-archiver": 27,
                    "a-traiter": 10,
                    "id": "id_01",
                    "isSecretaire": false,
                    "name": "Name 01 \\"/%@&éè",
                    "retournes": 13,
                    "dossiers-delegues": 59
                },
                {
                    "hasSecretaire": true,
                    "collectivite": "Collectivité 02 \\"/%@&éè",
                    "description": "Description 02 \\"/%@&éè",
                    "en-preparation": 1,
                    "nodeRef": "id_02",
                    "shortName": "C2",
                    "en-retard": 5,
                    "image": null,
                    "show_a_venir": null,
                    "habilitation": {
                        "traiter": null,
                        "secretariat": null,
                        "archivage": null,
                        "transmettre": null
                    },
                    "a-archiver": 33,
                    "isSecretaire": false,
                    "name": "Name 02 \\"%@&éè",
                    "retournes": 10,
                    "dossiers-delegues": 0
                }
            ]
        """
        let getBureauxJsonData = getBureauxJsonString.data(using: .utf8)!

        let jsonDecoder = JSONDecoder()
        let bureaux = try? jsonDecoder.decode([Bureau].self,
                                              from: getBureauxJsonData)

        // Checks

        XCTAssertNotNil(bureaux)
        XCTAssertEqual(bureaux!.count, 2)
        XCTAssertNotNil(bureaux![0])
        XCTAssertNotNil(bureaux![1])

        XCTAssertEqual(bureaux![0].hasSecretaire, false)
        XCTAssertEqual(bureaux![0].hasSecretaire, false)
        XCTAssertEqual(bureaux![0].nodeRef, "44abe93c-16d7-4e00-b561-f6d1b8b6c1d3")
        XCTAssertEqual(bureaux![0].identifier, "id_01")
        XCTAssertEqual(bureaux![0].name, "Name 01 \"/%@&éè")
        XCTAssertEqual(bureaux![0].collectivite, "Collectivité 01 \"\\/%@&éè")
        XCTAssertNil(bureaux![0].desc)
        XCTAssertEqual(bureaux![0].shortName, "C1")
        XCTAssertEqual(bureaux![0].enPreparation, 0)
        XCTAssertEqual(bureaux![0].enRetard, 5)
        XCTAssertEqual(bureaux![0].aTraiter, 10)
        XCTAssertEqual(bureaux![0].aArchiver, 27)
        XCTAssertEqual(bureaux![0].retournes, 13)
        // XCTAssertEqual(bureaux![0].syncDate, bureau01.SyncDate)
        // XCTAssertEqual(bureaux![0].parent, bureau01.Parent)
        // XCTAssertEqual(bureaux![0].childrenDossiers, bureau01.ChildrenDossiers)
        XCTAssertEqual(bureaux![0].dossiersDelegues, 59)

        XCTAssertEqual(bureaux![1].hasSecretaire, true)
        XCTAssertEqual(bureaux![1].nodeRef, "id_02")
        XCTAssertEqual(bureaux![1].identifier, "")
        XCTAssertEqual(bureaux![1].name, "Name 02 \"%@&éè")
        XCTAssertEqual(bureaux![1].collectivite, "Collectivité 02 \"/%@&éè")
        XCTAssertEqual(bureaux![1].desc, "Description 02 \"/%@&éè")
        XCTAssertEqual(bureaux![1].shortName, "C2")
        XCTAssertEqual(bureaux![1].enPreparation, 1)
        XCTAssertEqual(bureaux![1].enRetard, 5)
        XCTAssertEqual(bureaux![1].aTraiter, 0)
        XCTAssertEqual(bureaux![1].aArchiver, 33)
        XCTAssertEqual(bureaux![1].retournes, 10)
        // XCTAssertEqual(bureaux![1].syncDate, bureau02.SyncDate)
        // XCTAssertEqual(bureaux![1].parent, bureau02.Parent)
        // XCTAssertEqual(bureaux![1].childrenDossiers, bureau02.ChildrenDossiers)
        XCTAssertEqual(bureaux![1].dossiersDelegues, 0)
    }


    func testDecodeEmpty() {

        let bureauJsonString = "{}"
        let bureauJsonData = bureauJsonString.data(using: .utf8)!

        let jsonDecoder = JSONDecoder()
        let bureau = try? jsonDecoder.decode(Bureau.self,
                                             from: bureauJsonData)

        // Checks

        XCTAssertNotNil(bureau)

        XCTAssertEqual(bureau!.hasSecretaire, false)
        XCTAssertEqual(bureau!.isSecretaire, false)
        XCTAssertEqual(bureau!.identifier, "")
        XCTAssertNil(bureau!.nodeRef)
        XCTAssertEqual(bureau!.name, "(aucun nom)")
        XCTAssertNil(bureau!.shortName)
        XCTAssertEqual(bureau!.enPreparation, 0)
        XCTAssertEqual(bureau!.enRetard, 0)
        XCTAssertEqual(bureau!.aTraiter, 0)
        XCTAssertEqual(bureau!.aArchiver, 0)
        XCTAssertEqual(bureau!.retournes, 0)
        XCTAssertEqual(bureau!.dossiersDelegues, 0)
    }


    func testDecodeFail() {

        let getBureauxJsonString = "{{{"
        let getBureauxJsonData = getBureauxJsonString.data(using: .utf8)!

        let jsonDecoder = JSONDecoder()
        let bureaux = try? jsonDecoder.decode([Bureau].self,
                                              from: getBureauxJsonData)

        // Checks

        XCTAssertNil(bureaux)
    }
}
