(uiop:define-package #:40ants-routes-tests/multiple-inclusion
  (:use #:cl)
  (:import-from #:rove
                #:deftest
                #:ok
                #:testing
                #:ng)
  (:import-from #:40ants-routes
                #:defroutes
                #:get
                #:include
                #:route-url
                #:find-route))
(in-package #:40ants-routes-tests/multiple-inclusion)

;; Define a reusable set of routes
(defroutes (*reusable-routes* :namespace "reusable")
  (get ("/" :name "index" :title "Reusable Index")
       (format nil "Reusable index"))
  (get ("/<string:slug>" :name "item" :title "Reusable Item")
       (format nil "Reusable item: ~A" slug)))

;; Include the same routes twice in one application but with different paths
(defroutes (*app-routes* :namespace "app")
  (get ("/" :name "index" :title "App Index")
       (format nil "App index"))
  
  ;; Include reusable routes as /users/
  (defroutes (*users-routes* :namespace "users")
    (get ("/" :name "index" :title "Users Index")
       (format nil "Users index"))
    (include *reusable-routes*))
  (include *users-routes*)
  
  ;; Include reusable routes as /posts/
  (defroutes (*posts-routes* :namespace "posts")
    (get ("/" :name "index" :title "Posts Index")
       (format nil "Posts index"))
    (include *reusable-routes*))
  (include *posts-routes*))

(deftest test-multiple-inclusion
  (testing "Same routes can be included twice with different paths"
    (ok (find-route "index" "app") "Can find app index route")
    (ok (find-route "index" "users") "Can find users index route")
    (ok (find-route "index" "posts") "Can find posts index route")
    (ok (find-route "index" "reusable") "Can find original reusable index route"))
  
  (testing "route-url resolves correctly for included routes"
    (ok (string= (route-url "index" :namespace "app") "/app/")
        "Can generate URL for app index")
    (ok (string= (route-url "index" :namespace "users") "/app/users/")
        "Can generate URL for users index")
    (ok (string= (route-url "index" :namespace "posts") "/app/posts/")
        "Can generate URL for posts index"))
  
  (testing "route-url resolves correctly for doubly-included routes with parameters"
    (ok (string= (route-url "item" :namespace "reusable" :slug "test") "/reusable/test")
        "Can generate URL for original reusable item")
    (ok (string= (route-url "item" :namespace "users" :slug "test") "/app/users/test")
        "Can generate URL for users' included item")
    (ok (string= (route-url "item" :namespace "posts" :slug "test") "/app/posts/test")
        "Can generate URL for posts' included item")))
