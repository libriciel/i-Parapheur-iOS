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

class FolderListCell: UITableViewCell {

    static let cellIdentifier = "FolderListCell"

    @IBOutlet var titleLabel: UILabel!
    @IBOutlet var typologyLabel: UILabel!
    @IBOutlet var limitDateLabel: UILabel!
    @IBOutlet var dot: UIImageView!
    @IBOutlet var checkboxHandlerView: UIView!
    @IBOutlet var checkOnImage: UIImageView!
    @IBOutlet var checkOffImage: UIImageView!

}