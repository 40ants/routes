(uiop:define-package #:40ants-routes/handler
  (:use #:cl)
  (:import-from #:40ants-routes/vars
                #:*current-routes*)
  (:import-from #:40ants-routes/matched-route
                #:matched-route-p
                #:matched-route-parameters
                #:original-route)
  (:import-from #:40ants-routes/route
                #:route-handler)
  (:export #:call-handler))
(in-package #:40ants-routes/handler)


(defun call-handler ()
  "Calls a handler of current route.

   Should be called only during 40ANTS-ROUTES/WITH-URL:WITH-URL macro body execution."
  (unless (boundp '*current-routes*)
    (error "CALL-HANDLER should be called only during 40ANTS-ROUTES/WITH-URL:WITH-URL macro body execution."))

  (unless (matched-route-p *current-routes*)
    (error "Current route is not of type MATCHED-ROUTE, probably this is a bug in the 40ANTS-ROUTES."))
  (let* ((route (original-route *current-routes*))
         (handler (route-handler route))
         (parameters (matched-route-parameters *current-routes*))
         (parameters-plist (alexandria:alist-plist parameters)))
    (apply handler parameters-plist)))
