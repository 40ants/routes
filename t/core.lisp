(uiop:define-package #:40ants-routes-tests/core
  (:use #:cl)
  (:import-from #:rove
                #:deftest
                #:ok
                #:testing
                #:ng)
  (:shadowing-import-from #:40ants-routes/defroutes
                          #:defroutes
                          #:get
                          #:post
                          #:put
                          #:include)
  (:import-from #:serapeum
                #:fmt)
  (:import-from #:alexandria
                #:remove-from-plistf)
  (:import-from #:40ants-routes/route
                #:route-method
                #:route-name)
  (:import-from #:40ants-routes/vars
                #:*current-routes*)
  (:import-from #:40ants-routes/find-route
                #:find-route)
  (:import-from #:40ants-routes/route-url
                #:route-url)
  (:import-from #:40ants-routes/with-url
                #:with-url)
  (:import-from #:40ants-routes/breadcrumbs
                #:get-breadcrumbs))
(in-package #:40ants-routes-tests/core)


;; Define test routes for a blog library
(defroutes (*blog-routes*)
  (get ("/" :name "index"
            :title "Blog")
    (fmt "Blog index"))
  (get ("/<string:slug>" :name "post"
                         :title "Post")
    (fmt "Blog post: ~A" slug)))


;; Define test routes for an admin library
(defroutes (*admin-routes*)
  (get ("/" :name "admin-index" :title "Admin")
    (fmt "Admin index"))
  (post ("/users/" :name "users" :title "Users")
    (fmt "Users list"))
  (get ("/users/<int:id>" :name "user" :title "User Profile")
    (fmt "User profile: ~A" id))
  (put ("/users/<int:id>" :name "user-update" :title "Update User")
    (fmt "Update user profile: ~A" id)))


;; Define test routes for an application
(defroutes (*app-routes*)
  (get ("/" :name "index" :title "Main Page")
    (fmt "App index"))
  (include *blog-routes*
           :path "/blog/"
           :namespace "blog")
  (include *admin-routes*
           :path "/admin/"
           :namespace "admin"))


(defun check-route (name &key namespace expected-method missingp)
  (testing (if namespace
               (fmt "Checking route ~S with namespace ~S"
                    name
                    namespace)
               (fmt "Checking route ~S without namespace"
                    name))
    (let ((route (find-route name :namespace namespace)))
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
         
         (ok (string= (route-name route)
                      name)
             (if (equal (route-name route)
                        name)
                 (fmt "Route's name is ~S, as expected."
                      name)
                 (fmt "Route's name is ~S, but ~S was expected."
                      (route-name route)
                      name)))
         
         (when expected-method
           (ok (eql (route-method route)
                    expected-method)
               (if (equal (route-method route)
                          expected-method)
                   (fmt "Route's method is ~S as expected"
                        expected-method)
                   (fmt "Route's method is ~S but ~S was expected."
                        (route-method route)
                        expected-method)))))))))


(defun check-route-url (name expected-url &rest args &key namespace missingp &allow-other-keys)
  (remove-from-plistf args
                      :missingp)
  
  (testing (if namespace
               (fmt "Checking url for route ~S with namespace ~S"
                    name
                    namespace)
               (fmt "Checking url for route ~S without namespace"
                    name))
    (let ((url (apply #'route-url
                      name
                      args)))
      (cond
        (missingp
         (ng url
             (if url
                 "URL expected to be missing, but it was found"
                 "URL was not found")))
        ;; Should be found
        (t
         (ok url
             (if url
                 "URL was found"
                 "URL was not found"))
         
         (ok (string= url
                      expected-url)
             (if (equal url
                        name)
                 (fmt "Route's URL is ~S, as expected."
                      url)
                 (fmt "Route's URL is ~S, but ~S was expected."
                      url
                      expected-url))))))))


(deftest test-simple-route-search ()
  (with-url (*app-routes* "/blog/some-post")
    (testing "Blog routes can be found"
      (testing "Without namespace"
        (check-route "index"
                     :expected-method :get)
        (check-route "post"
                     :expected-method :get))
      
      (testing "With absolute namespace"
        (check-route "index"
                     :namespace '(:absolute "blog")
                     :expected-method :get)
        (check-route "post"
                     :namespace '(:absolute "blog")
                     :expected-method :get))
      
      (testing "With wrong namespace"
        (check-route "index"
                     :namespace '(:absolute "bad")
                     :missingp t)
        (check-route "post"
                     :namespace '(:absolute "bad")
                     :missingp t)))

    (testing "Admin routes can be found"
      (testing "Without namespace it should be impossible"
        (check-route "admin-index"
                     :missingp t))
      
      (testing "With absolute namespace"
        (check-route "admin-index"
                     :namespace '(:absolute "admin")
                     :expected-method :get)
        (check-route "user-update"
                     :namespace '(:absolute "admin")
                     :expected-method :put)))))


(deftest test-simple-route-reverse ()
  (testing "Blog routes can be reversed"
    (with-url (*app-routes* "/blog/some-post")
      (check-route-url "index"
                       "/blog/")
      (check-route-url "post"
                       "/blog/foo-bar"
                       :slug "foo-bar")))
  
  ;; (testing "Admin routes can be reversed if absolute namespace given"
  ;;   (with-url (*app-routes* "/blog/some-post")
  ;;     (check-route-url "adminindex"
  ;;                      "/")
  ;;     (check-route-url "post"
  ;;                      "/foo-bar"
  ;;                      :slug "foo-bar")))
  )

(deftest test-with-url ()
  (testing "Checking if current-route will be set to the route of \"user\" inside admin interface"
    (with-url (*app-routes* "/admin/users/100500")
      (ok (typep *current-routes*
                 '40ants-routes/route:route)))))


(deftest test-route-lookup-by-absolute-namespace ()
  (with-url (*app-routes* "/")
    (flet ((check-route (name &key namespace expected-method)
             (testing (if namespace
                          (fmt "Checking route ~S with namespace ~S"
                               name
                               namespace)
                          (fmt "Checking route ~S without namespace"
                               name))
               (let ((route (find-route name :namespace namespace)))
                 (ok (string= (route-name route)
                              name)
                     (fmt "Route's name is ~S, but ~S was expected."
                          (route-name route)
                          name))
                 ;; namespace was removed from ROUTE class, because
                 ;; route's namespace defined by included-routes
                 ;; (when namespace
                 ;;   (ok (string= (route-namespace route)
                 ;;                "blog")
                 ;;       (fmt "Route's namespace is ~S but ~S was expected."
                 ;;            (route-namespace route)
                 ;;            namespace)))
                 (when expected-method
                   (ok (eql (route-method route)
                            expected-method)
                       (fmt "Route's method is ~S but ~S was expected."
                            (route-method route)
                            expected-method)))))))
      (testing "Lookup by absolute namespaces"
        (check-route "index" :namespace '("blog")
                             :expected-method :get)
        (check-route "users" :namespace '("admin")
                             :expected-method :post)
        (check-route "user" :namespace '("admin")
                            :expected-method :get)
        (check-route "user-update" :namespace '("admin")
                                   :expected-method :put)))))


(deftest test-url-generation ()
  (testing "Basic URL generation"
    (with-url (*app-routes* "/")
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
    (with-url (*app-routes* "/")
      (ok (string= (route-url "index") "/")
          "App index URL is correct in app context")
      (ok (string= (route-url "index" :namespace "blog") "/blog/")
          "Blog index URL is correct in app context"))
    
    (with-url (*blog-routes* "/")
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
    (with-url (*app-routes* "/admin/users/123")
      (let ((crumbs (get-breadcrumbs "/admin/users/123")))
        (ok (= (length crumbs) 4) "Breadcrumbs have correct length")
        (ok (string= (caar crumbs) "/") "First breadcrumb is root")
        (ok (string= (caadr crumbs) "/admin") "Second breadcrumb is admin")
        (ok (string= (caaddr crumbs) "/admin/users") "Third breadcrumb is users")
        (ok (string= (caar (last crumbs)) "/admin/users/123") "Last breadcrumb is user profile")))))
