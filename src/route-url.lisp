(uiop:define-package #:40ants-routes/route-url
  (:use #:cl)
  (:import-from #:40ants-routes/vars
                #:*current-namespace*)
  (:import-from #:40ants-routes/find-route
                #:find-route)
  (:import-from #:40ants-routes/route
                #:route-parameters
                #:route-name)
  (:import-from #:40ants-routes/url-pattern
                #:replace-parameters)
  (:import-from #:cl-ppcre
                #:regex-replace
                #:regex-replace-all)
  (:import-from #:alexandria
                #:remove-from-plistf)
  (:import-from #:40ants-routes/generics
                #:format-url
                #:url-path)
  (:import-from #:40ants-routes/utils
                #:make-new-namespace)
  (:export #:route-url))
(in-package #:40ants-routes/route-url)


(defun route-url (name &rest args &key namespace &allow-other-keys)
  "Generate a URL for a named route with the given parameters."
  (let* ((new-namespace (make-new-namespace *current-namespace*
                                            namespace))
         (full-routes-path nil))
    (flet ((on-match (route)
             (push route full-routes-path)))
      (declare (dynamic-extent #'on-match))
      
      (find-route name
                  :namespace new-namespace
                  :on-match #'on-match)
      (when full-routes-path
        (with-output-to-string (s)
          (write-char #\/ s)
          (loop for piece in (nreverse full-routes-path)
                do (format-url piece s args)))))))
