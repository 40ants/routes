(uiop:define-package #:40ants-routes/included-routes
  (:use #:cl)
  (:import-from #:40ants-routes/routes
                #:routes
                #:routes-namespace
                #:children-routes)
  (:import-from #:40ants-routes/route
                #:route-name
                #:route-parameters
                #:route-title
                #:route-method
                #:route-handler)
  (:import-from #:40ants-routes/url-pattern
                #:url-pattern-pattern
                #:url-pattern)
  (:import-from #:40ants-routes/generics
                #:partial-match-url
                #:match-url
                #:url-path)
  (:export #:included-routes
           #:included-routes-original-collection
           #:included-routes-p))
(in-package #:40ants-routes/included-routes)

(defclass included-routes ()
  ((original-collection :initarg :original-collection
                        :reader included-routes-original-collection
                        :type routes
                        :documentation "The original collection that was included")
   (path :initarg :path
         :type url-pattern
         :reader url-path
         :documentation "Path to add to all routes in the collection")))


(defmethod print-object ((obj included-routes) stream)
  (print-unreadable-object (obj stream :type t)
    (format stream "~S (refers to :namespace ~S)"
            (url-pattern-pattern
             (url-path obj))
            (routes-namespace obj))))


(defun included-routes-p (obj)
  (typep obj 'included-routes))


;; Proxy methods for included-routes
(defmethod children-routes ((included included-routes))
  (children-routes (included-routes-original-collection included)))


(defmethod routes-namespace ((included included-routes))
  (routes-namespace (included-routes-original-collection included)))


(defmethod match-url ((obj included-routes) (url string) &key on-match)
  (multiple-value-bind (matched position)
      (partial-match-url (url-path obj) url)
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


(defmethod 40ants-routes/generics::format-url ((obj included-routes) stream args)
  (40ants-routes/generics::format-url
   (url-path obj)
   stream
   args))
