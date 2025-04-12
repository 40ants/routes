(uiop:define-package #:40ants-routes/with-url
  (:use #:cl)
  (:import-from #:serapeum
                #:->)
  (:import-from #:40ants-routes/routes
                #:routesp
                #:routes)
  (:import-from #:40ants-routes/route
                #:route)
  (:import-from #:40ants-routes/included-route
                #:included-route)
  (:import-from #:40ants-routes/vars
                #:*routes-path*
                #:*current-routes*)
  (:import-from #:40ants-routes/generics
                #:match-url)
  (:export
   #:with-url))
(in-package #:40ants-routes/with-url)


(-> find-route-for-url ((or routes
                            route
                            included-route)
                        string)
    (values (or route
                included-route)
            (serapeum:soft-list-of (or route
                                       included-route))
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
                       (last routes-path))))
      
          (values matched-route
                  filtered-routes-path)))))



(defmacro with-url ((root-routes url) &body body)
  "Execute body with the current routes object corresponding to a given URL argument."
  (let ((root-routes-var (gensym "ROOT-ROUTES")))
    `(let* ((,root-routes-var ,root-routes))
       (multiple-value-bind (*current-routes* *routes-path*)
           (find-route-for-url ,root-routes-var
                               ,url)
         ,@body))))
