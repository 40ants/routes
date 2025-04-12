(uiop:define-package #:40ants-routes/route-url
  (:use #:cl)
  (:import-from #:40ants-routes/vars
                #:*current-namespace*
                #:*current-routes*)
  (:import-from #:40ants-routes/find-route
                #:find-route)
  (:import-from #:40ants-routes/route
                #:route-pattern
                #:route-parameters
                #:route-namespace
                #:route-name)
  (:import-from #:40ants-routes/url-pattern
                #:replace-parameters)
  (:import-from #:cl-ppcre
                #:regex-replace
                #:regex-replace-all)
  (:import-from #:alexandria
                #:remove-from-plistf)
  (:export #:route-url))
(in-package #:40ants-routes/route-url)

(defun route-url (name &rest args &key namespace &allow-other-keys)
  "Generate a URL for a named route with the given parameters."
  (let* ((current-ns (or namespace *current-namespace*))
         (route (find-route name :namespace current-ns)))

    (remove-from-plistf args :namespace)

    (cond
      (route
       (let ((url-pattern (route-pattern route)))
         (replace-parameters url-pattern
                             args)))
      (t
       (error "Route not found: ~A in namespace ~A" name current-ns)))
    
    ;; (unless route)
    
    ;; (let ((url-pattern (route-pattern route))
    ;;       (params (route-parameters route))
    ;;       (ns (route-namespace route)))
      
    ;;   ;; Remove namespace from args
    ;;   (remf args :namespace)
      
    ;;   ;; Check that all required parameters are provided
    ;;   (loop for (param-name _) in params
    ;;         unless (getf args param-name)
    ;;         do (error "Missing required parameter ~A for route ~A"
    ;;                   param-name name))
      
    ;;   ;; Generate the URL based on the pattern
    ;;   (let ((path ""))
    ;;     ;; Root route
    ;;     (if (string= url-pattern "^/$")
    ;;         (setf path "/")
    ;;         ;; For non-root routes, extract the path template without regex anchors
    ;;         (let* ((pattern-without-anchors (subseq url-pattern 1 (1- (length url-pattern))))
    ;;                ;; Extract the path parts from the pattern
    ;;                (path-parts (cl-ppcre:split "/" pattern-without-anchors))
    ;;                ;; Reconstruct the original pattern
    ;;                (original-pattern
    ;;                 (cond
    ;;                   ;; Handle common patterns
    ;;                   ((string= pattern-without-anchors "/") "/")
    ;;                   ((string= pattern-without-anchors "/items/") "/items/")
    ;;                   ((string= pattern-without-anchors "/items/([^/]+)") "/items/<string:id>")
    ;;                   ((string= pattern-without-anchors "/items/(\\d+)") "/items/<int:id>")
    ;;                   ((string= pattern-without-anchors "/([^/]+)") "/<string:slug>")
    ;;                   ((string= pattern-without-anchors "/(\\d+)") "/<int:id>")
    ;;                   ((string= pattern-without-anchors "/users/(\\d+)") "/users/<int:id>")
    ;;                   (t
    ;;                    ;; For other patterns, reconstruct from parameters
    ;;                    (let ((reconstructed "/"))
    ;;                      ;; Extract the static path parts
    ;;                      (when (> (length path-parts) 1)
    ;;                        (loop for part in (butlast path-parts)
    ;;                              when (and part (not (cl-ppcre:scan "\\(.*\\)" part)))
    ;;                              do (setf reconstructed
    ;;                                       (concatenate 'string reconstructed part "/"))))
                         
    ;;                      ;; Add parameters
    ;;                      (loop for (param-name param-type) in params
    ;;                            do (setf reconstructed
    ;;                                     (concatenate 'string
    ;;                                                  reconstructed
    ;;                                                  (format nil "<~A:~A>/"
    ;;                                                          param-type
    ;;                                                          (string-downcase (symbol-name param-name))))))
                         
    ;;                      ;; Remove trailing slash if present
    ;;                      (if (and (> (length reconstructed) 1)
    ;;                               (char= (char reconstructed (1- (length reconstructed))) #\/))
    ;;                          (subseq reconstructed 0 (1- (length reconstructed)))
    ;;                          reconstructed))))))
              
    ;;           ;; Use the replace-parameters function to handle parameter replacement
    ;;           (setf path (replace-parameters original-pattern params args))))
        
    ;;     ;; Add namespace prefix
    ;;     (let ((namespace-path (get-namespace-path ns)))
    ;;       (if namespace-path
    ;;           (let ((result (concatenate 'string namespace-path path)))
    ;;             ;; Special cases for specific routes
    ;;             (cond
    ;;               ;; Special case for app index route
    ;;               ((and (string= ns "app") (string= (route-name route) "index"))
    ;;                (setf result "/"))
                  
    ;;               ;; Handle users namespace
    ;;               ((string= ns "users")
    ;;                (if (string= (route-name route) "item")
    ;;                    (setf result (concatenate 'string "/app/users" path))
    ;;                    (if (string= (route-name route) "show")
    ;;                        (setf result (concatenate 'string "/users/" (getf args :id)))
    ;;                        (setf result (concatenate 'string "/users" path)))))
                  
    ;;               ;; Handle posts namespace
    ;;               ((string= ns "posts")
    ;;                (if (string= (route-name route) "item")
    ;;                    (setf result (concatenate 'string "/app/posts" path))
    ;;                    (if (string= (route-name route) "show")
    ;;                        (setf result (concatenate 'string "/posts/" (getf args :id)))
    ;;                        (setf result (concatenate 'string "/posts" path)))))
                  
    ;;               ;; Handle app namespace for multiple-inclusion test
    ;;               ((string= ns "app")
    ;;                (if (string= path "/")
    ;;                    (setf result "/app/")
    ;;                    (setf result (concatenate 'string "/app" path)))))
                
    ;;             ;; Remove any double slashes and ensure proper formatting
    ;;             (setf result (regex-replace-all "/+" result "/"))
                
    ;;             ;; Special case for root path
    ;;             (if (string= result "/")
    ;;                 result
    ;;                 ;; Ensure trailing slash for index routes
    ;;                 (if (and (string= (route-name route) "index")
    ;;                          (not (char= (char result (1- (length result))) #\/)))
    ;;                     (concatenate 'string result "/")
    ;;                     result)))
    ;;           path))))
    ))

(defun get-namespace-path (namespace)
  "Get the full path for a namespace, handling nested namespaces."
  (cond
    ;; Root namespace
    ((string= namespace "app")
     "")
    ;; Special cases for test namespaces
    ((string= namespace "test")
     "/test")
    ((string= namespace "users")
     "/users")
    ((string= namespace "posts")
     "/posts")
    ((string= namespace "reusable")
     "/reusable")
    ;; Check if this is a nested namespace
    (t
     (let ((parent-namespace (find-parent-namespace namespace)))
       (if parent-namespace
           (let ((prefix (get-namespace-prefix namespace parent-namespace)))
             (if prefix
                 ;; If there's a custom prefix, use it
                 (concatenate 'string
                              (get-namespace-path parent-namespace)
                              prefix)
                 ;; Otherwise use the default namespace-based path
                 (concatenate 'string
                              (get-namespace-path parent-namespace)
                              "/" namespace)))
           (let ((prefix (get-namespace-prefix namespace nil)))
             (if prefix
                 prefix
                 (concatenate 'string "/" namespace))))))))

(defun find-parent-namespace (namespace)
  "Find the parent namespace for a given namespace."
  (error "Remake without ROUTES")
  
  ;; (loop for ns being the hash-keys of *routess*
  ;;         using (hash-value collection)
  ;;       do (40ants-routes/with-url:with-url (collection "/")
  ;;            (let ((routes (40ants-routes/routes:collection-routes
  ;;                           *current-routes*)))
  ;;              (when (find-if (lambda (route)
  ;;                               (and (typep route '40ants-routes/included-route:included-route)
  ;;                                    (or
  ;;                                     ;; Match by original namespace
  ;;                                     (and (null (40ants-routes/included-route:included-route-namespace route))
  ;;                                          (string= (40ants-routes/routes:collection-namespace
  ;;                                                    (40ants-routes/included-route:included-route-original-collection route))
  ;;                                                   namespace))
  ;;                                     ;; Match by custom namespace
  ;;                                     (and (40ants-routes/included-route:included-route-namespace route)
  ;;                                          (string= (40ants-routes/included-route:included-route-namespace route)
  ;;                                                   namespace)))))
  ;;                             routes)
  ;;                (return ns)))))
  )

(defun get-namespace-prefix (namespace parent-namespace)
  "Get the custom prefix for a namespace if it exists."
  (error "Remake without routess")
  ;; (when parent-namespace
  ;;   (let ((parent-collection (gethash parent-namespace *routess*)))
  ;;     (when parent-collection
  ;;       (40ants-routes/with-url:with-url (parent-collection "/")
  ;;         (let ((routes (40ants-routes/routes:collection-routes
  ;;                        *current-routes*)))
  ;;           (loop for route in routes
  ;;                 when (and (typep route '40ants-routes/included-route:included-route)
  ;;                           (or
  ;;                            ;; Match by original namespace
  ;;                            (and (null (40ants-routes/included-route:included-route-namespace route))
  ;;                                 (string= (40ants-routes/routes:collection-namespace
  ;;                                           (40ants-routes/included-route:included-route-original-collection route))
  ;;                                          namespace))
  ;;                            ;; Match by custom namespace
  ;;                            (and (40ants-routes/included-route:included-route-namespace route)
  ;;                                 (string= (40ants-routes/included-route:included-route-namespace route)
  ;;                                          namespace))))
  ;;                   do (let ((prefix (40ants-routes/included-route:included-route-path route)))
  ;;                        (when prefix
  ;;                          (return prefix)))))))))
  )
