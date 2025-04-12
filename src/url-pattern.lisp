(uiop:define-package #:40ants-routes/url-pattern
  (:use #:cl)
  (:import-from #:cl-ppcre
                #:scan
                #:scan-to-strings
                #:regex-replace
                #:regex-replace-all)
  (:import-from #:serapeum
                #:->)
  (:import-from #:str
                #:trim-right
                #:replace-all)
  (:import-from #:40ants-routes/generics)
  ;; (:export #:parse-url-pattern
  ;;          #:match-url
  ;;          #:replace-parameters)
  )
(in-package #:40ants-routes/url-pattern)


(defclass url-pattern ()
  ((pattern :initarg :pattern
            :type string
            :reader url-pattern-pattern)
   (regex :initarg :regex
          :type string
          :reader url-pattern-regex)
   (params :initarg :params
           :type list
           :documentation "Alist with parameter types"
           :reader url-pattern-params)))


(defmethod print-object ((obj url-pattern) stream)
  (print-unreadable-object (obj stream :type t)
    (format stream "~S"
            (url-pattern-pattern obj))))


(-> parse-url-pattern (string)
    (values url-pattern &optional))

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
    
    (make-instance 'url-pattern
                   :pattern pattern
                   :regex regex-pattern
                   :params (nreverse params))))

(-> match-url (url-pattern string &key (:partialp boolean))
    (values boolean
            list
            (or null integer)
            &optional))

(defun match-url (pattern url &key partialp)
  "Match a URL against a route.

   Returns three values where:

   - first will be T if pattern was matched
   - the second value is parameter values alist
   - and the third one is position of the character right after the matched piece of URL

   If PARTIALP argument is T then full match is required and the third returned
   value will be equal to a URL length."
  
  (let ((pattern (let ((res (url-pattern-regex pattern)))
                   (if partialp
                       (trim-right res :char-bag "$")
                       res)))
        (params (url-pattern-params pattern)))
    (multiple-value-bind (match-start match-end reg-starts reg-ends)
        (scan pattern url)
      (cond
        (match-start
         (let ((param-values nil))
           (loop for reg-start across reg-starts
                 for reg-end across reg-ends
                 for (param-name param-type) in params
                 do (push (cons param-name 
                                (if (string= param-type "int")
                                    (parse-integer url
                                                   :start reg-start
                                                   :end reg-end)
                                    (subseq url reg-start reg-end)))
                          param-values))
           (values t
                   (nreverse param-values)
                   match-end)))
        (t
         (values nil
                 nil
                 nil))))))


(-> replace-parameters (url-pattern list)
    (values string &optional))

(defun replace-parameters (url-pattern args)
  "Replace parameters in a URL pattern with their values.
   url-pattern: The original URL pattern (e.g., '/<string:slug>')
   params: List of parameter specifications ((name type) ...)
   args: Property list of parameter values (:name value ...)"
  (loop with params = (url-pattern-params url-pattern)
        with pattern = (url-pattern-pattern url-pattern)
        with result = pattern
        for (param-name param-type) in params
        for param-value = (getf args param-name)
        when param-value
          do (let ((param-with-type
                     (format nil "<~A:~A>"
                             param-type
                             (string-downcase (symbol-name param-name)))))
               (setf result (replace-all param-with-type
                                         (princ-to-string param-value)
                                         result)))
        finally (return result)))


(defmethod 40ants-routes/generics::match-url ((obj url-pattern) (url string))
  (when (match-url obj url)
    (values obj)))


(defmethod 40ants-routes/generics::partial-match-url ((obj url-pattern) (url string))
  (multiple-value-bind (matched-obj parameters end-position)
      (match-url obj url :partialp t)
    (declare (ignore parameters))
    (values matched-obj
            end-position)))
