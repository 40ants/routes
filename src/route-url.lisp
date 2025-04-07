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
            ;; For non-root routes, reconstruct the URL from the original pattern
            (let* ((original-pattern (route-pattern route))
                   ;; Remove the regex anchors (^ and $)
                   (pattern-without-anchors (subseq original-pattern
                                                   1
                                                   (1- (length original-pattern))))
                   ;; Convert the pattern to a URL template
                   (url-template (let ((template pattern-without-anchors))
                                   ;; For each parameter, replace the regex pattern with a simple placeholder
                                   (loop for (param-name param-type) in params
                                         for regex = (cond
                                                      ((string= param-type "string") "([^/]+)")
                                                      ((string= param-type "int") "(\\\\d+)")
                                                      (t (error "Unknown parameter type: ~A" param-type)))
                                         do (setf template (regex-replace regex template "")))
                                   template)))
              
              ;; Build the path by inserting parameter values in the correct positions
              (let ((parts (cl-ppcre:split "/" url-template))
                    (result '()))
                (dolist (part parts)
                  (push "/" result)
                  (unless (string= part "")
                    (push part result)))
                
                ;; Now insert the parameter values
                (loop for (param-name _) in params
                      for param-value = (getf args param-name)
                      do (push (format nil "~A" param-value) result))
                
                ;; Join all parts to form the final path
                (setf path (apply #'concatenate 'string (nreverse result)))
                ;; Remove any double slashes
                (setf path (cl-ppcre:regex-replace-all "//" path "/")))))
        
        ;; Add namespace prefix if it's not the root namespace
        (if (string= ns "app")
            path
            (concatenate 'string "/" ns path))))))
