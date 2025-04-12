(uiop:define-package #:40ants-routes/included-route
  (:use #:cl)
  (:import-from #:40ants-routes/route-collection
                #:collection-namespace
                #:collection-routes)
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
  (:export #:included-route
           #:included-route-original-collection
           #:included-route-path
           #:included-route-namespace
           #:collection-parent))
(in-package #:40ants-routes/included-route)

(defclass included-route ()
  ((original-collection :initarg :original-collection
                        :reader included-route-original-collection
                        :documentation "The original collection that was included")
   (parent :initarg :parent
           :accessor collection-parent
           :initform nil
           :documentation "Parent collection")
   (path :initarg :path
           :type url-pattern
           :reader included-route-path
           :documentation "Path to add to all routes in the collection")
   (namespace :initarg :namespace
              :initform nil
              :reader included-route-namespace
              :documentation "Custom namespace for the included routes")))


(defmethod print-object ((obj included-route) stream)
  (print-unreadable-object (obj stream :type t)
    (format stream "~S (:namespace ~S)"
            (url-pattern-pattern
             (included-route-path obj))
            (included-route-namespace obj))))


;; Proxy methods for included-route
(defmethod collection-routes ((included included-route))
  (let ((original (included-route-original-collection included)))
    (if (typep original 'included-route)
        ;; If the original is itself an included-route, get its routes
        (collection-routes original)
        ;; Otherwise, get the routes directly
        (collection-routes original))))

(defmethod collection-namespace ((included included-route))
  (let ((custom-namespace (included-route-namespace included)))
    (if custom-namespace
        custom-namespace
        (collection-namespace (included-route-original-collection included)))))

;; Store the original collection directly without any proxying
(defmethod included-route-original-collection :around ((included included-route))
  (let ((original (call-next-method)))
    (if (and (typep original 'included-route)
             (slot-boundp original 'original-collection))
        ;; If the original is itself an included-route, get its original collection
        (included-route-original-collection original)
        ;; Otherwise, return the original
        original)))

;; Add route-name method for included-route
(defmethod route-name ((included included-route))
  (route-name (included-route-original-collection included)))


(defmethod match-url ((obj included-route) (url string))
  (multiple-value-bind (matched position)
      (partial-match-url (included-route-path obj) url)
    (when matched
      (match-url (included-route-original-collection obj)
                 (subseq url position)))))
