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

import Foundation


class ActionToPerform {

    let folder: Dossier
    let action: Action
    var signInfo: SignInfo?
    var remoteHasher: RemoteHasher?
    var isDone = false
    var error: Error?


    init(folder: Dossier, action: Action) {
        self.folder = folder

        var realAction = action
        if (action == .sign) && (folder.actionDemandee == .visa) { realAction = .visa }
        if (action == .sign) && folder.isSignPapier { realAction = .visa }

        self.action = realAction
    }


    func generateRemoteHasher(restClient: RestClient, certificate: Certificate?) {

        guard let currentCertificate = certificate,
              let currentSignInfo = signInfo else {
            self.isDone = true
            self.error = RuntimeError("Erreur à la génération de la signature")
            return
        }

        do {
            self.remoteHasher = try CryptoUtils.generateHasherWrappers(signInfo: currentSignInfo,
                                                                       dossier: folder,
                                                                       certificate: currentCertificate,
                                                                       restClient: restClient)
        } catch {
            self.isDone = true
            self.error = RuntimeError("Erreur à la génération de la signature")
        }
    }

}
