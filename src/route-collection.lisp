(uiop:define-package #:40ants-routes/route-collection
  (:use #:cl)
  (:import-from #:40ants-routes/generics
                #:match-url)
  (:export #:route-collection
           #:collection-routes
           #:collection-namespace))
(in-package #:40ants-routes/route-collection)


(defclass route-collection ()
  ((routes :initarg :routes
           :accessor collection-routes
           :initform nil
           :documentation "List of routes in this collection")
   ;; (namespace :initarg :namespace
   ;;            :reader collection-namespace
   ;;            :documentation "Namespace of this collection")
   ))


(defmethod match-url ((obj route-collection) (url string))
  (loop for subroute in (collection-routes obj)
        thereis (match-url subroute url)))
