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
                #:get-breadcrumbs)
  (:import-from #:40ants-routes-tests/fixtures
                #:*app-routes*
                #:*blog-routes*
                #:*admin-routes*))
(in-package #:40ants-routes-tests/core)



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
         
         (when route
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
                          expected-method))))))))))


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
             (if (string= url
                        expected-url)
                 (fmt "Route's URL is ~S, as expected."
                      url)
                 (fmt "Route's URL is ~S, but ~S was expected."
                      url
                      expected-url))))))))


(deftest test-simple-route-search ()
  "Test finding routes by name with different namespace configurations."
  (with-url (*app-routes* "/blog/some-post")
    (testing "Blog routes can be found"
      (testing "Without namespace"
        (check-route "index"
                     :expected-method :get)
        (check-route "post"
                     :expected-method :get))
      
      (testing "With absolute namespace"
        (check-route "index"
                     :namespace '("app" "blog")
                     :expected-method :get)
        (check-route "post"
                     :namespace '("app" "blog")
                     :expected-method :get))
      
      (testing "With wrong namespace"
        (check-route "index"
                     :namespace '("bad")
                     :missingp t)
        (check-route "post"
                     :namespace '("bad")
                     :missingp t)))

    (testing "Admin routes can be found"
      (testing "Without namespace it should be impossible"
        (check-route "admin-index"
                     :missingp t))
      
      (testing "With absolute namespace"
        (check-route "admin-index"
                     :namespace '("app" "admin")
                     :expected-method :get)
        (check-route "user-update"
                     :namespace '("app" "admin" "users")
                     :expected-method :put)))))


(deftest test-simple-route-reverse ()
  "Test URL generation for routes with different namespace configurations."
  (with-url (*app-routes* "/blog/some-post")
    (testing "Blog routes can be reversed"
      (check-route-url "index"
                       "/blog/")
      (check-route-url "post"
                       "/blog/foo-bar"
                       :slug "foo-bar"))
  
    (testing "Admin routes can be reversed if absolute namespace given"
      (check-route-url "admin-index"
                       "/admin/"
                       :namespace '("app" "admin"))
      (check-route-url "user-update"
                       "/admin/users/42"
                       :namespace '("app" "admin" "users")
                       :id "42")))
  
  (with-url (*app-routes* "/admin/users/100500")
    (testing "Admin routes can be reversed using relative namespace"
      (check-route-url "admin-index"
                       "/admin/"
                       :namespace '("admin"))
      (check-route-url "post"
                       "/admin/posts/foo-bar"
                       :namespace '("admin" "posts")
                       :slug "foo-bar"))))


(deftest test-route-lookup-by-absolute-namespace ()
  "Test finding routes by absolute namespace."
  (with-url (*app-routes* "/")
    (testing "Lookup by absolute namespaces"
      (check-route "index" :namespace '("app" "blog")
                           :expected-method :get)
      (check-route "users" :namespace '("app" "admin" "users")
                           :expected-method :post)
      (check-route "user" :namespace '("app" "admin" "users")
                          :expected-method :get)
      (check-route "user-update" :namespace '("app" "admin" "users")
                                 :expected-method :put))))


(deftest test-url-generation ()
  "Test basic URL generation with different namespaces."
  (testing "Basic URL generation"
    (with-url (*app-routes* "/")
      (ok (string= (route-url "index")
                   "/")
          "App index URL is correct if no namespace was given")
      (ok (string= (route-url "index" :namespace '("app"))
                   "/")
          "App index URL is correct")
      (ok (string= (route-url "index" :namespace '("app" "blog"))
                   "/blog/")
          "Blog index URL is correct")
      (ok (string= (route-url "post" :namespace '("app" "blog") :slug "hello-world")
                   "/blog/hello-world")
          "Blog post URL is correct")
      (ok (string= (route-url "user" :namespace '("app" "admin" "users") :id 123)
                   "/admin/users/123")
          "Admin user URL is correct"))))


(deftest test-namespace-context ()
  "Test URL generation with different namespace contexts."
  (testing "URL generation with namespace context"
    (with-url (*app-routes* "/")
      (ok (string= (route-url "index")
                   "/")
          "App index URL is correct in app context")
      (ok (string= (route-url "index" :namespace '("app" "blog"))
                   "/blog/")
          "Blog index URL is correct in app context"))
    
    (with-url (*blog-routes* "/")
      (ok (string= (route-url "index")
                   "/")
          "Blog index URL is correct in blog context")
      (ok (string= (route-url "post" :slug "hello-world")
                   "/hello-world")
          "Blog post URL is correct in blog context"))))


(deftest test-parameter-validation ()
  "Test parameter validation for URL generation."
  (testing "Missing parameters cause errors"
    (handler-case
        (progn
          (route-url "post" :namespace '("blog"))
          (ng t "Should have raised an error for missing slug parameter"))
      (error ()
        (ok t "Correctly raised error for missing parameter")))))


(deftest test-breadcrumbs ()
  "Test breadcrumbs generation."
  (testing "Breadcrumbs generation"
    (with-url (*app-routes* "/admin/users/123")
      (let ((crumbs (get-breadcrumbs "/admin/users/123")))
        (ok (= (length crumbs) 4) "Breadcrumbs have correct length")
        (ok (string= (caar crumbs) "/") "First breadcrumb is root")
        (ok (string= (caadr crumbs) "/admin") "Second breadcrumb is admin")
        (ok (string= (caaddr crumbs) "/admin/users") "Third breadcrumb is users")
        (ok (string= (caar (last crumbs)) "/admin/users/123") "Last breadcrumb is user profile")))))
