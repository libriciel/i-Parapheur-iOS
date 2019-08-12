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

import Foundation
import PDFKit
import os


protocol PdfAnnotationGestureRecognizerDelegate: class {

    func pressBegan(_ location: CGPoint)

    func longPressBegan()

    func pressMoved(_ location: CGPoint, _ isLongPress: Bool)

    func pressEnded(_ location: CGPoint, _ isLongPress: Bool)

    func enterInEditMode(_ location: CGPoint) -> Bool

}

/**
    Largely taken from this tutorial :
    https://medium.com/@artempoluektov/ios-pdfkit-ink-annotations-tutorial-4ba19b474dce

    A Timer has been set to manage long presses.
    Cumulating multliple (long and regular) GestureRecognizers won't do anything good.
    Subclassing UILongPressGestureRecognizer neither, it won't trigger on quick moves.

    Managing an isLongPress boolean is way clearer, simpler.
 */
class PdfAnnotationGestureRecognizer: UIGestureRecognizer {


    weak var drawingDelegate: PdfAnnotationGestureRecognizerDelegate?
    var isInCreateAnnotationMode = false

    private var longPressTimer: Timer?
    private var doubleTapTimer: Timer?
    private var isLongPress = false


    // <editor-fold desc="UIGestureRecognizer"> MARK: - UIGestureRecognizer


    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {

        if let touch = touches.first,
           let numberOfTouches = event?.allTouches?.count,
           numberOfTouches == 1 {

            let location = touch.location(in: self.view)

            if (doubleTapTimer != nil) {
                doubleTapTriggered()
                state = .ended
            }
            else if (isInCreateAnnotationMode || (drawingDelegate?.enterInEditMode(location) ?? false)) {
                doubleTapTimer = Timer.scheduledTimer(timeInterval: 0.5, target: self, selector: #selector(singlePressTriggered), userInfo: location, repeats: false)
                state = .began
            }
            else {
                doubleTapTimerCancelled()
                longPressTimerCancelled()
                isLongPress = false
                state = .failed
            }
        }
        else {
            doubleTapTimerCancelled()
            longPressTimerCancelled()
            isLongPress = false
            state = .failed
        }
    }


    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {

        // If we're still waiting for a double tab, we can dismiss the timer,
        // and already considering a single press action
        doubleTapTimer?.fire()
        doubleTapTimerCancelled()

        longPressTimerCancelled()

        state = .changed

        guard let location = touches.first?.location(in: self.view) else { return }
        drawingDelegate?.pressMoved(location, isLongPress)
    }


    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {

        guard let location = touches.first?.location(in: self.view) else {
            state = .ended
            return
        }

        if (doubleTapTimer != nil) {
            // May be the end of the first tap, still waiting for a second one
            state = .changed
        }
        else {
            drawingDelegate?.pressEnded(location, isLongPress)

            isInCreateAnnotationMode = false
            doubleTapTimerCancelled()
            state = .ended
        }

        longPressTimerCancelled()
        isLongPress = false
    }


    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent) {
        doubleTapTimerCancelled()
        longPressTimerCancelled()
        isLongPress = false
        state = .failed
    }


    // </editor-fold desc="UIGestureRecognizer"> MARK: - UIGestureRecognizer


    @objc func singlePressTriggered() {
        guard let location = doubleTapTimer?.userInfo as? CGPoint else { return }
        doubleTapTimerCancelled()

        if (state == .changed) { // That was a missed double tap. Dismissing...
            state = .failed
        }
        else if (isInCreateAnnotationMode) {
            state = .began
            drawingDelegate?.pressBegan(location)
        }
        else if (drawingDelegate?.enterInEditMode(location) ?? false) {
            longPressTimer = Timer.scheduledTimer(timeInterval: 0.5, target: self, selector: #selector(longPressTriggered), userInfo: nil, repeats: false)
            state = .began
            drawingDelegate?.pressBegan(location)
        }
        else {
            state = .failed
        }
    }


    func doubleTapTriggered() {
        doubleTapTimerCancelled()
        longPressTimerCancelled()
        isLongPress = false
    }


    @objc func longPressTriggered() {
        isLongPress = true
        drawingDelegate?.longPressBegan()
    }


    private func doubleTapTimerCancelled() {
        doubleTapTimer?.invalidate()
        doubleTapTimer = nil
    }


    private func longPressTimerCancelled() {
        longPressTimer?.invalidate()
        longPressTimer = nil
    }

}
