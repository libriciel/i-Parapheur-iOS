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
