#lang racket

;; required libraries
(require test-engine/racket-tests)
(require xml)
(require net/url)





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
  "HTTP/1.0 200 Okay\r\n Server:k\r\nContent-Type: text/html\r\n\r\n <html><head></head><body>Hello, world!  This is Racket Server. Using custodians and threads</body></html>")

(define sample-get-request-bad 
  "GET /path/file.html 
HTTP/1.0
  From: someuser@jmarshall.com
  User-Agent: HTTPTool/1.0

")

(define sample-get-request
  "GET /path/file.html HTTP/1.0
From: someuser@jmarshall.com
User-Agent: HTTPTool/1.0")
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
;; to start the server use (define stop (serve port-no))
(define (serve port-no)
  ;; define a custodian for the server thread
  (define main-cust (make-custodian))
  (parameterize ([current-custodian main-cust])
    (define listener-tcp (tcp-listen port-no number-of-tcp-connections #t ))
    (define (loop)
      (accept-and-handle listener-tcp)
      (loop))
    ;; a new thread by default goes in the 
    ;; current custodian
    (thread loop))
  (lambda ()
    (custodian-shutdown-all main-cust)))

;; example and tests
(check-expect (procedure?(serve 8080)) #t )


;; accepts a TCP connection ->returns closes streams
;; creates a tcp client connection on the server associated with listener
;;(define (accept-and-handle listener)
;;  ( listener))
(define (accept-and-handle listener)
  (define cust (make-custodian))
  (custodian-limit-memory cust (* 50 1024 1024))
  (parameterize ([current-custodian cust])
    (define-values (input-stream output-stream)(tcp-accept listener))
    ;;putting each connecton into its own thread
    (thread
     (lambda ()
       (handle-tcp input-stream output-stream)
       (close-input-port input-stream)
       (close-output-port output-stream))))
  ;; watcher thread
  (thread (lambda() 
            (sleep 10)
            (custodian-shutdown-all cust))))
;; example and tests
;;this test does not return a value
;; I have to stop the top repl...I wonder why?
;(check-expect (procedure?(accept-and-handle 
;                          (tcp-listen 8081 1 #t )))
;               #t )



;; takes the tcp request and creates a reply
;; input stream, output stream  -> output stream
(define (handle-tcp input-stream output-stream)
  (define request (check-request input-stream))
  (when request
    ; Discard the request header (up to blank line):
    (regexp-match #rx"(\r\n|^)\r\n" input-stream)
    ;dispatcher
    (let ([xexpr (dispatch (list-ref  request 1))])
      ; send reply
      (display "HTTP/1.0 200 Okay\r\n" output-stream)
      (display "Server: k\r\nContent-Type: text/html\r\n\r\n" output-stream)
      (display (xexpr->string xexpr) output-stream))))

;; examples and tests
;; parameters for testing
(check-expect (handle-tcp (current-input-port) (current-output-port)) (display hello-world-page))

;; checking a request
;; HTTP request -> Boolean
;;(define request 
;;  (regexp-match "pattern to determine if it is a request"
;;                (read-line in)))  ;stub
;; function body
(define (check-request in)
  ;;Match the first line to extract the request:
  (regexp-match #rx"^GET (.+) HTTP/[0-9]+\\.[0-9]+"
                (read-line in)))
;; tests
(check-expect (check-request (open-input-string sample-get-request-bad)) #f)
(check-expect (check-request (open-input-string sample-get-request))
              '("GET /path/file.html HTTP/1.0" "/path/file.html"))


;; URL -> function that creates a page
;; this function takes a URL and returns a function
;; based on the path of the incomming url
;;(define dispatch URL null) ;stub
(define test-string "http://localhost:8080/")
(define test-hello-page-url "http://localhost:8080/hello")
(define test-hello-page-url-return `(html (body "Hello, World!")))


(define (dispatch str-path) 
  ;; Parse the request as a URL:
  (define url (string->url str-path))
  ;; Extract the path part:
  (define path (map path/param-path (url-path url)))
  ;; Find a handler based on the path's first element:
  (define h (hash-ref dispatch-table (car path) #f))
  (if h
      ;; Call a handler:
      (h (url-query url))
      ;; No handler found:
      `(html (head (title "Error"))
             (body
              (font ((color "red"))
                    "Unknown page: "
                    ,str-path)))))


;; tests
(check-expect (dispatch test-hello-page-url) test-hello-page-url-return)

;;!! ok, need new function to build reply page
;; string, destination url, hidden value on form -> reply html page
;; use this url for testing http://localhost:8081/many

(define (build-request-page label next-url hidden)
  `(html
    (head (title "Enter a Number to Add"))
    (body ([bgcolor "white"])
          (form ([action ,next-url] [method "get"])
                ,label
                (input ([type "text"] [name "number"]
                        [value ""]))
                (input ([type "hidden"] [name "hidden"]
                        [value ,hidden]))
                (input ([type "submit"] [name "enter"]
                        [value "Enter"]))))))

;; adding more elements to the hash dispatch table require
;; function for the reply
(define (many query)
  (build-request-page "Number of greetings:" "/reply" ""))
(define (reply query)
  (define n (string->number (cdr (assq 'number query))))
  `(html (body ,@(for/list ((i (in-range n)))
                   "hello"))))

;; hash table
(define dispatch-table (make-hash))
(hash-set! dispatch-table "hello"
           (lambda (query)
             '(html (body "Hello, World!"))))
(hash-set! dispatch-table "many" many)
(hash-set! dispatch-table "reply" reply)

  
;; the following runs the tests.  should be commented out
;; for production
(test)