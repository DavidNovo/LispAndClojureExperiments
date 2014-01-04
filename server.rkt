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
;;
;;

;; constants section
(define port-no  8080) ;HTTP port of server
(define number-of-tcp-connections 5)
(define sample-http-request "GET /path/to/file/index.html HTTP/1.0 \r\n")

;; variable section



;; This is a simple Hello World test page
;; interp.  this page is only used for creating tests
;; the page will be a String containning HTTP commands
;; String
(define hello-world-page 
  "HTTP/1.0 200 Okay\r\n Server:k\r\nContent-Type: text/html\r\n\r\n <html><head></head><body>Hello, world!  This is Racket Server. </body></html>")
;; Template rules used:
;;  - atomic non-distinct: String
;; template
;;(define (fn-for-hello-world-page t)
;;  (... t))


;; tests
(check-expect (string? hello-world-page) true)
(check-expect (number? port-no) true)
;;(check-expect (= port-no 8080) true)

;; functions 

;; first a method to serve pages, to accept a TCP connection
;; this is the top-level function
;; to start the server use (define stop (serve port-no))

(define (serve port-no)
  (define listener-tcp (tcp-listen port-no number-of-tcp-connections #t ))
  (define (loop)
    (accept-and-handle listener-tcp)
    (loop))
  ;; call the loop in new thread of control
  (define t (thread loop))
  (lambda ()
    (kill-thread t)
    (tcp-close listener-tcp)))
;; example and tests
(check-expect (procedure?(serve 8080)) #t )


;; accepts a TCP connection ->returns closes streams
;; creates a tcp client connection on the server associated with listener
;;(define (accept-and-handle listener)
;;  ( listener))
(define (accept-and-handle listener)
  (define-values (input-stream output-stream)(tcp-accept listener))
  (handle-tcp input-stream output-stream)
  (close-input-port input-stream)
  (close-output-port output-stream))
;; examples
;; this should return a hello world page 
;;(check-expect (accept-and-handle 
;;               (tcp-listen port-no number-of-tcp-connections #t )) null)


;; takes the tcp request and creates a reply
;; input stream, output stream  -> output stream
(define (handle-tcp input-stream output-stream)
  ; Discard the request header (up to blank line):
  (regexp-match #rx"(\r\n|^)\r\n" input-stream)
  ; Send reply:
  (display hello-world-page output-stream))
;; examples and tests
;; parameters for testing
(check-expect (handle-tcp "null string" (current-output-port)) (display hello-world-page))



;; the following runs the tests.  should be commented out
;; for production
(test)