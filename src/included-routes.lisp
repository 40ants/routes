(uiop:define-package #:40ants-routes/included-routes
  (:use #:cl)
  (:import-from #:40ants-routes/routes
                #:children-routes)
  (:import-from #:40ants-routes/route
                #:route-name
                #:route-namespace
                #:route-pattern
                #:route-parameters
                #:route-title
                #:route-method
                #:route-handler)
  (:import-from #:40ants-routes/url-pattern
                #:url-pattern-pattern
                #:url-pattern)
  (:import-from #:40ants-routes/generics
                #:partial-match-url
                #:match-url)
  (:export #:included-routes
           #:included-routes-original-collection
           #:included-routes-path
           #:included-routes-namespace
           #:collection-parent
           #:included-routes-p))
(in-package #:40ants-routes/included-routes)


(defclass included-routes ()
  ((original-collection :initarg :original-collection
                        :reader included-routes-original-collection
                        :documentation "The original collection that was included")
   (parent :accessor collection-parent
           :initform nil
           :documentation "Parent collection, will be set when object will be added as a child")
   (path :initarg :path
         :type url-pattern
         :reader included-routes-path
         :documentation "Path to add to all routes in the collection")
   (namespace :initarg :namespace
              :initform nil
              :type (or null string)
              :reader included-routes-namespace
              :documentation "Custom namespace for the included routes")))


(defmethod print-object ((obj included-routes) stream)
  (print-unreadable-object (obj stream :type t)
    (format stream "~S (:namespace ~S)"
            (url-pattern-pattern
             (included-routes-path obj))
            (included-routes-namespace obj))))


(defun included-routes-p (obj)
  (typep obj 'included-routes))

;; Proxy methods for included-routes
(defmethod children-routes ((included included-routes))
  (children-routes (included-routes-original-collection included)))


;; Store the original collection directly without any proxying
(defmethod included-routes-original-collection :around ((included included-routes))
  (let ((original (call-next-method)))
    (if (and (typep original 'included-routes)
             (slot-boundp original 'original-collection))
        ;; If the original is itself an included-routes, get its original collection
        (included-routes-original-collection original)
        ;; Otherwise, return the original
        original)))

;; Add route-name method for included-routes
(defmethod route-name ((included included-routes))
  (route-name (included-routes-original-collection included)))


(defmethod match-url ((obj included-routes) (url string) &key on-match)
  (multiple-value-bind (matched position)
      (partial-match-url (included-routes-path obj) url)
    (when matched
      (when on-match
        (funcall on-match obj))
      
      (match-url (included-routes-original-collection obj)
                 ;; Here we substract 1 to pass
                 ;; url with beginning /.
                 ;; We need this, because prefix to which
                 ;; INCLUDED-ROUTES matches should end with
                 ;; slash, but to make correct matches
                 ;; of child nodes we also need this slash
                 ;; at the beginning of the path
                 (subseq url (1- position))
                 :on-match on-match))))
