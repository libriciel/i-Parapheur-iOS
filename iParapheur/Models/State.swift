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


enum State: String {

    case draft = "en-preparation"
    case toDo = "a-traiter"
    case workflowEnded = "a-archiver"
    case refused = "retournes"
    case pending = "en-cours"
    case incoming = "a-venir"
    case retrievable = "recuperables"
    case late = "en-retard"
    case done = "traites"
    case delegated = "dossiers-delegues"
    case allStates = "no-corbeille"
    case all = "no-bureau"

}
