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
            ;; For non-root routes, reconstruct the URL from the pattern
            (let* ((pattern-parts (cl-ppcre:split "/" url-pattern))
                   (url-parts '()))
              
              ;; Process each part of the URL pattern
              (loop for part in pattern-parts
                    when (and part (not (string= part "")))
                    do (let ((processed-part part))
                         ;; Check if this part contains a parameter
                         (loop for (param-name param-type) in params
                               for param-value = (getf args param-name)
                               for param-regex = (cond
                                                  ((string= param-type "string") "\\([^/]+\\)")
                                                  ((string= param-type "int") "\\(\\\\d\\+\\)")
                                                  (t (error "Unknown parameter type: ~A" param-type)))
                               when (cl-ppcre:scan param-regex processed-part)
                               do (setf processed-part (format nil "~A" param-value)))
                         
                         ;; Remove regex anchors and escapes
                         (setf processed-part (cl-ppcre:regex-replace-all "\\^|\\$|\\\\|\\(|\\)" processed-part ""))
                         
                         ;; Add to URL parts
                         (push processed-part url-parts)))
              
              ;; Construct the final path
              (setf path (format nil "/~{~A/~}" (nreverse url-parts)))
              
              ;; Remove trailing slash for non-root paths
              (when (and (> (length path) 1)
                         (char= (char path (1- (length path))) #\/))
                (setf path (subseq path 0 (1- (length path)))))))
        
        ;; Add namespace prefix if it's not the root namespace
        (if (string= ns "app")
            path
            (concatenate 'string "/" ns path))))))
