; The GIMP -- an image manipulation program
; Copyright (C) 1995 Spencer Kimball and Peter Mattis
;
; This program is free software; you can redistribute it and/or modify
; it under the terms of the GNU General Public License as published by
; the Free Software Foundation; either version 3 of the License, or
; (at your option) any later version.
; 
; This program is distributed in the hope that it will be useful,
; but WITHOUT ANY WARRANTY; without even the implied warranty of
; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
; GNU General Public License for more details.
; 
; You should have received a copy of the GNU General Public License
; along with this program; if not, write to the Free Software
; Foundation, Inc., 675 Mass Ave, Cambridge, MA 02139, USA.
; http://www.gnu.org/licenses/gpl-3.0.html
;
; Copyright (C) 2008 Samuel Albrecht <samuel_albrecht@web.de>
;
; Version 0.1 - Simulate a high quality photo like these from the National Geographic
;               Thanks to Martin Egger <martin.egger@gmx.net> for the shadow revovery and the sharpen script
;

(define (elsamuko-national-geographic aimg adraw shadowopacity
                                      sharpness screenopacity
                                      overlayopacity localcontrast
                                      screenmask)
  (let* ((img (car (gimp-drawable-get-image adraw)))
         (owidth (car (gimp-image-width img)))
         (oheight (car (gimp-image-height img)))
         (overlaylayer 0)
         (overlaylayer2 0)
         (screenlayer 0)
         (floatingsel 0)
         )
    
    ;init
    
    ;shadow recovery from here: http://registry.gimp.org/node/112
    (define (Eg-ShadowRecovery-Helper InImage InLayer InMethod InOpacity)
      (let* ((CopyLayer (car (gimp-layer-copy InLayer TRUE)))
             (ShadowLayer (car (gimp-layer-copy InLayer TRUE)))
             )
        ; Create new layer and add it to the image
        (gimp-image-add-layer InImage CopyLayer -1)
        (gimp-layer-set-mode CopyLayer ADDITION-MODE)
        (gimp-layer-set-opacity CopyLayer InOpacity)
        (gimp-image-add-layer InImage ShadowLayer -1)
        (gimp-desaturate ShadowLayer)
        (gimp-invert ShadowLayer)
        (let* ((CopyMask (car (gimp-layer-create-mask CopyLayer ADD-WHITE-MASK)))
               (ShadowMask (car (gimp-layer-create-mask ShadowLayer ADD-WHITE-MASK)))
               )
          (gimp-layer-add-mask CopyLayer CopyMask)
          (gimp-layer-add-mask ShadowLayer ShadowMask)
          (gimp-selection-all InImage)
          (gimp-edit-copy ShadowLayer)
          (gimp-floating-sel-anchor (car (gimp-edit-paste CopyMask TRUE)))
          (gimp-floating-sel-anchor (car (gimp-edit-paste ShadowMask TRUE)))
          )
        (gimp-layer-set-mode ShadowLayer OVERLAY-MODE)
        (gimp-layer-set-opacity ShadowLayer InOpacity)
        (if (= InMethod 0) (gimp-image-remove-layer InImage CopyLayer))
        ;Flatten the image
        (if (= InMethod 1) (gimp-image-merge-down InImage CopyLayer CLIP-TO-IMAGE))
        (set! InLayer (car(gimp-image-merge-down InImage ShadowLayer CLIP-TO-IMAGE)))
        )
      )
    
    ;smart sharpen from here: http://registry.gimp.org/node/108
    (define (Eg-SmartSharpen-Helper InImage InLayer InRadius InAmount
                                    InThreshold InRefocus InMatSize
                                    InRFRadius InGauss InCorrelation
                                    InNoise InEdge InBlur)
      (let* ((MaskImage (car (gimp-image-duplicate InImage)))
             (MaskLayer (cadr (gimp-image-get-layers MaskImage)))
             (OrigLayer (cadr (gimp-image-get-layers InImage)))
             (HSVImage (car (plug-in-decompose TRUE InImage InLayer "Value" TRUE)))
             (HSVLayer (cadr (gimp-image-get-layers HSVImage)))
             (SharpenLayer (car (gimp-layer-copy InLayer TRUE)))
             )
        (gimp-image-add-layer InImage SharpenLayer -1)
        (gimp-selection-all HSVImage)
        (gimp-edit-copy (aref HSVLayer 0))
        (gimp-image-delete HSVImage)
        (gimp-floating-sel-anchor (car (gimp-edit-paste SharpenLayer FALSE)))
        (gimp-layer-set-mode SharpenLayer VALUE-MODE)
        ;Find edges, Warpmode = Smear (1), Edgemode = Sobel (0)
        (plug-in-edge TRUE MaskImage (aref MaskLayer 0) InEdge 1 0)
        (gimp-levels-stretch (aref MaskLayer 0))
        (gimp-image-convert-grayscale MaskImage)
        (plug-in-gauss TRUE MaskImage (aref MaskLayer 0) InBlur InBlur TRUE)
        (let* ((SharpenChannel (car (gimp-layer-create-mask SharpenLayer ADD-WHITE-MASK)))
               )
          (gimp-layer-add-mask SharpenLayer SharpenChannel)
          (gimp-selection-all MaskImage)
          (gimp-edit-copy (aref MaskLayer 0))
          (gimp-floating-sel-anchor (car (gimp-edit-paste SharpenChannel FALSE)))
          (gimp-image-delete MaskImage)
          (cond			
            ((= InRefocus FALSE)(plug-in-unsharp-mask TRUE InImage SharpenLayer InRadius InAmount InThreshold))
            ((= InRefocus TRUE)(plug-in-refocus TRUE InImage SharpenLayer InMatSize InRFRadius InGauss InCorrelation InNoise))
            )
          (gimp-layer-set-opacity SharpenLayer 80)
          (gimp-layer-set-edit-mask SharpenLayer FALSE)
          )
        ;Flatten the image
        (set! InLayer (car(gimp-image-merge-down InImage SharpenLayer CLIP-TO-IMAGE)))
        )
      )
    
    (gimp-context-push)
    (gimp-image-undo-group-start img)
    (if (= (car (gimp-drawable-is-gray adraw )) TRUE)
        (gimp-image-convert-rgb img)
        )
    ;(gimp-context-set-foreground '(0 0 0))
    ;(gimp-context-set-background '(255 255 255))
    
    ;recover shadows
    (Eg-ShadowRecovery-Helper img adraw 0 shadowopacity)
    (set! adraw (car(gimp-image-get-active-layer img)))
    
    ;sharpen
    (Eg-SmartSharpen-Helper img adraw
                            2 sharpness 0
                            FALSE
                            5 1 0 0.5
                            0.01 6 6)
    (set! adraw (car(gimp-image-get-active-layer img)))
    
    ;enhance local contrast
    (if(> localcontrast 0)
       (plug-in-unsharp-mask 1 img adraw 60 localcontrast 0)
       )
    
    ;copy original layer 2 times
    (set! overlaylayer (car(gimp-layer-copy adraw FALSE)))
    (set! overlaylayer2 (car(gimp-layer-copy adraw FALSE)))
    (set! screenlayer (car(gimp-layer-copy adraw FALSE)))
    
    ;add screen- and overlay- layers
    (gimp-image-add-layer img screenlayer -1)
    (gimp-image-add-layer img overlaylayer -1)
    (gimp-image-add-layer img overlaylayer2 -1)
    
    ;desaturate layers
    (gimp-desaturate screenlayer)
    (gimp-desaturate overlaylayer)  
    (gimp-desaturate overlaylayer2)  
    
    ;give names
    (gimp-drawable-set-name screenlayer "Screen")
    (gimp-drawable-set-name overlaylayer "Overlay")
    (gimp-drawable-set-name overlaylayer2 "Overlay 2")
    
    ;set modes 
    (gimp-layer-set-mode screenlayer SCREEN-MODE)
    (gimp-layer-set-mode overlaylayer OVERLAY-MODE)
    (gimp-layer-set-mode overlaylayer2 OVERLAY-MODE)
    (gimp-layer-set-opacity screenlayer screenopacity)
    (gimp-layer-set-opacity overlaylayer2 overlayopacity)
    
    ;layermask for the screen layer
    (if(= screenmask TRUE)
       (begin
         (set! floatingsel (car (gimp-layer-create-mask screenlayer 5)))
         (gimp-layer-add-mask screenlayer floatingsel)
         (gimp-invert floatingsel)
         )
       )
    
    ; tidy up
    (gimp-image-undo-group-end img)
    (gimp-displays-flush)
    (gimp-context-pop)
    )
  )

(script-fu-register "elsamuko-national-geographic"
                    _"_National Geographic"
                    "Simulating High Quality Photos.
Newest version can be downloaded from http://registry.gimp.org/"
                    "Samuel Albrecht <samuel_albrecht@web.de>"
                    "Samuel Albrecht"
                    "22/09/08"
                    "*"
                    SF-IMAGE       "Input image"           0
                    SF-DRAWABLE    "Input drawable"        0
                    SF-ADJUSTMENT _"Shadow Recover Opacity"   '(60  0  100  1   5 0 0)
                    SF-ADJUSTMENT _"Sharpness"                '(1   0    2  0.1 1 1 0)
                    SF-ADJUSTMENT _"Screen Layer Opacity"     '(60  0  100  1   5 0 0)                    
                    SF-ADJUSTMENT _"2. Overlay Layer Opacity" '(25  0  100  1   5 0 0)
                    SF-ADJUSTMENT _"Local Contrast"           '(0.4 0    2  0.1 1 1 0)
                    SF-TOGGLE     _"Layer Mask for the Screen Layer"     FALSE
                    )

(script-fu-menu-register "elsamuko-national-geographic" _"<Image>/Filters/Generic")
