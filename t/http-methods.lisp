(uiop:define-package #:40ants-routes-tests/http-methods
  (:use #:cl)
  (:import-from #:rove
                #:deftest
                #:ok
                #:testing
                #:ng)
  (:import-from #:40ants-routes
                #:defroutes
                #:get
                #:post
                #:put
                #:include
                #:route-url
                #:with-routes-context
                #:*current-namespace*
                #:find-route
                #:route-method))
(in-package #:40ants-routes-tests/http-methods)

;; Define test routes using the new HTTP method format
(defroutes (*http-method-routes* :namespace "test")
  (get ("/" :name "index" :title "Test Index")
       (format nil "Test index page"))
  (post ("/items/" :name "create-item" :title "Create Item")
       (format nil "Create a new item"))
  (get ("/items/<int:id>" :name "view-item" :title "View Item")
       (format nil "View item: ~A" id))
  (put ("/items/<int:id>" :name "update-item" :title "Update Item")
       (format nil "Update item: ~A" id)))

(deftest test-http-methods ()
  (testing "HTTP methods are set correctly"
    (ok (eq (route-method (find-route "index" "test")) :get) 
        "Index route is GET")
    (ok (eq (route-method (find-route "create-item" "test")) :post) 
        "Create item route is POST")
    (ok (eq (route-method (find-route "view-item" "test")) :get) 
        "View item route is GET")
    (ok (eq (route-method (find-route "update-item" "test")) :put) 
        "Update item route is PUT")))

(deftest test-url-generation-with-methods ()
  (testing "URL generation works with HTTP method routes"
    (ok (string= (route-url "index" :namespace "test") "/test/")
        "Test index URL is correct")
    (ok (string= (route-url "create-item" :namespace "test") "/test/items/")
        "Create item URL is correct")
    (ok (string= (route-url "view-item" :namespace "test" :id 123) "/test/items/123")
        "View item URL is correct")
    (ok (string= (route-url "update-item" :namespace "test" :id 456) "/test/items/456")
        "Update item URL is correct")))