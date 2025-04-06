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
                #:with-routes-context
                #:*current-namespace*
                #:find-route
                #:get-breadcrumbs
                #:route-method))
(in-package #:40ants-routes-tests/core)

;; Define test routes for a blog library
(defroutes (*blog-routes* :namespace "blog")
  (get ("/" :name "index" :title "Blog")
       (format nil "Blog index"))
  (get ("/<string:slug>" :name "post" :title "Post")
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

(deftest test-route-definition ()
  (testing "Route collections are created correctly"
    (ok *blog-routes* "Blog routes collection exists")
    (ok *admin-routes* "Admin routes collection exists")
    (ok *app-routes* "App routes collection exists"))
  
  (testing "HTTP methods are set correctly"
    (ok (eq (route-method (find-route "index" "blog")) :get) "Blog index route is GET")
    (ok (eq (route-method (find-route "users" "admin")) :post) "Admin users route is POST")
    (ok (eq (route-method (find-route "user" "admin")) :get) "Admin user route is GET")
    (ok (eq (route-method (find-route "user-update" "admin")) :put) "Admin user update route is PUT")))

(deftest test-url-generation ()
  (testing "Basic URL generation"
    (ok (string= (route-url "index" :namespace "app") "/")
        "App index URL is correct")
    (ok (string= (route-url "index" :namespace "blog") "/blog/")
        "Blog index URL is correct")
    (ok (string= (route-url "post" :namespace "blog" :slug "hello-world") "/blog/hello-world")
        "Blog post URL is correct")
    (ok (string= (route-url "user" :namespace "admin" :id 123) "/admin/users/123")
        "Admin user URL is correct")))

(deftest test-namespace-context ()
  (testing "URL generation with namespace context"
    (with-routes-context "app"
      (ok (string= (route-url "index") "/")
          "App index URL is correct in app context")
      (ok (string= (route-url "index" :namespace "blog") "/blog/")
          "Blog index URL is correct in app context"))
    
    (with-routes-context "blog"
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
    (let ((crumbs (get-breadcrumbs "/admin/users/123")))
      (ok (= (length crumbs) 4) "Breadcrumbs have correct length")
      (ok (string= (caar crumbs) "/") "First breadcrumb is root")
      (ok (string= (caadr crumbs) "/admin") "Second breadcrumb is admin")
      (ok (string= (caaddr crumbs) "/admin/users") "Third breadcrumb is users")
      (ok (string= (caar (last crumbs)) "/admin/users/123") "Last breadcrumb is user profile"))))
