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
