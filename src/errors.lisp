(uiop:define-package #:40ants-routes/errors
  (:use #:cl)
  (:export #:no-common-elements-error
           #:full-namespace
           #:relative-namespace
           #:no-route-for-url-error
           #:error-url
           #:namespace-duplication-error
           #:path-duplication-error
           #:url-resolution-error
           #:error-routes-path
           #:argument-missing-error
           #:argument-missing-error-route-name
           #:argument-missing-error-parameter
           #:existing-namespace
           #:existing-route
           #:new-route
           #:existing-path
           #:route-name
           #:namespace))
(in-package #:40ants-routes/errors)


(define-condition no-common-elements-error (error)
  ((full-namespace :initarg :full-namespace
                   :reader full-namespace)
   (relative-namespace :initarg :relative-namespace
                       :reader relative-namespace))
  (:report (lambda (condition stream)
             (format stream "There is no common elements between ~S and ~S namespaces."
                     (full-namespace condition)
                     (relative-namespace condition)))))


(define-condition namespace-duplication-error (error)
  ((namespace :initarg :namespace
              :reader existing-namespace)
   (existing-route :initarg :existing-route
                   :reader existing-route)
   (new-route :initarg :new-route
              :reader new-route))
  (:report (lambda (condition stream)
             (format stream "There is already a ~S route with namespace ~S namespaces, can't add route ~S with same namespace."
                     (existing-route condition)
                     (existing-namespace condition)
                     (new-route condition)))))


(define-condition path-duplication-error (error)
  ((path :initarg :path
         :reader existing-path)
   (existing-route :initarg :existing-route
                   :reader existing-route)
   (new-route :initarg :new-route
              :reader new-route))
  (:report (lambda (condition stream)
             (format stream "There is already a ~S route with path ~S, can't add route ~S with same path."
                     (existing-route condition)
                     (existing-path condition)
                     (new-route condition)))))


(define-condition no-route-for-url-error (error)
  ((url :initarg :url
        :reader error-url)
   (routes-path :initarg :routes-path
                :reader error-routes-path
                :documentation "A path of routes corresponding matching to the prefix of the current URL."))
  (:report (lambda (condition stream)
             (format stream "No route found for URL: ~S"
                     (error-url condition)))))


(define-condition url-resolution-error (error)
  ((route-name :initarg :route-name
               :reader route-name)
   (namespace :initarg :namespace
               :reader namespace))
  (:report (lambda (condition stream)
             (format stream "Unable to find route with name ~S and namespace ~S."
                     (route-name condition)
                     (namespace condition)))))


(define-condition argument-missing-error (error)
 ((route-name :initarg :route-name
              :reader argument-missing-error-route-name)
  (missing-parameter :initarg :missing-parameter
                     :reader argument-missing-error-parameter))
 (:report (lambda (condition stream)
            (format stream "Missing required parameter ~S for route ~S."
                    (argument-missing-error-parameter condition)
                    (argument-missing-error-route-name condition)))))
