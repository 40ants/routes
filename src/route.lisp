(uiop:define-package #:40ants-routes/route
  (:use #:cl)
  (:import-from #:40ants-routes/route-collection
                #:route-collection
                #:collection-namespace)
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
         :reader route-name
         :documentation "Name of the route")
   (pattern :initarg :pattern
            :reader route-pattern
            :documentation "URL pattern")
   (handler :initarg :handler
            :reader route-handler
            :documentation "Function to handle the route")
   (namespace :initarg :namespace
              :reader route-namespace
              :documentation "Namespace of the route")
   (parameters :initarg :parameters
               :reader route-parameters
               :initform nil
               :documentation "Parameters extracted from the URL pattern")
   (title :initarg :title
          :reader route-title
          :initform nil
          :documentation "Title for breadcrumbs")
   (method :initarg :method
           :reader route-method
           :initform :get
           :documentation "HTTP method (GET, POST, PUT, etc.)")))