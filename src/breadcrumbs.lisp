(uiop:define-package #:40ants-routes/breadcrumbs
  (:use #:cl)
  (:import-from #:split-sequence
                #:split-sequence)
  (:import-from #:40ants-routes/route
                #:route-title
                #:route)
  (:import-from #:serapeum
                #:->)
  (:import-from #:40ants-routes/url-pattern
                #:url-pattern-pattern)
  (:import-from #:40ants-routes/generics
                #:format-url
                #:match-url
                #:get-route-breadcrumbs
                #:url-path)
  (:import-from #:40ants-routes/vars
                #:*routes-path*)
  (:import-from #:40ants-routes/included-routes
                #:original-routes
                #:included-routes)
  (:import-from #:40ants-routes/routes
                #:routes)
  (:import-from #:alexandria
                #:alist-plist
                #:last-elt)
  (:import-from #:40ants-routes/matched-route
                #:matched-route-parameters
                #:matched-route)
  (:export #:get-breadcrumbs
           #:breadcrumb
           #:breadcrumb-path
           #:breadcrumb-title
           #:breadcrumb-route
           #:make-breadcrumb))
(in-package #:40ants-routes/breadcrumbs)


(defclass breadcrumb ()
  ((path :initarg :path
         :type string
         :reader breadcrumb-path)
   (title :initarg :title
         :type string
         :reader breadcrumb-title)
   (route :initarg :route
          :type route
          :reader breadcrumb-route)))


(defmethod print-object ((obj breadcrumb) stream)
  (print-unreadable-object (obj stream :type t)
    (format stream "~S ~S"
            (breadcrumb-title obj)
            (breadcrumb-path obj))))


(defvar *breadcrumbs-path*)


(-> current-breadcrumb-path ()
    (values string &optional))

(defun current-breadcrumb-path ()
  (unless (40ants-routes/route:current-route-p)
    (error "Breadcrumbs can be collected only inside WITH-URL macro or inside WITH-PARTIALLY-MATCHED-URL when URL was fully matched."))
  
  (with-output-to-string (s)
    (write-char #\/ s)
    (loop with matched-route = (40ants-routes/route:current-route)
          with args = (etypecase matched-route
                        (matched-route
                         (alist-plist
                          (matched-route-parameters matched-route))))
          for route in (reverse *breadcrumbs-path*)
          do (format-url route s args))))


(-> current-breadcrumb-route ()
    (values route &optional))

(defun current-breadcrumb-route ()
  (first *breadcrumbs-path*))

(-> make-breadcrumb (string)
    (values breadcrumb &optional))

(defun make-breadcrumb (title)
  "Creates a breadcrumb item."
  (make-instance 'breadcrumb
                 :path (current-breadcrumb-path)
                 :title title
                 :route (current-breadcrumb-route)))


(defun get-breadcrumbs ()
  "Generate breadcrumbs list for the current URL set by 40ANTS-ROUTES/WITH-URL:WITH-URL macro."
  (let ((*breadcrumbs-path* nil))
    (loop for node in (reverse *routes-path*)
          for breadcrumbs = (get-route-breadcrumbs node)
          appending (uiop:ensure-list breadcrumbs)
          ;; Other routes paths should be based on the previos nodes
          do (push node *breadcrumbs-path*))))


(defmethod get-route-breadcrumbs :around ((obj t))
  (typecase obj
    ((or route routes included-routes)
     (push obj *breadcrumbs-path*)))

  (unwind-protect
       (call-next-method)
    (typecase obj
      ((or route routes included-routes)
       (pop *breadcrumbs-path*)))))


(defmethod get-route-breadcrumbs ((obj route))
  (let* ((title (route-title obj))
         (title (etypecase title
                  (string title)
                  (function
                   (unless (40ants-routes/route:current-route-p)
                     (error "Function as a route title can be resolved only when URL was fully matched by WITH-URL or WITH-PARTIALLY-MATCHED-URL macro body execution."))
                   (apply title
                          (alist-plist
                           (matched-route-parameters
                            (40ants-routes/route:current-route))))))))
    (make-breadcrumb title)))


(defmethod get-route-breadcrumbs ((obj included-routes))
  (get-route-breadcrumbs (original-routes obj)))


(defmethod get-route-breadcrumbs ((obj routes))
  (let ((root-route (match-url obj "/")))
    (when root-route
      (get-route-breadcrumbs root-route))))
