(uiop:define-package #:40ants-routes-tests/included-route
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
                #:find-route
                #:included-route-original-collection))
(in-package #:40ants-routes-tests/included-route)

;; Define test routes for a blog library
(defroutes (*blog-routes* :namespace "blog")
  (get ("/" :name "index" :title "Blog")
       (format nil "Blog index"))
  (get ("/<string:slug>" :name "post" :title "Post")
       (format nil "Blog post: ~A" slug)))

;; Define test routes for an application
(defroutes (*app-routes* :namespace "app")
  (get ("/" :name "index" :title "Main Page")
       (format nil "App index"))
  (include *blog-routes*))

(deftest test-included-route ()
  (testing "Include creates an included-route instance"
    (let ((app-routes (gethash "app" 40ants-routes/with-routes::*route-collections*)))
      (40ants-routes:with-routes (app-routes)
        (let* ((routes (40ants-routes::collection-routes 40ants-routes:*current-routes*))
               (included (find-if (lambda (route)
                                    (typep route '40ants-routes:included-route))
                                  routes)))
          (ok included "An included-route instance was created")
          (when included
            (ok (eq (40ants-routes:included-route-original-collection included) *blog-routes*)
                "The original-collection is correctly set")))))))

(deftest test-route-resolution ()
  (testing "Routes can be found through included-route"
    (ok (find-route "index" "blog") "Can find blog index route")
    (ok (string= (route-url "index" :namespace "blog") "/blog/")
        "Can generate URL for included route")
    (ok (string= (route-url "post" :namespace "blog" :slug "hello-world") "/blog/hello-world")
        "Can generate URL for included route with parameters")))
