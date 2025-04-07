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
            ;; For non-root routes, reconstruct the URL from the original URL pattern
            (let* ((url-parts '())
                   (pattern-parts '()))
              
              ;; Extract the URL pattern from the route definition
              ;; The pattern is in the form "^/path/to/<param-type:param-name>$"
              ;; We need to extract the path parts and replace parameters with their values
              
              ;; Remove the regex anchors (^ and $)
              (let ((pattern (subseq url-pattern 1 (1- (length url-pattern)))))
                ;; Split the pattern by '/'
                (setf pattern-parts (cl-ppcre:split "/" pattern))
                
                ;; Process each part
                (loop for part in pattern-parts
                      when (and part (not (string= part "")))
                      do (cond
                           ;; Parameter part (contains < and >)
                           ((and (cl-ppcre:scan "<" part)
                                 (cl-ppcre:scan ">" part))
                            (let* ((param-type-and-name (cl-ppcre:regex-replace-all "[<>]" part ""))
                                   (type-and-name (cl-ppcre:split ":" param-type-and-name))
                                   (param-type (first type-and-name))
                                   (param-name (intern (string-upcase (second type-and-name)) :keyword))
                                   (param-value (getf args param-name)))
                              (push (format nil "~A" param-value) url-parts)))
                           
                           ;; Regular path part
                           (t (push part url-parts)))))
              
              ;; Construct the final path
              (setf path (format nil "/~{~A~^/~}" (nreverse url-parts)))))
        
        ;; Add namespace prefix if it's not the root namespace
        (if (string= ns "app")
            path
            (concatenate 'string "/" ns path))))))
