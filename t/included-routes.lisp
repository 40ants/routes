(uiop:define-package #:40ants-routes-tests/included-routes
  (:use #:cl)
  (:import-from #:rove
                #:deftest
                #:ok
                #:testing
                #:ng)
  (:shadowing-import-from #:40ants-routes/defroutes
                          #:defroutes
                          #:get
                          #:include)
  (:import-from #:40ants-routes/with-url
                #:with-url)
  (:import-from #:40ants-routes/route-url
                #:route-url)
  (:import-from #:40ants-routes/find-route
                #:find-route)
  (:import-from #:40ants-routes/included-routes
                #:included-routes
                #:included-routes-p
                #:included-routes-original-collection)
  (:import-from #:40ants-routes/vars
                #:*current-routes*)
  (:import-from #:40ants-routes/routes
                #:routes
                #:children-routes)
  (:import-from #:40ants-routes/errors
                #:namespace-duplication-error))
(in-package #:40ants-routes-tests/included-routes)

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
  (include *blog-routes*
           :path "/blog/"))


(deftest test-included-routes ()
  (testing "Include creates an included-routes instance"
    (let* ((routes (children-routes *app-routes*))
           (included (find-if #'included-routes-p
                              routes)))
      (ok included "An included-routes instance was created"))))

(deftest test-route-resolution ()
  (testing "Routes can be found through included-routes"
    (with-url (*app-routes* "/")
      (ok (find-route "index" :namespace '("app" "blog")) "Can find blog index route")
      (ok (string= (route-url "index" :namespace '("app" "blog")) "/blog/")
          "Can generate URL for included route")
      (ok (string= (route-url "post" :namespace '("app" "blog") :slug "hello-world") "/blog/hello-world")
          "Can generate URL for included route with parameters"))))


;; Define a reusable route collection for entities
(defroutes (*entity-routes* :namespace "entity")
  (get ("/" :name "index" :title "All Entities")
       (format nil "List of all entities"))
  (get ("/<string:id>" :name "show" :title "Entity Details")
       (format nil "Entity details: ~A" id)))


;; Define routes that include the entity routes twice with different prefixes and namespaces
;; (defroutes (*multi-include-routes* :namespace "multi-include")
;;   (get ("/" :name "index" :title "Application")
;;     (format nil "Application index"))
;;   (include *entity-routes* :path "/users")
;;   (include *entity-routes* :path "/posts"))


(deftest test-multiple-inclusion ()
  (testing "It should not be possible to include same routes with the same namespace on the single level"

    (ok
     (rove:signals 
         (routes ("multi-include")
           (get ("/" :name "index" :title "Application")
             (format nil "Application index"))
           (include *entity-routes* :path "/users")
           (include *entity-routes* :path "/posts"))
         'namespace-duplication-error))))
