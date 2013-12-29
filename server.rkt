#lang racket
 
;; required libraries
(require test-engine/racket-tests)




;How to Design Data
;1. A possible structure definition (not until compound data)
;2. A type comment that defines a new type name and describes how to form data of that type.
;3. An interpretation that describes the correspondence between information and data.
;4. One or more examples of the data.
;5. A template for a 1 argument function operating on data of this type.

;steps to design function
;1. Signature, purpose and stub.
;2. Define examples, wrap each in check-expect.
;3. Template and inventory.
;4. Code the function body.
;5. Test and debug until correct

;; constants section
(define port-no  8080) ;HTTP port of server
(define input-stream "place holder for a stream" )
(define number-of-tcp-connections 5)
(define sample-http-request "GET /path/to/file/index.html HTTP/1.0 \r\n")

;; variable section



;; This is a simple Hello World test page
;; interp.  this page is only used for creating tests
;; the page will be a String containning HTTP commands
;; String
(define hello-world-page 
  "HTTP/1.0 200 Okay\r\n Server:k\r\nContent-Type: text/html\r\n\r\n <html><head></head><body>Hello, world!</body></html>")
;; Template rules used:
;;  - atomic non-distinct: String
;; template
;;(define (fn-for-hello-world-page t)
;;  (... t))


;; tests
(check-expect (string? hello-world-page) true)
(check-expect (number? port-no) true)
(check-expect (= port-no 8080) true)

;; functions

;; first a method to serve pages, to accept a TCP connection
;; this is the top-level function
(define (serve port-no)
  (define listener (tcp-listen port-no number-of-tcp-connections #t ))
    (define (loop)
      (accept-and-handle listener)
      (loop))
    (loop))
    

;; !!
;; This is a listener for the serve function, listens for TCP connections
;; port number, number of connection, allow for reuse
;; number, number, boolean -> TCP listener
;;(define listener (tcp-listen port-no number-of-tcp-connections #t ))
;; when I moved this into the server function definition it worked, re-served pages a lot.  why?

;; examples
;;(check-expect (listener (tcp-listen port-no number-of-tcp-connections #t "127.0.0.1")) #<tcp-listener>)

;; !!
;; accepts a TCP connection ->returns response
;;(define (accept-and-handle listener)
;;  ( listener))
(define (accept-and-handle listener)
  (define-values (input-stream output-stream)(tcp-accept listener))
    (handle-tcp input-stream output-stream)
    (close-input-port input-stream)
    (close-output-port output-stream))
;; examples
;; this should return a hello world page
;;(check-expect (accept-and-handle listener) hello-world-page)


;; takes the tcp request and creates a reply
;; input stream -> output stream
(define (handle-tcp input-stream output-stream)
  ; Discard the request header (up to blank line):
  (regexp-match #rx"(\r\n|^)\r\n" input-stream)
  ; Send reply:
  (display hello-world-page output-stream))



;; the following runs the tests.  should be commented out
;; for production
;;(test)