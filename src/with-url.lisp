(uiop:define-package #:40ants-routes/with-url
  (:use #:cl)
  (:import-from #:serapeum
                #:->)
  (:import-from #:40ants-routes/routes
                #:routesp
                #:routes)
  (:import-from #:40ants-routes/route
                #:route)
  (:import-from #:40ants-routes/included-routes
                #:included-routes)
  (:import-from #:40ants-routes/vars
                #:*current-namespace*
                #:*routes-path*
                #:*current-routes*)
  (:import-from #:40ants-routes/generics
                #:match-url)
  (:import-from #:40ants-routes/matched-route
                #:matched-route)
  (:export
   #:with-url))
(in-package #:40ants-routes/with-url)


(-> find-route-for-url ((or routes
                            route
                            included-routes)
                        string)
    (values (or matched-route
                included-routes)
            (serapeum:soft-list-of (or matched-route
                                       included-routes))
            (serapeum:soft-list-of string)
            &optional))

(defun find-route-for-url (routes url)
  "Searches a route matching URL.

   URL can match some nested route."
  (let ((routes-path nil)
        (namespace nil))
    (flet ((collect-matched-route (route)
             (when (typep route 'routes)
               (push (40ants-routes/routes::routes-namespace route)
                     namespace))
             (push route routes-path)))
      (declare (dynamic-extent #'collect-matched-route))

      (let* ((matched-route (match-url routes url
                                       :on-match #'collect-matched-route))
             ;; Now we need to remove all ROUTES collection
             ;; except the last one, because it is enough to have
             ;; INCLUDED-ROUTES only:
             (filtered-routes-path
               (append (remove-if #'routesp
                                  (butlast routes-path))
                       (last routes-path))))
      
          (values matched-route
                  filtered-routes-path
                  (nreverse namespace))))))


(defun call-with-url (root-routes url thunk)
  (multiple-value-bind (*current-routes* *routes-path* *current-namespace*)
      (find-route-for-url root-routes
                          url)
    (funcall thunk)))


(defmacro with-url ((root-routes url) &body body)
  "Execute body with the current routes object corresponding to a given URL argument."
  `(flet ((thunk-with-url ()
            ,@body))
     (declare (dynamic-extent #'thunk-with-url))
     (call-with-url ,root-routes ,url #'thunk-with-url)))
