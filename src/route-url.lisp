(uiop:define-package #:40ants-routes/route-url
  (:use #:cl)
  (:import-from #:40ants-routes/vars
                #:*current-namespace*)
  (:import-from #:40ants-routes/find-route
                #:find-route)
  (:import-from #:40ants-routes/generics
                #:format-url
                #:url-path)
  (:import-from #:40ants-routes/utils
                #:make-new-namespace)
  (:import-from #:serapeum
                #:soft-list-of
                #:->)
  (:import-from #:40ants-routes/errors
                #:url-resolution-error)
  (:export #:route-url))
(in-package #:40ants-routes/route-url)


(-> route-url (string &key (:namespace (or string
                                           (soft-list-of string)))
               &allow-other-keys)
    (values string
            &optional))

(defun route-url (name &rest args &key namespace &allow-other-keys)
  "Generate a URL for a named route with the given parameters."
  (let* ((new-namespace (make-new-namespace *current-namespace*
                                            (uiop:ensure-list namespace)))
         (full-routes-path nil))
    (flet ((on-match (route)
             (push route full-routes-path)))
      (declare (dynamic-extent #'on-match))
      
      (let ((matched-route
              (find-route name
                          :namespace new-namespace
                          :on-match #'on-match)))
        (cond
          ((and matched-route full-routes-path)
           (with-output-to-string (s)
             (write-char #\/ s)
             (loop for 40ants-routes/vars::*current-route* in (nreverse full-routes-path)
                   do (format-url 40ants-routes/vars::*current-route* s args))))
          (t
           (error 'url-resolution-error
                  :route-name name
                  :namespace namespace)))))))
