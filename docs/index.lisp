(uiop:define-package #:40ants-routes-docs/index
  (:use #:cl)
  (:import-from #:40ants-doc
                #:defsection
                #:defsection-copy)
  (:import-from #:40ants-routes/with-url
                #:with-url)
  (:import-from #:40ants-routes/handler
                #:call-handler)
  (:import-from #:40ants-routes/defroutes
                #:defroutes
                #:include)
  (:import-from #:40ants-routes/route-url
                #:route-url)
  (:import-from #:40ants-doc/autodoc
                #:defautodoc)
  (:import-from #:docs-config
                #:docs-config)
  (:export #:@index
           #:@readme))
(in-package #:40ants-routes-docs/index)


(defparameter *disable-linter-for-these-imports*
  '(route-url with-url defroutes call-handler))


(defmethod docs-config ((system (eql (asdf:find-system "40ants-routes-docs"))))
  ;; 40ANTS-DOC-THEME-40ANTS system will bring
  ;; as dependency a full 40ANTS-DOC but we don't want
  ;; unnecessary dependencies here:
  #+quicklisp
  (uiop:symbol-call :ql :quickload
                    "40ants-doc-theme-40ants")
  #-quicklisp
  (asdf:load-system "40ants-doc-theme-40ants")
  
  (list :theme
        (find-symbol "40ANTS-THEME"
                     (find-package "40ANTS-DOC-THEME-40ANTS"))))

(defsection @index (:title "40ants-routes - Framework agnostic URL routing library"
                    :ignore-words ("JSON"
                                   "HTTP"
                                   "URL"
                                   "REPL"
                                   "POST"
                                   "PUT"
                                   "GET"
                                   "ASDF"
                                   "API"
                                   "HTML"
                                   "TODO"
                                   "Unlicense"))
  "
## Overview

40ants-routes is a framework-agnostic URL routing library for Common Lisp, inspired by Django's URL routing system. It provides a clean and flexible way to define URL routes, generate URLs, and handle URL parameters.

## Features

* Defining routes with namespaces.
* Including routes from libraries into applications.
* Matching URL while extracting parameters from it.
* Generating URLs based on route names.
* Generating breadcrumbs.

## Installation

```lisp
(ql:quickload :40ants-routes)
```
"
  (@usage section)
  (@api section))


(40ants-doc:defsection-copy @readme @index)


(defsection @defining-routes (:title "Defining Routes")
  "Routes can be defined using the 40ANTS-ROUTES/DEFROUTES:DEFROUTES macro.

   Inside it's body, use 40ANTS-ROUTES/DEFROUTES:GET, 40ANTS-ROUTES/DEFROUTES:POST, macro
   to define final routes in the collection.

   ```

   (uiop:define-package #:test-routes
     (:use #:cl)
     (:shadowing-import-from #:40ants-routes/defroutes
                             #:defroutes
                             #:include
                             #:get
                             #:post)
     (:import-from #:40ants-routes/route-url
                   #:route-url)
     (:import-from #:40ants-routes/handler
                   #:call-handler)
     (:import-from #:40ants-routes/with-url
                   #:with-partially-matched-url
                   #:with-url))
   (in-package #:test-routes)

   (defroutes (*blog-routes* :namespace \"blog\")
     (get (\"/\" :name \"index\")
          (format t \"Handler for blog index was called.\"))
     (get (\"/<string:slug>\" :name \"post\")
          (format t \"Handler for blog post ~S was called.\"
                  slug)))
   ```

   Routes, defined by this 40ANTS-ROUTES/DEFROUTES:DEFROUTES are stored in `*blog-routes*` variable
   and can be used either to 40ANTS-ROUTES/DEFROUTES:INCLUDE these routes into the route hierarchy,
   or to search a route, matched to the URL. See section @MATCHING-THE-URL.

   Here's an example demonstrating how to use an integer URL parameter:

   ```lisp
   (defroutes (*article-routes* :namespace \"articles\")
     (get (\"/\" :name \"index\")
          (format t \"Handler for articles index was called.\"))
     (get (\"/<int:id>\" :name \"article\")
          (format t \"Handler for article with ID ~D was called.\"
                  id)))
   ```

   In this example, the route will match URLs like `/123` and the argument ID will be parsed as an integer.

   You can also capture the rest of the URL as a parameter using the `.*` regex pattern:

   ```lisp
   (defroutes (*file-routes* :namespace \"files\")
     (get (\"/\" :name \"index\")
          (format t \"Handler for files index was called.\"))
     (get (\"/<.*:path>\" :name \"file\")
          (format t \"Handler for file at path ~S was called.\"
                  path)))
   ```

   This will match URLs like `/documents/reports/annual/2023.pdf` and capture the entire path
   `documents/reports/annual/2023.pdf` as the PATH argument.
")


(defsection @including-routes (:title "Including Routes")
  "Routes from libraries can be included in application routes using
   40ANTS-ROUTES/DEFROUTES:INCLUDE function.

   This way they can form a hyerarchy:

   ```lisp
   (defroutes (*app-routes* :namespace \"app\")
     (get (\"/\" :name \"index\")
          (format t \"Handler for application's index page.\"))
     (include *blog-routes*
              :path \"/blog/\"))
   ```

   In it's turn, `*blog-routes*` might also include other routes itself.

   This allows to build a composable web-applications and libraries. For example,
   some library might build routes to show the list of objects, show details about an object,
   edit it and delete. Then such routes can be included into a more complex application.
")


(defsection @matching-the-url (:title "Matching the URL")
  "Imagine, user have opened the URL with a path like this `/blog/some-post`.

   Then in your web-application you might setup the context in which this route
   processing should happen. Use 40ANTS-ROUTES/WITH-URL:WITH-URL or 40ANTS-ROUTES/WITH-URL:WITH-PARTIALLY-MATCHED-URL
   macros to setup the context. Inside the context you can use CALL-HANDLER function to call
   a body of the route, matched to the URL:


   ```lisp

   TEST-ROUTES> (with-url (*app-routes* \"/blog/some-post\")
                  (call-handler))
   Handler for blog post \"some-post\" was called.

   TEST-ROUTES> (with-url (*app-routes* \"/blog/\")
                  (call-handler))
   Handler for blog index was called.

   TEST-ROUTES> (with-url (*app-routes* \"/\")
                  (call-handler))
   Handler for application's index page.

   ```

   40ANTS-ROUTES/WITH-URL:WITH-URL will signal 40ANTS-ROUTES/ERRORS:NO-ROUTE-FOR-URL-ERROR
   error if there is no route matching the whole URL, but 40ANTS-ROUTES/WITH-URL:WITH-PARTIALLY-MATCHED-URL will
   try to do the best it can.

   So, inside the 40ANTS-ROUTES/WITH-URL:WITH-URL body you can use CALL-HANDLER
   always, while inside the 40ANTS-ROUTES/WITH-URL:WITH-PARTIALLY-MATCHED-URL macro handler should be called only if
   40ANTS-ROUTES/ROUTE:CURRENT-ROUTE-P function returns T.
")


(defsection @generating-urls (:title "Generating URLs")
  "Another feature of `40ants-routes` is URL generation.
   URLs can be generated using the 40ANTS-ROUTES/ROUTE-URL:ROUTE-URL function. Like
   CALL-HANDLER, it should be called when URL context is available.

   In our application routes tree there are two `index` routes, but we can get paths to both of them
   using namespaces. Route's namespace is defined as a list of names from the root route, given
   to the WITH-URL macro up to the matched route. Each DEFROUTES form or a call to INCLUDE form
   create an object having the name. These names are added to the current route's namespace.

   Imagine we are on the blog-post page and we want to get path to all blog posts. Easiest way
   to do this, is to call ROUTE-URL function with only route name:

   ```lisp
   TEST-ROUTES> (with-url (*app-routes* \"/blog/some-post\")
                  (route-url \"index\"))
   \"/blog/\"
   ```

   But this will not work if the user is on the root page:

   ```lisp
   TEST-ROUTES> (with-url (*app-routes* \"/\")
                  (route-url \"index\"))
   \"/\"
   ```

   You might want to make URL resolution more stable, especially if these URLs are used in some common
   page parts such as header or footer. In this case, help URL resolver by giving it a namespace:

   ```lisp
   TEST-ROUTES> (with-url (*app-routes* \"/\")
                  (route-url \"index\"
                             :namespace '(\"app\" \"blog\")))
   \"/blog/\"
   ```

   Note, when you are building a reusable component which creates it's own 40ANTS-ROUTES/ROUTES:ROUTES
   object, you should not use these absolute namespaces, because you don't know beforehand which namespace
   will be used by user when including the component's routes.

   Let's update our blog component routes and add one to edit the blog post:

   ```lisp
   TEST-ROUTES> (defroutes (*blog-routes* :namespace \"blog\")
                  (get (\"/\" :name \"index\")
                    (format t \"Handler for blog index was called.\"))
                  (get (\"/<string:slug>\" :name \"post\")
                    (format t \"Handler for blog post ~S was called.~
                               To edit post go to ~S.\"
                            slug
                            (route-url \"edit-post\"
                                       :slug slug)))
                  (get (\"/<string:slug>/edit\" :name \"edit-post\")
                    (format t \"Handler for blog post ~S edit form was called.\"
                            slug)))
   #<40ANTS-ROUTES/ROUTES:ROUTES \"blog\" 3 subroutes>
   ```

   Note, how we did use ROUTE-URL inside the `/<string:slug>` handler to get
   path to the post edit page.

   Now, let's try to call this handler when this blog's routes are included
   into the application routes:

   ```lisp
   TEST-ROUTES> (with-url (*app-routes* \"/blog/some-post\")
                  (call-handler))
   Handler for blog post \"some-post\" was called.To edit post go to \"/blog/some-post/edit\".
   ```

   See, it did return `/blog/some-post/edit` path to the edit page and there wasn't need to specify
   a namespace at all!
")


(defsection @generating-breadcrumbs (:title "Generating Breadcrumbs")
  "Breadcrumbs can be generated using the 40ANTS-ROUTES/BREADCRUMBS:GET-BREADCRUMBS function. This function returns a list of 40ANTS-ROUTES/BREADCRUMBS:BREADCRUMB objects that represent the path from the root to the current page.

Each 40ANTS-ROUTES/BREADCRUMBS:BREADCRUMB object has the following properties:
- The URL path to the breadcrumb (accessible via 40ANTS-ROUTES/BREADCRUMBS:BREADCRUMB-PATH)
- The display title for the breadcrumb (accessible via 40ANTS-ROUTES/BREADCRUMBS:BREADCRUMB-TITLE)
- The route object associated with the breadcrumb (accessible via 40ANTS-ROUTES/BREADCRUMBS:BREADCRUMB-ROUTE)

To use breadcrumbs, you need to define routes with titles:

```lisp

(defroutes (*admin-users-routes* :namespace \"users\")
  (post (\"/\" :name \"users\"
         :title \"Users\")
    (format nil \"Users list\"))
  (get (\"/<string:username>\"
        :name \"user\"
        :title \"User Profile\")
    (format nil \"User profile: ~A\" username)))


(defroutes (*admin-routes* :namespace \"admin\")
  (get (\"/\" :name \"admin-index\" :title \"Admin\")
    (format nil \"Admin index\"))
  (include *admin-users-routes*
           :path \"/users/\"))


(defroutes (*app-routes* :namespace \"app\")
  (get (\"/\" :name \"index\" :title \"Home\")
    (format nil \"App index\"))
  (include *admin-routes*
           :path \"/admin/\"))

```

Then, you can generate breadcrumbs for a specific URL:

```lisp

TEST-ROUTES> (with-url (*app-routes* \"/admin/users/john\")
               (let ((crumbs (40ants-routes/breadcrumbs:get-breadcrumbs)))
                 ;; This way you can get all paths or titles:
                 (values
                  (mapcar #'40ants-routes/breadcrumbs:breadcrumb-path crumbs)
                  (mapcar #'40ants-routes/breadcrumbs:breadcrumb-title crumbs))))
(\"/\" \"/admin/\" \"/admin/users/\" \"/admin/users/john\")
(\"Home\" \"Admin\" \"Users\" \"User Profile\")

```

or to generate an HTML code like this:

```lisp

TEST-ROUTES> (with-url (*app-routes* \"/admin/users/john\")
               (let ((crumbs (40ants-routes/breadcrumbs:get-breadcrumbs)))
                 (format t \"<nav aria-label=\\\"breadcrumb\\\">~%\")
                 (format t \"  <ol class=\\\"breadcrumb\\\">~%\")
                 (loop for crumb in crumbs
                       for last-p = (eq crumb (car (last crumbs)))
                       do (format t \"    <li class=\\\"breadcrumb-item~:[~; active~]\\\"~:[~; aria-current=\\\"page\\\"~]>~%\" 
                                  last-p last-p)
                          (if last-p
                              (format t \"      ~A~%\" (40ants-routes/breadcrumbs:breadcrumb-title crumb))
                              (format t \"      <a href=\\\"~A\\\">~A</a>~%\" 
                                      (40ants-routes/breadcrumbs:breadcrumb-path crumb) 
                                      (40ants-routes/breadcrumbs:breadcrumb-title crumb)))
                          (format t \"    </li>~%\"))
                 (format t \"  </ol>~%\")
                 (format t \"</nav>~%\")))
<nav aria-label=\"breadcrumb\">
  <ol class=\"breadcrumb\">
    <li class=\"breadcrumb-item\">
      <a href=\"/\">Home</a>
    </li>
    <li class=\"breadcrumb-item\">
      <a href=\"/admin/\">Admin</a>
    </li>
    <li class=\"breadcrumb-item\">
      <a href=\"/admin/users/\">Users</a>
    </li>
    <li class=\"breadcrumb-item active\" aria-current=\"page\">
      User Profile
    </li>
  </ol>
</nav>

```

For more advanced usage, you can also use functions as route titles to generate dynamic titles based on URL parameters. This is demonstrated in the test file:

First, you need to define a function which will accept an arguments extracted from URL:

```lisp
(defun get-user-name (&key username &allow-other-keys)
  \"A function for retrieving user display names based on username parameter\"
  (cond
    ((string= username \"john\")
     \"John Smith\")
    ((string= username \"jane\")
     \"Jane Doe\")
    (t
     (format nil \"User: ~A\" username))))
```

Then redefine routes, to use this function as TITLE argument of the route:

```
(defroutes (*admin-users-routes* :namespace \"users\")
  (post (\"/\" :name \"users\" :title \"Users\")
    (format nil \"Users list\"))
  (get (\"/<string:username>\"
        :name \"user\"
        ;; Example of using a function for retrieving
        ;; route title dynamically at runtime:
        :title #'get-user-name)
    (format nil \"User profile: ~A\" username)))
```

And now you will get a real user's name as the last breadcrumb title:

```lisp

TEST-ROUTES> (with-url (*app-routes* \"/admin/users/john\")
               (let ((crumbs (40ants-routes/breadcrumbs:get-breadcrumbs)))
                 (values
                  (mapcar #'40ants-routes/breadcrumbs:breadcrumb-path crumbs)
                  (mapcar #'40ants-routes/breadcrumbs:breadcrumb-title crumbs))))
(\"/\" \"/admin/\" \"/admin/users/\" \"/admin/users/john\")
(\"Home\" \"Admin\" \"Users\" \"John Smith\")

```

This makes it easy to create meaningful breadcrumb navigation that adapts to the content being displayed.")


(defsection @usage (:title "Usage Examples")
  (@defining-routes section)
  (@including-routes section)
  (@matching-the-url section)
  (@generating-urls section)
  (@generating-breadcrumbs section))


(defautodoc @api (:title "API Reference"
                  :system "40ants-routes"))

