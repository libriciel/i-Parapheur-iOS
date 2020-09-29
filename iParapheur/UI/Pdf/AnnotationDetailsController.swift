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

import UIKit
import os


@objc protocol AnnotationDetailsControllerDelegate: class {

    func onAnnotationDeleted(annotation: Annotation)

    func onAnnotationChanged(annotation: Annotation)

    func onAnnotationPopupDismissed()

}


class AnnotationDetailsController: UIViewController {


    public static let segue = "annotationDetails"

    @IBOutlet weak var authorTextField: UITextField!
    @IBOutlet weak var dateTextField: UITextField!
    @IBOutlet weak var mainTextView: UITextView!

    weak var delegate: AnnotationDetailsControllerDelegate?
    var currentAnnotation: Annotation?
    var currentFolder: Dossier?
    var currentDocument: Document?
    var restClient: RestClient?


    // <editor-fold desc="LifeCycle"> MARK: - LifeCycle


    override func viewDidLoad() {
        super.viewDidLoad()
        os_log("View loaded : AnnotationDetailsController", type: .debug)

        // UITextView border like UITextField

        mainTextView.layer.cornerRadius = 5
        mainTextView.layer.borderColor = UIColor.gray.withAlphaComponent(0.5).cgColor
        mainTextView.layer.borderWidth = 0.5
        mainTextView.clipsToBounds = true

        // Populate annotation data

        guard let annotation = currentAnnotation else { return }

        authorTextField.text = annotation.author
        dateTextField.text = StringsUtils.prettyPrint(date: annotation.date)
        mainTextView.text = annotation.text
    }


    // </editor-fold desc="LifeCycle">


    // <editor-fold desc="UI listeners"> MARK: - UI listeners


    @IBAction func onCancelButtonClicked(_ sender: Any) {
        delegate?.onAnnotationPopupDismissed()
        dismiss(animated: true)
    }


    @IBAction func onDeleteButtonClicked(_ sender: Any) {

        guard let folderId = currentFolder?.identifier,
              let documentId = currentDocument?.identifier,
              let annotation = currentAnnotation else { return }

        restClient?.deleteAnnotation(annotationId: annotation.identifier,
                                     folderId: folderId,
                                     documentId: documentId,
                                     onResponse: {
                                         self.delegate?.onAnnotationDeleted(annotation: annotation)
                                         self.dismiss(animated: true)
                                     },
                                     onError: {
                                         (error: Error) in
                                         ViewUtils.logError(message: error.localizedDescription as NSString,
                                                            title: "Impossible de supprimer l'annotation")
                                     }
        )
    }


    @IBAction func onSaveButtonClicked(_ sender: Any) {

        guard let folderId = currentFolder?.identifier,
              let documentId = currentDocument?.identifier,
              let annotation = currentAnnotation else { return }

        annotation.text = mainTextView.text

        restClient?.updateAnnotation(annotation,
                                     folderId: folderId,
                                     documentId: documentId,
                                     responseCallback: {
                                         self.delegate?.onAnnotationChanged(annotation: annotation)
                                         self.delegate?.onAnnotationPopupDismissed()
                                         self.dismiss(animated: true)
                                     },
                                     errorCallback: { (error: Error) in
                                         ViewUtils.logError(message: error.localizedDescription as NSString,
                                                            title: "Impossible de mettre à jour l'annotation")
                                     })
    }


    // </editor-fold desc="UI listeners">

}
