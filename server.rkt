#lang racket

;How to Design Data
;1. A possible structure definition (not until compound data)
;2. A type comment that defines a new type name and describes how to form data of that type.
;3. An interpretation that describes the correspondence between information and data.
;4. One or more examples of the data.
;5. A template for a 1 argument function operating on data of this type.

;; constants section
(define port-no  8080) ;HTTP port of server



;; variable section



;; This is a simple Hello World test page
;; interp.  this page is only used for creating tests
;; the page will be a String containning HTTP commands
(define (hello-world-page) 
  (display "HTTP/1.0 200 Okay\r\n" out)
  (display "Server: k\r\nContent-Type: text/html\r\n\r\n" out)
  (display "<html><body>Hello, world!</body></html>" out))
;; Template rules used:
;;  - atomic non-distinct: String


;; functions
;; ;; steps to design function
;1. Signature, purpose and stub.
;2. Define examples, wrap each in check-expect.
;3. Template and inventory.
;4. Code the function body.
;5. Test and debug until correct


