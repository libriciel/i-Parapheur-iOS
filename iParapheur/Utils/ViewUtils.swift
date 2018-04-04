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

import Foundation
import SwiftMessages


@objc class ViewUtils: NSObject {


    @objc class func isConnectedToDemoAccount() -> Bool {

        let preferences = UserDefaults.standard
        let selectedId = preferences.object(forKey: Account.PreferencesKeySelectedAccount) as? String

        return Account.DemoId == selectedId
    }

    /**
     * Here's the trick : VFR on Android rasterizes its PDF at 72dpi.
     * Ghostscript on the server rasterize at 150dpi, and takes that as a root scale.
     * Every Annotation has a pixel-coordinates based on that 150dpi, on the server.
     * We need to translate it from 150 to 72dpi, by default.
     * <p/>
     * Not by default : The server-dpi is an open parameter, in the alfresco-global.properties file...
     * So we can't hardcode the old "150 dpi", we have to let an open parameter too, to allow any density coordinates.
     * <p/>
     * Maybe some day, we'll want some crazy 300dpi on tablets, that's why we don't want to hardcode the new "72 dpi" one.
     */
    @objc class func translateDpi(rect: CGRect,
                                  oldDpi: Int,
                                  newDpi: Int) -> CGRect {

        return CGRect(x: rect.origin.x * CGFloat(newDpi) / CGFloat(oldDpi),
                      y: rect.origin.y * CGFloat(newDpi) / CGFloat(oldDpi),
                      width: rect.size.width * CGFloat(newDpi) / CGFloat(oldDpi),
                      height: rect.size.height * CGFloat(newDpi) / CGFloat(oldDpi))
    }


    // MARK: - Logs

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


    // MARK: - Private Methods

    class func logMessage(title: NSString?,
                          subtitle: NSString,
                          messageType: Theme) {

        // Call back to main queue
        SwiftMessages.show {

            let view = MessageView.viewFromNib(layout: .cardView)
            view.button!.isHidden = true

            view.configureTheme(messageType)
            view.configureDropShadow()
            view.configureContent(title: (title == nil ? subtitle : title!) as String,
                                  body: (title == nil ? "" : subtitle as String))

            return view
        }
    }

}
