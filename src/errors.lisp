(uiop:define-package #:40ants-routes/errors
  (:use #:cl)
  (:export #:no-common-elements-error
           #:full-namespace
           #:relative-namespace))
(in-package #:40ants-routes/errors)


(define-condition no-common-elements-error (error)
  ((full-namespace :initarg :full-namespace
                   :reader full-namespace)
   (relative-namespace :initarg :relative-namespace
                       :reader relative-namespace))
  (:report (lambda (condition stream)
             (format stream "There is no common elements between ~S and ~S namespaces."
                     (full-namespace condition)
                     (relative-namespace condition)))))


(define-condition namespace-duplication-error (error)
  ((namespace :initarg :namespace
              :reader existing-namespace)
   (existing-route :initarg :existing-route
                   :reader existing-route)
   (new-route :initarg :new-route
              :reader new-route))
  (:report (lambda (condition stream)
             (format stream "There is already a ~S route with namespace ~S namespaces, can't add route ~S with same namespace."
                     (existing-route condition)
                     (existing-namespace condition)
                     (new-route condition)))))
