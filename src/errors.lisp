(uiop:define-package #:40ants-routes/errors
  (:use #:cl)
  (:export #:parent-already-set
           #:parent-already-set-route))
(in-package #:40ants-routes/errors)


(define-condition parent-already-set (error)
  ((route :initarg :route
          :reader parent-already-set-route
          :documentation "A route object for which parent already exists."))
  (:report (lambda (condition stream)
             (format stream "Parent already was set for route ~S. Route can have only one parent."
                     (parent-already-set-route condition)))))
