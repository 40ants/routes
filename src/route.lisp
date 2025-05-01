(uiop:define-package #:40ants-routes/route
  (:use #:cl)
  (:import-from #:str
                #:trim-right
                #:replace-all)
  (:import-from #:serapeum
                #:->
                #:soft-alist-of)
  (:import-from #:40ants-routes/errors
                #:argument-missing-error)
  (:import-from #:40ants-routes/url-pattern
                #:url-pattern-params
                #:url-pattern-pattern
                #:url-pattern)
  (:import-from #:40ants-routes/generics
                #:url-path)
  (:import-from #:40ants-routes/vars
                #:*current-route*)
  (:export #:route
           #:route-name
           #:route-handler
           #:route-parameters
           #:route-title
           #:route-method
           #:routep
           #:current-route
           #:current-route-p))
(in-package #:40ants-routes/route)


(defclass route ()
  ((name :initarg :name
         :type string
         :reader route-name
         :documentation "Name of the route")
  (pattern :initarg :pattern
           :type url-pattern
           :reader url-path
           :documentation "URL pattern")
   (handler :initarg :handler
            :reader route-handler
            :type function
            :documentation "Function to handle the route")
   (title :initarg :title
          :type (or null string function)
          :initform nil
          :documentation "Title for breadcrumbs"
          :reader route-title)
   (method :initarg :method
           :reader route-method
           :type keyword
           :initform :get
           :documentation "HTTP method (GET, POST, PUT, etc.)")))


(defmethod print-object ((obj route) stream)
  (print-unreadable-object (obj stream :type t)
    (format stream "~S ~S"
            (route-method obj)
            (url-pattern-pattern
             (url-path obj)))))


(-> routep (t)
    (values boolean &optional))

(defun routep (obj)
  "Checks if object is of type ROUTE"
  (typep obj 'route))


(defmethod 40ants-routes/generics::format-url ((obj route) stream args)
  (40ants-routes/generics::format-url
   (url-path obj)
   stream
   args))


(defun current-route-p ()
  "Returns T if there current route matching the URL was found..
   
   Should be called only during 40ANTS-ROUTES/WITH-URL:WITH-URL
   or 40ANTS-ROUTES/WITH-URL:WITH-PARTIALLY-MATCHED-URL macro body execution."
  (boundp '*current-route*))


(defun current-route ()
  "Returns the current route.
   
   Should be called only during 40ANTS-ROUTES/WITH-URL:WITH-URL macro body execution."
  (unless (boundp '*current-route*)
    (error "CURRENT-ROUTE should be called only during 40ANTS-ROUTES/WITH-URL:WITH-URL macro body execution."))
  *current-route*)


(-> replace-parameters (url-pattern list)
    (values string &optional))

(defun replace-parameters (url-pattern args)
  "Replace parameters in a URL pattern with their values.

   - URL-PATTERN - The original URL pattern (e.g., '/<string:slug>')
   - ARGS - Property list of parameter values (:name value ...)"
  (loop with params = (url-pattern-params url-pattern)
        with pattern = (url-pattern-pattern url-pattern)
        with result = pattern
        for (param-name param-type) in params
        for param-value = (getf args param-name)
        do (cond
             (param-value
              (let ((param-with-type
                      (format nil "<~A:~A>"
                              param-type
                              (string-downcase (symbol-name param-name)))))
                (setf result (replace-all param-with-type
                                          (princ-to-string param-value)
                                          result))))
             (t
              ;; If parameter is missing, throw an error
              (let ((route-name (when (current-route-p)
                                  (route-name
                                   (current-route)))))
                (error 'argument-missing-error
                       :route-name (or route-name
                                       "unknown-route-name")
                       :missing-parameter param-name))))
        finally (return result)))


(defmethod 40ants-routes/generics::format-url ((obj url-pattern) stream args)
  (write-string (string-left-trim '(#\/)
                                  (replace-parameters obj args))
                stream)
  (values))
