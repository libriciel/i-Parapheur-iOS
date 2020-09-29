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
import PDFKit
import os


protocol PdfAnnotationEventsDelegate: class {

    func onAnnotationMoved(_ annotation: PDFAnnotation?)

    func onAnnotationSelected(_ annotation: PDFAnnotation?)

}


protocol PdfAnnotationGestureRecognizerDelegate: class {

    func pressBeganInCreateMode(_ location: CGPoint)

    func pressBeganInEditMode(pdfAnnotation: PDFAnnotation, insideHit: CGPoint, forceRedraw: Bool)

    func pressMoved(_ location: CGPoint, _ isLongPress: Bool)

    func pressEnded(_ location: CGPoint, _ isLongPress: Bool)

    func targetedAnnotation(_ location: CGPoint) -> (PDFAnnotation, CGPoint)?

    func getCurrentAnnotation() -> PDFAnnotation?

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
    weak var eventsDelegate: PdfAnnotationEventsDelegate?

    var isInEditAnnotationMode = false

    private var longPressTimer: Timer?
    private var doubleTapTimer: Timer?
    private var isLongPress = false


    // <editor-fold desc="UIGestureRecognizer"> MARK: - UIGestureRecognizer


    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {

        guard let touch = touches.first,
              let numberOfTouches = event?.allTouches?.count,
              numberOfTouches == 1 else {

            doubleTapTimerCancelled()
            longPressTimerCancelled()
            isLongPress = false
            state = .failed
            return
        }

        let location = touch.location(in: self.view)
        let targetedAnnotation = drawingDelegate?.targetedAnnotation(location)

        if (state == .changed) { // That was a missed double tap. Dismissing...
            doubleTapTimerCancelled()
            longPressTimerCancelled()
            isLongPress = false
            state = .failed
        }
        else if (isInEditAnnotationMode) {

            if (targetedAnnotation != nil) {
                drawingDelegate?.pressBeganInEditMode(pdfAnnotation: targetedAnnotation!.0, insideHit: targetedAnnotation!.1, forceRedraw: false)
                doubleTapTimerCancelled()
                longPressTimer = Timer.scheduledTimer(timeInterval: 0.4,
                                                      target: self,
                                                      selector: #selector(longPressTriggered),
                                                      userInfo: targetedAnnotation,
                                                      repeats: false)
            }
            else {
                drawingDelegate?.pressBeganInCreateMode(location)
                doubleTapTimerCancelled()
                longPressTimerCancelled()
            }

            state = .began
        }
        else if (targetedAnnotation != nil) {

            if (doubleTapTimer != nil) {
                doubleTapTriggered(annotation: targetedAnnotation!.0)
                state = .ended
            }
            else {
                doubleTapTimer = Timer.scheduledTimer(timeInterval: 0.5,
                                                      target: self,
                                                      selector: #selector(doubleTapTimerCancelled),
                                                      userInfo: nil,
                                                      repeats: false)
                state = .possible
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

        // Swipe inside an annotation

        if (state == .possible) {
            state = .failed
            return
        }

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
            let currentAnnotation = drawingDelegate?.getCurrentAnnotation()
            drawingDelegate?.pressEnded(location, isLongPress)

            isInEditAnnotationMode = false
            doubleTapTimerCancelled()
            state = .ended

            eventsDelegate?.onAnnotationMoved(currentAnnotation)
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


    // </editor-fold desc="UIGestureRecognizer">


    private func doubleTapTriggered(annotation: PDFAnnotation) {

        doubleTapTimerCancelled()
        longPressTimerCancelled()
        isLongPress = false

        eventsDelegate?.onAnnotationSelected(annotation)
    }


    @objc private func longPressTriggered(sender: Timer) {

        guard let annotation = (sender.userInfo as? (PDFAnnotation, CGPoint))?.0,
              let insideHit = (sender.userInfo as? (PDFAnnotation, CGPoint))?.1 else { return }

        longPressTimerCancelled()
        isLongPress = true

        drawingDelegate?.pressBeganInEditMode(pdfAnnotation: annotation, insideHit: insideHit, forceRedraw: true)
    }


    @objc private func doubleTapTimerCancelled() {
        doubleTapTimer?.invalidate()
        doubleTapTimer = nil
    }


    private func longPressTimerCancelled() {
        longPressTimer?.invalidate()
        longPressTimer = nil
    }

}
