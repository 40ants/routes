(uiop:define-package #:40ants-routes/route-url
  (:use #:cl)
  (:import-from #:40ants-routes/with-routes
                #:*current-namespace*
                #:*current-routes*)
  (:import-from #:40ants-routes/find-route
                #:find-route)
  (:import-from #:40ants-routes/route
                #:route-pattern
                #:route-parameters
                #:route-namespace)
  (:import-from #:cl-ppcre
                #:regex-replace)
  (:export #:route-url))
(in-package #:40ants-routes/route-url)

(defun route-url (name &rest args &key namespace &allow-other-keys)
  "Generate a URL for a named route with the given parameters."
  (let* ((current-ns (or namespace *current-namespace*))
         (route (find-route name current-ns)))
    
    (unless route
      (error "Route not found: ~A in namespace ~A" name current-ns))
    
    (let ((url-pattern (route-pattern route))
          (params (route-parameters route))
          (ns (route-namespace route)))
      
      ;; Remove namespace from args
      (remf args :namespace)
      
      ;; Check that all required parameters are provided
      (loop for (param-name _) in params
            unless (getf args param-name)
            do (error "Missing required parameter ~A for route ~A"
                      param-name name))
      
      ;; Generate the URL based on the pattern
      (let ((path ""))
        ;; Root route
        (if (string= url-pattern "^/$")
            (setf path "/")
            ;; For non-root routes, extract the path template and replace parameters
            (let ((pattern-without-anchors (subseq url-pattern 1 (1- (length url-pattern)))))
              ;; First, replace regex patterns with actual values
              (loop for (param-name param-type) in params
                    for param-value = (getf args param-name)
                    for regex = (cond
                                  ((string= param-type "string") "\\([^/]+\\)")
                                  ((string= param-type "int") "\\(\\\\d\\+\\)")
                                  (t (error "Unknown parameter type: ~A" param-type)))
                    do (setf pattern-without-anchors 
                             (cl-ppcre:regex-replace regex pattern-without-anchors 
                                                    (format nil "~A" param-value))))
              
              ;; Clean up any remaining regex artifacts
              (setf path (cl-ppcre:regex-replace-all "\\\\|\\(|\\)|\\+|\\^|\\$|\\[|\\]" 
                                                    pattern-without-anchors ""))
              
              ;; Ensure the path starts with a slash
              (unless (char= (char path 0) #\/)
                (setf path (concatenate 'string "/" path)))))
        
        ;; Add namespace prefix
        (let ((namespace-path (get-namespace-path ns)))
          (if namespace-path
              (concatenate 'string namespace-path path)
              path))))))

(defun get-namespace-path (namespace)
  "Get the full path for a namespace, handling nested namespaces."
  (cond
    ;; Root namespace
    ((string= namespace "app")
     "")
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
  (loop for ns being the hash-keys of 40ants-routes/with-routes:*route-collections*
        using (hash-value collection)
        do (40ants-routes/with-routes:with-routes (collection)
             (let ((routes (40ants-routes/route-collection:collection-routes 
                            40ants-routes/with-routes:*current-routes*)))
               (when (find-if (lambda (route)
                                (and (typep route '40ants-routes/included-route:included-route)
                                     (or 
                                      ;; Match by original namespace
                                      (and (null (40ants-routes/included-route:included-route-namespace route))
                                           (string= (40ants-routes/route-collection:collection-namespace
                                                     (40ants-routes/included-route:included-route-original-collection route))
                                                    namespace))
                                      ;; Match by custom namespace
                                      (and (slot-boundp route 'namespace)
                                           (slot-value route 'namespace)
                                           (string= (slot-value route 'namespace)
                                                    namespace)))))
                              routes)
                 (return ns))))))

(defun get-namespace-prefix (namespace parent-namespace)
  "Get the custom prefix for a namespace if it exists."
  (when parent-namespace
    (let ((parent-collection (gethash parent-namespace 40ants-routes/with-routes:*route-collections*)))
      (40ants-routes/with-routes:with-routes (parent-collection)
        (let ((routes (40ants-routes/route-collection:collection-routes 
                       40ants-routes/with-routes:*current-routes*)))
          (loop for route in routes
                when (and (typep route '40ants-routes/included-route:included-route)
                          (or 
                           ;; Match by original namespace
                           (and (null (40ants-routes/included-route:included-route-namespace route))
                                (string= (40ants-routes/route-collection:collection-namespace
                                          (40ants-routes/included-route:included-route-original-collection route))
                                         namespace))
                           ;; Match by custom namespace
                           (and (slot-boundp route 'namespace)
                                (slot-value route 'namespace)
                                (string= (slot-value route 'namespace)
                                         namespace))))
                return (if (slot-boundp route 'prefix)
                          (slot-value route 'prefix)
                          "")))))))
