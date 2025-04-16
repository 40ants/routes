(uiop:define-package #:40ants-routes-tests/add-route
  (:use #:cl)
  (:import-from #:rove
                #:deftest
                #:ok
                #:testing
                #:ng)
  (:import-from #:40ants-routes/routes
                #:routes
                #:children-routes)
  (:import-from #:40ants-routes/generics
                #:url-path
                #:add-route)
  (:import-from #:40ants-routes/route
                #:route-name
                #:route)
  (:import-from #:40ants-routes/url-pattern
                #:url-pattern-pattern
                #:parse-url-pattern)
  (:import-from #:40ants-routes/errors
                #:namespace-duplication-error
                #:path-duplication-error)
  (:import-from #:40ants-routes/defroutes
                #:include)
  (:shadowing-import-from #:40ants-routes/defroutes
                          #:get))
(in-package #:40ants-routes-tests/add-route)


(deftest test-add-route-basic ()
  "Test basic route addition functionality"
  (testing "Adding a route to an empty routes collection"
    (let* ((routes (routes ("app")))
           (route (get ("/test"))))
      (add-route routes
                 route)
      (ok (= (length (children-routes routes)) 1)
          "Route was successfully added")
      (ok (eq (first (children-routes routes)) route)
          "The added route is the same object"))))


(deftest test-add-route-duplicate-path ()
  "Test adding a route with a duplicate path"
  (testing "Adding a route with a duplicate path should signal an error"
    (let* ((routes (routes ("app")))
           (route1 (get ("/test")))
           (route2 (get ("/test" :name "test2"))))
      (add-route routes route1)
      (handler-case
          (progn
            (add-route routes route2)
            (ng t "Should have raised a path-duplication-error"))
        (path-duplication-error ()
          (ok t "Correctly raised path-duplication-error"))))))


(deftest test-add-route-duplicate-namespace ()
  "Test adding included-routes with a duplicate namespace"
  (testing "Adding included-routes with a duplicate namespace should signal an error"
    (let* ((routes (routes ("app")))
           (included1 (include (routes ("blog")
                                 (get ("/")))
                               :path "/blog"))
           ;; Here path is different, but namespace is the same - "blog"
           (included2 (include (routes ("blog")
                                 (get ("/")))
                               :path "/blog2")))
      (add-route routes included1)
      (handler-case
          (progn
            (add-route routes included2)
            (ng t "Should have raised a namespace-duplication-error"))
        (namespace-duplication-error ()
          (ok t "Correctly raised namespace-duplication-error"))))))


(deftest test-add-route-with-override ()
  "Test adding a route with override=true"
  (testing "Adding a route with override=true should replace the existing route"
    (let* ((routes (routes ("app")))
           (route1 (get ("/test" :name "test1")))
           (route2 (get ("/test" :name "test2"))))
      (add-route routes route1)
      (add-route routes route2 :override t)
      (ok (= (length (children-routes routes)) 1)
          "Only one route exists after override")
      (ok (string= (route-name (first (children-routes routes))) "test2")
          "The new route replaced the old one"))))


;; Skip this test for now since it's causing issues
(deftest test-add-included-routes-with-override ()
  "Test adding included-routes with override=true"
  
  (testing "Adding included-routes with a duplicate namespace and override, should replace old included routes"
    (let* ((routes (routes ("app")))
           (included1 (include (routes ("blog")
                                 (get ("/")))
                               :path "/blog/"))
           ;; Here path is different, but namespace is the same - "blog"
           (included2 (include (routes ("blog")
                                 (get ("/")))
                               :path "/blog2/")))
      (add-route routes included1)
      (add-route routes included2 :override t)

      (ok (= (length (children-routes routes)) 1)
          "Only one route exists after override")
      (let ((route-path (url-pattern-pattern
                         (url-path (first (children-routes routes))))))
        (ok (string= route-path
                     "/blog2/")
            "The new route replaced the old one")))))
