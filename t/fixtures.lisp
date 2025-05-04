(uiop:define-package #:40ants-routes-tests/fixtures
  (:use #:cl)
  (:import-from #:serapeum
                #:fmt)
  (:shadowing-import-from #:40ants-routes/defroutes
                          #:defroutes
                          #:get
                          #:post
                          #:put
                          #:include))
(in-package #:40ants-routes-tests/fixtures)


;; Define test routes for a blog library
(defroutes (*blog-routes* :namespace "blog")
  (get ("/" :name "index"
            :title "Blog")
    (fmt "Blog index"))
  (get ("/<string:slug>" :name "post"
                         :title "Post")
    (fmt "Blog post: ~A" slug)))


;; Define test routes for an admin library
(defroutes (*admin-users-routes* :namespace "users")
  (post ("/" :name "users" :title "Users")
    (fmt "Users list"))
  (get ("/<int:id>" :name "user" :title "User Profile")
    (fmt "User profile: ~A" id))
  (put ("/<int:id>" :name "user-update" :title "Update User")
    (fmt "Update user profile: ~A" id)))


(defroutes (*admin-posts-routes* :namespace "posts")
  (post ("/" :name "posts" :title "Posts")
    (fmt "Posts list"))
  (get ("/<string:slug>" :name "post" :title "Post")
    (fmt "Post: ~A" slug)))


(defroutes (*admin-routes* :namespace "admin")
  (get ("/" :name "admin-index" :title "Admin")
    (fmt "Admin index"))
  (include *admin-users-routes*
           :path "/users/")
  (include *admin-posts-routes*
           :path "/posts/"))


;; Define test routes for an application
(defroutes (*app-routes* :namespace "app")
  (get ("/" :name "index" :title "Main Page")
    (fmt "App index"))
  (include *blog-routes*
           :path "/blog/")
  (include *admin-routes*
           :path "/admin/"))


