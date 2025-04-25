(uiop:define-package #:40ants-routes/route
  (:use #:cl)
  (:import-from #:serapeum
                #:->
                #:soft-alist-of)
  (:import-from #:40ants-routes/url-pattern
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
           #:current-route))
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


(defun current-route ()
  "Returns the current route.
   
   Should be called only during 40ANTS-ROUTES/WITH-URL:WITH-URL macro body execution."
  (unless (boundp '*current-route*)
    (error "CURRENT-ROUTE should be called only during 40ANTS-ROUTES/WITH-URL:WITH-URL macro body execution."))
  *current-route*)
