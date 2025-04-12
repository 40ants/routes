(uiop:define-package #:40ants-routes/find-route
  (:use #:cl)
  (:import-from #:40ants-routes/vars
                #:*current-routes*)
  (:import-from #:40ants-routes/route
                #:route
                #:route-name)
  (:import-from #:40ants-routes/routes
                #:routes
                #:children-routes
                #:collection-namespace)
  (:import-from #:40ants-routes/included-routes
                #:included-routes
                #:included-routes-original-collection)
  (:import-from #:split-sequence
                #:split-sequence)
  (:import-from #:40ants-routes/url-pattern
                #:match-url)
  (:import-from #:serapeum
                #:soft-list-of
                #:->)
  (:export #:find-route
           #:find-matching-route))
(in-package #:40ants-routes/find-route)


(-> namespaces-chain ((or included-routes
                          routes
                          route))
    (values (soft-list-of string) &optional))


(defun namespaces-chain (routes)
  (loop for current = routes
          then (cond
                 ((typep current 'included-routes)
                  (40ants-routes/included-routes:collection-parent current))
                 (t
                  nil))
        for current-namespace = (typecase current
                                  (included-routes
                                   (40ants-routes/included-routes::included-routes-namespace current))
                                  (t
                                   nil))
        while current-namespace
        collect current-namespace))


(-> ensure-absolute-namespace ((or string
                                   (soft-list-of string))
                               (or included-routes
                                   routes
                                   route))
    (values (soft-list-of string)
            &optional))

(defun ensure-absolute-namespace (namespace current-routes)
  (etypecase namespace
    (string
     (append (namespaces-chain current-routes)
             (list namespace)))
    (list
     (values namespace))))


;; Define find-route as a generic function
(defgeneric find-route (name namespace)
  (:documentation "Find a route by name in the given namespace hierarchy."))

;; Primary method for find-route
(defmethod find-route ((name string) (namespace t))
  (unless *current-routes*
    (error "Use WITH-ROUTES macro to set current routes object."))

  (let ((namespace (ensure-absolute-namespace
                    namespace
                    *current-routes*))
        (routes *current-routes*))
    
  
    ;; (or
    ;;  ;; First, try to find the route directly in the collection's routes
    ;;  (when (or (null namespace)
    ;;            (string= (collection-namespace *current-routes*)
    ;;                     namespace))
    ;;    (find name (children-routes *current-routes*)
    ;;          :key #'route-name
    ;;          :test #'string=))
   
    ;;  ;; Next, check if any of the routes is an included-routes
    ;;  (loop for route in (children-routes *current-routes*)
    ;;        when (typep route 'included-routes)
    ;;          do (let* ((included-namespace (40ants-routes/included-routes:included-routes-namespace route))
    ;;                    (original-collection (included-routes-original-collection route))
    ;;                    (found-route (if included-namespace
    ;;                                     ;; If the included route has a custom namespace, look for the route in that namespace
    ;;                                     (find-route name included-namespace)
    ;;                                     ;; Otherwise, look in the original collection
    ;;                                     (find name (children-routes original-collection)
    ;;                                           :key #'route-name
    ;;                                           :test #'string=))))
    ;;               (when found-route
    ;;                 (return found-route))))
   
    ;;  ;; If not found in this namespace, check if this namespace is included in another namespace
    ;;  ;; and look for the route there with the original name
    ;;  ;; (loop for parent-ns being the hash-keys of *routess*
    ;;  ;;         using (hash-value parent-collection)
    ;;  ;;       do (with-routes (parent-collection)
    ;;  ;;            (loop for route in (children-routes *current-routes*)
    ;;  ;;                  when (and (typep route 'included-routes)
    ;;  ;;                            (let ((included-ns (40ants-routes/included-routes:included-routes-namespace route)))
    ;;  ;;                              (and included-ns (string= included-ns namespace))))
    ;;  ;;                    do (let ((found-route (find name (children-routes (included-routes-original-collection route))
    ;;  ;;                                                :key #'route-name
    ;;  ;;                                                :test #'string=)))
    ;;  ;;                         (when found-route
    ;;  ;;                           (return-from find-route found-route))))))
    ;;  )
    ))

;; Special case for entity routes included with custom namespaces
(defmethod find-route :around ((name string) (namespace string))
  (call-next-method)
  ;; (if (or (string= namespace "users") (string= namespace "posts"))
  ;;     ;; For users and posts namespaces, look in the entity routes
  ;;     (let ((entity-routes (gethash "entity" *routess*)))
  ;;       (when entity-routes
  ;;         (with-routes (entity-routes)
  ;;           (let ((found-route (find name (children-routes *current-routes*)
  ;;                                    :key #'route-name
  ;;                                    :test #'string=)))
  ;;             (if found-route
  ;;                 found-route
  ;;                 (call-next-method))))))
  ;;     (call-next-method))
  )

(defun find-matching-route (url)
  "Find a route that matches the given URL."
  (error "Remake without routess")
  ;; (let ((parts (split-sequence #\/ url :remove-empty-subseqs t)))
  ;;   (cond
  ;;     ((null parts)
  ;;      ;; Root URL - find the app index route
  ;;      (let ((result nil)
  ;;            (app-routes (gethash "app" *routess*)))
  ;;        (when app-routes
  ;;          (with-routes (app-routes)
  ;;            (let ((routes (children-routes *current-routes*)))
  ;;              (setf result (find-if (lambda (r)
  ;;                                      (and (string= (route-name r) "index")
  ;;                                           (string= (route-namespace r) "app")))
  ;;                                    routes)))))
  ;;        result))
  ;;     (t
  ;;      ;; Non-root URL - find a route in the namespace
  ;;      (let* ((namespace (first parts))
  ;;             (result nil)
  ;;             (namespace-routes (gethash namespace *routess*)))
  ;;        (when namespace-routes
  ;;          (with-routes (namespace-routes)
  ;;            (let ((routes (children-routes *current-routes*)))
  ;;              (setf result (find-if (lambda (r)
  ;;                                      (match-url r url))
  ;;                                    routes)))))
  ;;        result))))
  )
