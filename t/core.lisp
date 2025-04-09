(uiop:define-package #:40ants-routes-tests/core
  (:use #:cl)
  (:import-from #:rove
                #:deftest
                #:ok
                #:testing
                #:ng)
  (:import-from #:40ants-routes
                #:defroutes
                #:url
                #:get
                #:post
                #:put
                #:include
                #:route-url
                #:with-routes
                #:*current-namespace*
                #:find-route
                #:get-breadcrumbs
                #:route-method)
  (:import-from #:serapeum
                #:fmt))
(in-package #:40ants-routes-tests/core)

;; Define test routes for a blog library
(defroutes (*blog-routes* :namespace "blog")
  (get ("/" :name "index"
            :title "Blog")
       (format nil "Blog index"))
  (get ("/<string:slug>" :name "post"
                         :title "Post")
       (format nil "Blog post: ~A" slug)))

;; Define test routes for an admin library
(defroutes (*admin-routes* :namespace "admin")
  (get ("/" :name "index" :title "Admin")
       (format nil "Admin index"))
  (post ("/users/" :name "users" :title "Users")
       (format nil "Users list"))
  (get ("/users/<int:id>" :name "user" :title "User Profile")
       (format nil "User profile: ~A" id))
  (put ("/users/<int:id>" :name "user-update" :title "Update User")
       (format nil "Update user profile: ~A" id)))

;; Define test routes for an application
(defroutes (*app-routes* :namespace "app")
  (get ("/" :name "index" :title "Main Page")
       (format nil "App index"))
  (include *blog-routes*)
  (include *admin-routes*))


(defun check-route (name &key namespace expected-method missingp)
  (testing (if namespace
               (fmt "Checking route ~S with namespace ~S"
                    name
                    namespace)
               (fmt "Checking route ~S without namespace"
                    name))
    (let ((route (find-route name namespace)))
      (cond
        (missingp
         (ng route
             (if route
                 "Route expected to be missing, but it was found"
                 "Route was not found")))
        ;; Should be found
        (t
         (ok route
             (if route
                 "Route was found"
                 "Route was not found"))
         
         (ok (string= (40ants-routes/core:route-name route)
                      name)
             (if (equal (40ants-routes/core:route-name route)
                        name)
                 (fmt "Route's name is ~S, as expected."
                      name)
                 (fmt "Route's name is ~S, but ~S was expected."
                      (40ants-routes/core:route-name route)
                      name)))
         (when namespace
           (ok (string= (40ants-routes/core:route-namespace route)
                        "blog")
               (if (equal (40ants-routes/core:route-namespace route)
                          namespace)
                   (fmt "Route's namespace is ~S as expected"
                        namespace)
                   (fmt "Route's namespace is ~S but ~S was expected."
                        (40ants-routes/core:route-namespace route)
                        namespace))))
         (when expected-method
           (ok (eql (40ants-routes/core:route-method route)
                    expected-method)
               (if (equal (40ants-routes/core:route-method route)
                          expected-method)
                   (fmt "Route's method is ~S as expected"
                        expected-method)
                   (fmt "Route's method is ~S but ~S was expected."
                        (40ants-routes/core:route-method route)
                        expected-method)))))))))


(deftest test-simple-route-search ()
  (testing "Blog routes can be found"
    (with-routes (*blog-routes*)
      (check-route "index"
                   :expected-method :get)
      (check-route "post"
                   :expected-method :get)
      (check-route "index"
                   :namespace "blog"
                   :expected-method :get)
      (check-route "post"
                   :namespace "blog"
                   :expected-method :get)

      (testing "With wrong namespace"
        (check-route "index"
                     :namespace "bad"
                     :missingp t)
        (check-route "post"
                     :namespace "bad"
                     :missingp t)))))


(deftest test-route-definition ()
  (testing "Route collections are created correctly"
    (ok *blog-routes* "Blog routes collection exists")
    (ok *admin-routes* "Admin routes collection exists")
    (ok *app-routes* "App routes collection exists"))
  
  (testing "HTTP methods are set correctly"
    (with-routes (*app-routes*)
      (flet ((check-route (name &key namespace expected-method)
               (testing (if namespace
                            (fmt "Checking route ~S with namespace ~S"
                                 name
                                 namespace)
                            (fmt "Checking route ~S without namespace"
                                 name))
                 (let ((route (find-route name namespace)))
                   (ok (string= (40ants-routes/core:route-name route)
                                name)
                       (fmt "Route's name is ~S, but ~S was expected."
                            (40ants-routes/core:route-name route)
                            name))
                   (when namespace
                     (ok (string= (40ants-routes/core:route-namespace route)
                                  "blog")
                         (fmt "Route's namespace is ~S but ~S was expected."
                              (40ants-routes/core:route-namespace route)
                              namespace)))
                   (when expected-method
                     (ok (eql (40ants-routes/core:route-method route)
                              expected-method)
                         (fmt "Route's method is ~S but ~S was expected."
                              (40ants-routes/core:route-method route)
                              expected-method)))))))
        (check-route "index" :namespace "blog"
                             :expected-method :get)
        (check-route "users" :namespace "admin"
                             :expected-method :post)
        (check-route "user" :namespace "admin"
                            :expected-method :get)
        (check-route "user-update" :namespace "admin"
                                   :expected-method :put)))))


(deftest test-url-generation ()
  (testing "Basic URL generation"
    (with-routes (*app-routes*)
      (ok (string= (route-url "index") "/")
          "App index URL is correct if no namespace was given")
      (ok (string= (route-url "index" :namespace "app") "/")
          "App index URL is correct")
      (ok (string= (route-url "index" :namespace "blog") "/blog/")
          "Blog index URL is correct")
      (ok (string= (route-url "post" :namespace "blog" :slug "hello-world") "/blog/hello-world")
          "Blog post URL is correct")
      (ok (string= (route-url "user" :namespace "admin" :id 123) "/admin/users/123")
          "Admin user URL is correct"))))

(deftest test-namespace-context ()
  (testing "URL generation with namespace context"
    (with-routes (*app-routes*)
      (ok (string= (route-url "index") "/")
          "App index URL is correct in app context")
      (ok (string= (route-url "index" :namespace "blog") "/blog/")
          "Blog index URL is correct in app context"))
    
    (with-routes (*blog-routes*)
      (ok (string= (route-url "index") "/blog/")
          "Blog index URL is correct in blog context")
      (ok (string= (route-url "post" :slug "hello-world") "/blog/hello-world")
          "Blog post URL is correct in blog context"))))

(deftest test-parameter-validation ()
  (testing "Missing parameters cause errors"
    (handler-case
        (progn
          (route-url "post" :namespace "blog")
          (ng t "Should have raised an error for missing slug parameter"))
      (error ()
        (ok t "Correctly raised error for missing parameter")))))

(deftest test-breadcrumbs ()
  (testing "Breadcrumbs generation"
    (with-routes (*app-routes*)
      (let ((crumbs (get-breadcrumbs "/admin/users/123")))
        (ok (= (length crumbs) 4) "Breadcrumbs have correct length")
        (ok (string= (caar crumbs) "/") "First breadcrumb is root")
        (ok (string= (caadr crumbs) "/admin") "Second breadcrumb is admin")
        (ok (string= (caaddr crumbs) "/admin/users") "Third breadcrumb is users")
        (ok (string= (caar (last crumbs)) "/admin/users/123") "Last breadcrumb is user profile")))))
