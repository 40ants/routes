(uiop:define-package #:40ants-routes/route
  (:use #:cl)
  (:import-from #:40ants-routes/generics
                #:match-url)
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


(defmethod match-url ((obj route) (url string) &key on-match)
  ;; Here we don't want to pass ON-MATCH to the
  ;; MATCH-URL method of URL-PATTERN, because we don't need
  ;; these objects in the routes chain:
  (multiple-value-bind (matchedp parameters)
      (match-url (route-pattern obj) url)
    (when matchedp
      ;; Instead of url-pattern we want to return this route object
      (let ((route-with-params
              (make-instance '40ants-routes/matched-route::matched-route
                             :original-route obj
                             :parameters parameters)))
        (when on-match
          (funcall on-match
                   route-with-params))
        (values route-with-params
                parameters)))))
