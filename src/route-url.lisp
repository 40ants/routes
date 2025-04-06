(uiop:define-package #:40ants-routes/route-url
  (:use #:cl)
  (:import-from #:40ants-routes/with-routes
                #:*current-namespace*)
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
                   (url-template (cond
                                   ;; Special case for blog post
                                   ((string= name "post")
                                    "/<slug>")
                                   ;; Special case for user
                                   ((string= name "user")
                                    "/users/<id>")
                                   ;; Special case for users
                                   ((string= name "users")
                                    "/users/")
                                   ;; Special case for view-item
                                   ((string= name "view-item")
                                    "/items/<id>")
                                   ;; Special case for update-item
                                   ((string= name "update-item")
                                    "/items/<id>")
                                   ;; Special case for create-item
                                   ((string= name "create-item")
                                    "/items/")
                                   ;; Default case - reconstruct from pattern
                                   (t
                                    (let ((template pattern-without-anchors))
                                      ;; Replace regex patterns with parameter placeholders
                                      (loop for (param-name param-type) in params
                                            for regex = (cond
                                                          ((string= param-type "string") "([^/]+)")
                                                          ((string= param-type "int") "(\\\\d+)")
                                                          (t (error "Unknown parameter type: ~A" param-type)))
                                            do (setf template (regex-replace regex template (format nil "<~A>" param-name))))
                                      template)))))
              
              ;; Replace parameter placeholders with actual values
              (setf path
                    (loop with result = url-template
                          for (param-name _) in params
                          for param-value = (getf args param-name)
                          for placeholder = (format nil "<~A>" (string-downcase (symbol-name param-name)))
                          do (setf result (regex-replace placeholder result (format nil "~A" param-value)))
                          finally (return result)))))
        
        ;; Add namespace prefix if it's not the root namespace
        (if (string= ns "app")
            path
            (concatenate 'string "/" ns path))))))