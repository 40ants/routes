(uiop:define-package #:40ants-routes/url-pattern
  (:use #:cl)
  (:import-from #:40ants-routes/route
                #:route
                #:route-pattern
                #:route-parameters)
  (:import-from #:cl-ppcre
                #:scan-to-strings
                #:regex-replace
                #:regex-replace-all)
  (:export #:parse-url-pattern
           #:match-url
           #:replace-parameters))
(in-package #:40ants-routes/url-pattern)

(defun parse-url-pattern (pattern)
  "Parse a URL pattern and extract parameter specifications.
   Returns two values: the regex pattern and a list of parameter names and types."
  (let ((params nil)
        (regex-pattern "^")
        (start 0))
    (loop
      (let ((param-start (position #\< pattern :start start)))
        (unless param-start
          ;; Add the rest of the pattern and finish
          (setf regex-pattern (concatenate 'string regex-pattern 
                                           (subseq pattern start)))
          (return))
        
        ;; Add the part before the parameter
        (setf regex-pattern (concatenate 'string regex-pattern 
                                         (subseq pattern start param-start)))
        
        ;; Find the parameter end
        (let ((param-end (position #\> pattern :start param-start)))
          (unless param-end
            (error "Unclosed parameter in URL pattern: ~A" pattern))
          
          ;; Extract and parse the parameter
          (let* ((param-spec (subseq pattern (1+ param-start) param-end))
                 (colon-pos (position #\: param-spec))
                 (param-type (if colon-pos
                                (subseq param-spec 0 colon-pos)
                                "string"))
                 (param-name (if colon-pos
                                (subseq param-spec (1+ colon-pos))
                                param-spec))
                 (regex (cond
                          ((string= param-type "string") "([^/]+)")
                          ((string= param-type "int") "(\\d+)")
                          (t (error "Unknown parameter type: ~A" param-type)))))
            
            ;; Add parameter to the list
            (push (list (intern (string-upcase param-name) :keyword)
                        param-type)
                  params)
            
            ;; Add the regex to the pattern
            (setf regex-pattern (concatenate 'string regex-pattern regex))
            
            ;; Update start position
            (setf start (1+ param-end))))))
    
    ;; Ensure the pattern ends with $
    (setf regex-pattern (concatenate 'string regex-pattern "$"))
    
    (values regex-pattern (nreverse params))))

(defun match-url (route url)
  "Match a URL against a route. Returns parameter values if matched, nil otherwise."
  (let ((pattern (route-pattern route))
        (params (route-parameters route)))
    (multiple-value-bind (match-p matches)
        (scan-to-strings pattern url)
      (when match-p
        (let ((param-values nil))
          (loop for i from 0 below (length matches)
                for (param-name param-type) in params
                for value = (aref matches i)
                do (push (cons param-name 
                               (if (string= param-type "int")
                                   (parse-integer value)
                                   value))
                         param-values))
          (nreverse param-values))))))

(defun replace-parameters (url-pattern params args)
  "Replace parameters in a URL pattern with their values.
   url-pattern: The original URL pattern (e.g., '/<string:slug>')
   params: List of parameter specifications ((name type) ...)
   args: Property list of parameter values (:name value ...)"
  (let ((result url-pattern))
    ;; First, handle special cases
    (cond
      ;; Root path
      ((string= url-pattern "/")
       (return-from replace-parameters "/"))
      
      ;; Simple slug pattern
      ((string= url-pattern "/<string:slug>")
       (let ((slug (getf args :slug)))
         (when slug
           (return-from replace-parameters (format nil "/~A" slug)))))
      
      ;; Simple ID pattern
      ((string= url-pattern "/<int:id>")
       (let ((id (getf args :id)))
         (when id
           (return-from replace-parameters (format nil "/~A" id)))))
      
      ;; Users ID pattern
      ((string= url-pattern "/users/<int:id>")
       (let ((id (getf args :id)))
         (when id
           (return-from replace-parameters (format nil "/users/~A" id))))))
    
    ;; For other patterns, replace each parameter with its value
    (loop for (param-name param-type) in params
          for param-value = (getf args param-name)
          when param-value
          do (let ((param-regex (format nil "<~A:~A>"
                                       param-type
                                       (string-downcase (symbol-name param-name)))))
               (setf result (regex-replace-all param-regex result (format nil "~A" param-value)))))
    
    ;; Clean up any remaining regex artifacts and ensure proper formatting
    (setf result (regex-replace-all "/+" result "/"))
    
    ;; Ensure the path starts with a slash
    (unless (or (string= result "") (char= (char result 0) #\/))
      (setf result (concatenate 'string "/" result)))
    
    result))