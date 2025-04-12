(uiop:define-package #:40ants-routes/matched-route
  (:use #:cl)
  (:import-from #:serapeum
                #:soft-alist-of)
  (:import-from #:40ants-routes/route
                #:route-pattern
                #:route-method)
  (:import-from #:40ants-routes/url-pattern
                #:url-pattern-pattern))
(in-package #:40ants-routes/matched-route)


(defclass matched-route ()
  ((original-route :initarg :original-route
                   :reader matched-route-original-route
                   :documentation "The original ROUTE object which has been matched.")
   (parameters :initarg :parameters
               :reader matched-route-parameters
               :type (soft-alist-of keyword symbol) 
               :initform nil
               :documentation "Parameters extracted from the URL pattern as alist where keys are parameter names and values - parameter types.")))


(defmethod print-object ((obj matched-route) stream)
  (let ((route (matched-route-original-route obj)))
    (print-unreadable-object (obj stream :type t)
      (format stream "~S ~S~@[~S~]"
              (route-method route)
              (url-pattern-pattern
               (route-pattern route))
              (matched-route-parameters obj)))))


(defun matched-route-p (obj)
  (typep obj 'matched-route))


