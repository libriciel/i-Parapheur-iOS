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
import PDFKit
@testable import iParapheur


class RestClientMock: RestClient {


    override func getSignInfo(folder: Dossier,
                              bureau: NSString,
                              onResponse responseCallback: ((SignInfo) -> Void)?,
                              onError errorCallback: ((NSError) -> Void)?) {
        responseCallback?(SignInfo(format: "PES", hashesToSign: ["hashToSign_01_\(folder.identifier)", "hashToSign_02_\(folder.identifier)"]))
    }


    override func getDataToSign(remoteDocumentList: [RemoteDocument],
                                publicKeyBase64: String,
                                signatureFormat: String,
                                payload: [String: String],
                                onResponse responseCallback: ((DataToSign) -> Void)?,
                                onError errorCallback: ((Error) -> Void)?) {
        var dataToSign: [String] = []
        remoteDocumentList.forEach { dataToSign.append("dataToSign_\($0.id)") }
        responseCallback?(DataToSign(dataToSignBase64: dataToSign, signatureDateTime: 999, payload: payload))
    }

    override func signDossier(dossierId: String,
                              bureauId: String,
                              publicAnnotation: String?,
                              privateAnnotation: String?,
                              signature: String,
                              responseCallback: ((NSNumber) -> Void)?,
                              errorCallback: ((Error) -> Void)?) {
        errorCallback?(RuntimeError("Cancelled before final sign"))
    }
}


class UI_WorkflowDialogController_Tests: XCTestCase {


    func testSignature_emptyList() {

        let controller = WorkflowDialogController()
        controller.restClient = RestClientMock(baseUrl: "https://iparapaheur", login: "log", password: "pass")
        controller.actionsToPerform = []
        controller.currentDeskId = "desk_01"

//        controller.signature()
    }

}
