(uiop:define-package #:40ants-routes/matched-route
  (:use #:cl)
  (:import-from #:serapeum
                #:soft-alist-of)
  (:import-from #:40ants-routes/route
                #:route
                #:route-pattern
                #:route-method)
  (:import-from #:40ants-routes/url-pattern
                #:url-pattern-pattern)
  (:import-from #:40ants-routes/generics
                #:match-url))
(in-package #:40ants-routes/matched-route)


(defclass matched-route ()
  ((original-route :initarg :original-route
                   :reader matched-route-original-route
                   :type route
                   :documentation "The original ROUTE object which has been matched.")
   (parameters :initarg :parameters
               :reader matched-route-parameters
               :type (soft-alist-of keyword (or integer string)) 
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
