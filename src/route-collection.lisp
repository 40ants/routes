(uiop:define-package #:40ants-routes/route-collection
  (:use #:cl)
  (:export #:route-collection
           #:collection-routes
           #:collection-namespace))
(in-package #:40ants-routes/route-collection)

(defclass route-collection ()
  ((routes :initarg :routes
           :accessor collection-routes
           :initform nil
           :documentation "List of routes in this collection")
   (namespace :initarg :namespace
              :reader collection-namespace
              :documentation "Namespace of this collection")))