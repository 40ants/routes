(uiop:define-package #:40ants-routes/route
  (:use #:cl)
  (:import-from #:serapeum
                #:soft-alist-of)
  (:import-from #:40ants-routes/url-pattern
                #:url-pattern-pattern
                #:url-pattern)
  (:export #:route
           #:route-name
           #:route-pattern
           #:route-handler
           #:route-namespace
           #:route-parameters
           #:route-title
           #:route-method))
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
   ;; (namespace :initarg :namespace
   ;;            :reader route-namespace
   ;;            :documentation "Namespace of the route")
   ;; (parameters :initarg :parameters
   ;;             :reader route-parameters
   ;;             :type (soft-alist-of keyword symbol)
   ;;             :initform nil
   ;;             :documentation "Parameters extracted from the URL pattern as alist where keys are parameter names and values - parameter types")
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

