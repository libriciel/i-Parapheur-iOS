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
import SwiftMessages


class ViewUtils: NSObject {


    @objc class func isConnectedToDemoAccount() -> Bool {

        let preferences = UserDefaults.standard
        let selectedId = preferences.object(forKey: Account.preferenceKeySelectedAccount) as? String

        return Account.demoId == selectedId
    }

    /**
        Here's the trick : VFR on Android rasterizes its PDF at 72dpi.
        Ghostscript on the server rasterize at 150dpi, and takes that as a root scale.
        Every Annotation has a pixel-coordinates based on that 150dpi, on the server.
        We need to translate it from 150 to 72dpi, by default.

        Not by default : The server-dpi is an open parameter, in the alfresco-global.properties file...
        So we can't hardcode the old "150 dpi", we have to let an open parameter too, to allow any density coordinates.

        Maybe some day, we'll want some crazy 300dpi on tablets, that's why we don't want to hardcode the new "72 dpi" one.
    */
    @objc class func translateDpi(rect: CGRect,
                                  oldDpi: Int,
                                  newDpi: Int) -> CGRect {

        return CGRect(x: rect.origin.x * CGFloat(newDpi) / CGFloat(oldDpi),
                      y: rect.origin.y * CGFloat(newDpi) / CGFloat(oldDpi),
                      width: rect.size.width * CGFloat(newDpi) / CGFloat(oldDpi),
                      height: rect.size.height * CGFloat(newDpi) / CGFloat(oldDpi))
    }


    class func getImageName(action: String) -> String {

        switch (action) {
            case "REJET": return "ic_close_white_24dp"
            case "VISA": return "ic_done_white_24dp"
            default: return "ic_fiber_manual_record_white_18dp"
        }
    }


    // <editor-folds desc="Logs">


    @objc class func logError(message: NSString,
                              title: NSString?) {

        ViewUtils.logMessage(title: title,
                             subtitle: message,
                             messageType: .error)
    }


    @objc class func logSuccess(message: NSString,
                                title: NSString?) {

        ViewUtils.logMessage(title: title,
                             subtitle: message,
                             messageType: .success)
    }


    @objc class func logInfo(message: NSString,
                             title: NSString?) {

        ViewUtils.logMessage(title: title,
                             subtitle: message,
                             messageType: .info)
    }


    @objc class func logWarning(message: NSString,
                                title: NSString?) {

        ViewUtils.logMessage(title: title,
                             subtitle: message,
                             messageType: .warning)
    }


    class func logMessage(title: NSString?,
                          subtitle: NSString,
                          messageType: Theme) {
        logMessage(title: title, subtitle: subtitle, messageType: messageType, config: SwiftMessages.defaultConfig)
    }


    class func logMessage(title: NSString?,
                          subtitle: NSString,
                          messageType: Theme,
                          config: SwiftMessages.Config) {

        let view = MessageView.viewFromNib(layout: .cardView)
        view.button!.isHidden = true

        view.configureTheme(messageType)
        view.configureDropShadow()
        view.configureContent(title: (title == nil ? subtitle : title!) as String,
                              body: (title == nil ? "" : subtitle as String))

        // Call back to main queue
        SwiftMessages.show(config: config, view: view)
    }


    // </editor-folds desc="Logs">

}
