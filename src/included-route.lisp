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
  (:export #:included-route
           #:included-route-original-collection
           #:included-route-prefix
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
   (prefix :initarg :prefix
           :initform ""
           :reader included-route-prefix
           :documentation "Prefix to add to all routes in the collection")
   (namespace :initarg :namespace
              :initform nil
              :reader included-route-namespace
              :documentation "Custom namespace for the included routes")))

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
