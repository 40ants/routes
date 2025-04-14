(uiop:define-package #:40ants-routes/route
  (:use #:cl)
  (:import-from #:serapeum
                #:->
                #:soft-alist-of)
  (:import-from #:40ants-routes/url-pattern
                #:url-pattern-pattern
                #:url-pattern)
  (:export #:route
           #:route-name
           #:route-pattern
           #:route-handler
           #:route-parameters
           #:route-title
           #:route-method
           #:routep))
(in-package #:40ants-routes/route)


(defclass route ()
  ((name :initarg :name
         :type string
         :reader route-name
         :documentation "Name of the route")
   (pattern :initarg :pattern
            :type url-pattern
            :reader route-pattern
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
             (route-pattern obj)))))


(-> routep (t)
    (values boolean &optional))

(defun routep (obj)
  "Checks if object is of type ROUTE"
  (typep obj 'route))


(defmethod 40ants-routes/generics::format-url ((obj route) stream args)
  (40ants-routes/generics::format-url
   (route-pattern obj)
   stream
   args))
