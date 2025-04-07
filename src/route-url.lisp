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
        
        ;; Add namespace prefix if it's not the root namespace
        (if (string= ns "app")
            path
            (concatenate 'string "/" ns path))))))
