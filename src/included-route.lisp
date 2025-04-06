(uiop:define-package #:40ants-routes/included-route
  (:use #:cl)
  (:import-from #:40ants-routes/route-collection
                #:collection-routes
                #:collection-namespace)
  (:export #:included-route
           #:included-route-original-collection
           #:collection-parent))
(in-package #:40ants-routes/included-route)

(defclass included-route ()
  ((original-collection :initarg :original-collection
                        :reader included-route-original-collection
                        :documentation "The original collection that was included")
   (parent :initarg :parent
           :accessor collection-parent
           :initform nil
           :documentation "Parent collection")))

;; Proxy methods for included-route
(defmethod collection-routes ((included included-route))
  (collection-routes (included-route-original-collection included)))

(defmethod collection-namespace ((included included-route))
  (collection-namespace (included-route-original-collection included)))