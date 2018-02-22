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

class Utils_StringsUtils_Tests: XCTestCase {
    
    func testGetMessage() {
        let errorBadServer = NSError(domain: "", code: -1011, userInfo: nil)
        let errorUnknown = NSError(domain: "Cause inconnue", code: 974399, userInfo: nil)
        let errorSsl = NSError(domain: "", code: -1204, userInfo: nil)
        let errorNotConnected = NSError(domain: "", code: -1009, userInfo: nil)
        let errorAuthenticationRequired = NSError(domain: "", code: -1013, userInfo: nil)
        let errorCannotFindHost = NSError(domain: "", code: -1003, userInfo: nil)
        let errorTimeOut = NSError(domain: "", code: -1001, userInfo: nil)

        XCTAssertEqual("Erreur d'authentification", StringsUtils.getMessage(error: errorBadServer))
        XCTAssertEqual("L’opération n’a pas pu s’achever. (Cause inconnue erreur 974399.)", StringsUtils.getMessage(error: errorUnknown))
        XCTAssertEqual("Le serveur n'est pas valide", StringsUtils.getMessage(error: errorSsl))
        XCTAssertEqual("La connexion Internet a été perdue.", StringsUtils.getMessage(error: errorNotConnected))
        XCTAssertEqual("Échec d'authentification", StringsUtils.getMessage(error: errorAuthenticationRequired))
        XCTAssertEqual("Le serveur est introuvable", StringsUtils.getMessage(error: errorCannotFindHost))
        XCTAssertEqual("Le serveur ne répond pas dans le délai imparti", StringsUtils.getMessage(error: errorTimeOut))
    }
    
}