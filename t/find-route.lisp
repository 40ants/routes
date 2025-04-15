(uiop:define-package #:40ants-routes-tests/find-route
  (:use #:cl)
  (:import-from #:rove
                #:ok
                #:testing
                #:deftest)
  (:import-from #:40ants-routes-tests/fixtures
                #:*app-routes*
                #:*blog-routes*
                #:*admin-routes*
                #:*admin-users-routes*)
  (:import-from #:40ants-routes/with-url
                #:with-url)
  (:import-from #:alexandria
                #:length=)
  (:import-from #:40ants-routes/included-routes
                #:original-routes
                #:included-routes-p))
(in-package #:40ants-routes-tests/find-route)


(deftest test-search-routes-with-namespace ()
  (with-url (*app-routes* "/blog/some-post")
    (testing "Blog routes can be found"
      (let ((matched-routes nil))
        (flet ((on-match (route)
                 (push route matched-routes)))
          (let ((result (40ants-routes/find-route::search-routes-with-namespace
                         *app-routes*
                         '("app" "admin" "users")
                         :on-match #'on-match)))
            (ok result)
            (ok (eql result
                     *admin-users-routes*))

            (ok (length= 5 matched-routes))

            (when (length= 5 matched-routes)
              (ok (eql (elt matched-routes 0)
                       *admin-users-routes*))
              (let ((fourth (elt matched-routes 1)))
                (ok (included-routes-p fourth))
                (when (included-routes-p fourth)
                  (ok (eql (original-routes fourth)
                           *admin-users-routes*))))
              (ok (eql (elt matched-routes 2)
                       *admin-routes*))
              (let ((second (elt matched-routes 3)))
                (ok (included-routes-p second))
                (when (included-routes-p second)
                  (ok (eql (original-routes second)
                           *admin-routes*))))
              (ok (eql (elt matched-routes 4)
                       *app-routes*)))))))))
