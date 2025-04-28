(uiop:define-package #:40ants-routes/with-url
  (:use #:cl)
  (:import-from #:serapeum
                #:->)
  (:import-from #:40ants-routes/errors
                #:no-route-for-url-error)
  (:import-from #:40ants-routes/routes
                #:routesp
                #:routes)
  (:import-from #:40ants-routes/route
                #:route)
  (:import-from #:40ants-routes/included-routes
                #:included-routes-p
                #:included-routes)
  (:import-from #:40ants-routes/vars
                #:*current-namespace*
                #:*routes-path*
                #:*current-route*)
  (:import-from #:40ants-routes/generics
                #:has-namespace-p
                #:node-namespace
                #:match-url)
  (:import-from #:40ants-routes/matched-route
                #:matched-route)
  (:export
   #:with-url
   #:with-partially-matched-url))
(in-package #:40ants-routes/with-url)


(-> find-route-for-url ((or routes
                            route
                            included-routes)
                        string)
    (values (or matched-route
                included-routes
                null)
            (serapeum:soft-list-of (or matched-route
                                       included-routes))
            (serapeum:soft-list-of string)
            &optional))

(defun find-route-for-url (routes url)
  "Searches a route matching URL.

   URL can match some nested route."
  (let ((routes-path nil))
    (flet ((collect-matched-route (route)
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
                       (last routes-path)))
             (namespace
               (loop for route in filtered-routes-path
                     when (has-namespace-p route)
                       collect (node-namespace route))))

        (values matched-route
                filtered-routes-path
                (nreverse namespace))))))


(defun call-with-url (root-routes url thunk)
  (multiple-value-bind (matched-route routes-path namespace)
      (find-route-for-url root-routes
                          url)
    (unless matched-route
      (error 'no-route-for-url-error
             :url url
             :routes-path routes-path))
    
    (let ((*current-route* matched-route)
          (*routes-path* routes-path)
          (*current-namespace* namespace))
      (funcall thunk))))


(defmacro with-url ((root-routes url) &body body)
  "Execute body with the current routes object corresponding to a given URL argument."
  `(flet ((thunk-with-url ()
            ,@body))
     (declare (dynamic-extent #'thunk-with-url))
     (call-with-url ,root-routes ,url #'thunk-with-url)))


(defun call-with-partially-matched-url (root-routes url thunk)
  (multiple-value-bind (matched-route routes-path namespace)
      (find-route-for-url root-routes
                          url)
    (let ((names-to-bind
            (list '*routes-path*
                  '*current-namespace*))
          (values-to-bind
            (list routes-path
                  namespace)))
      ;; Here we will bind *current-route* only if route was found:
      (when matched-route
        (push '*current-route* names-to-bind)
        (push matched-route values-to-bind))
      (progv names-to-bind values-to-bind
        (funcall thunk)))))


(defmacro with-partially-matched-url ((root-routes url) &body body)
  "Execute body with the current routes object corresponding to a given URL argument.

   Difference between this macro and WITH-URL macro is that WITH-URL signals an error
   if it is unable to find a leaf route matching to the whole URL.

   WITH-PARTIALLY-MATCHED-URL will try to find a routes path matching as much
   of URL as possible. As the result, 40ANTS-ROUTES/ROUTE:CURRENT-ROUTE-P function
   might return NIL when URL was not fully matched by WITH-PARTIALLY-MATCHED-URL.
   "
  `(flet ((thunk-with-partially-matched-url ()
            ,@body))
     (declare (dynamic-extent #'thunk-with-partially-matched-url))
     (call-with-partially-matched-url ,root-routes ,url
                                      #'thunk-with-partially-matched-url)))
