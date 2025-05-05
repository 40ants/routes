<a id="x-2840ANTS-ROUTES-DOCS-2FINDEX-3A-40README-2040ANTS-DOC-2FLOCATIVES-3ASECTION-29"></a>

# 40ants-routes - Framework agnostic URL routing library

<a id="overview"></a>

## Overview

40ants-routes is a framework-agnostic `URL` routing library for Common Lisp, inspired by Django's `URL` routing system. It provides a clean and flexible way to define `URL` routes, generate `URL`s, and handle `URL` parameters.

<a id="features"></a>

## Features

* Defining routes with namespaces.
* Including routes from libraries into applications.
* Matching `URL` while extracting parameters from it.
* Generating `URL`s based on route names.
* Generating breadcrumbs (Work In Progress!).

<a id="installation"></a>

## Installation

```lisp
(ql:quickload :40ants-routes)
```
<a id="x-2840ANTS-ROUTES-DOCS-2FINDEX-3A-3A-40USAGE-2040ANTS-DOC-2FLOCATIVES-3ASECTION-29"></a>

## Usage Examples

<a id="x-2840ANTS-ROUTES-DOCS-2FINDEX-3A-3A-40DEFINING-ROUTES-2040ANTS-DOC-2FLOCATIVES-3ASECTION-29"></a>

### Defining Routes

Routes can be defined using the [`40ants-routes/defroutes:defroutes`][3455] macro.

Inside it's body, use [`40ants-routes/defroutes:get`][f902], [`40ants-routes/defroutes:post`][a861], macro
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

(defroutes (*blog-routes* :namespace "blog")
  (get ("/" :name "index")
       (format t "Handler for blog index was called."))
  (get ("/<string:slug>" :name "post")
       (format t "Handler for blog post ~S was called."
               slug)))
```
Routes, defined by this [`40ants-routes/defroutes:defroutes`][3455] are stored in `*blog-routes*` variable
and can be used either to [`40ants-routes/defroutes:include`][2897] these routes into the route hierarchy,
or to search a route, matched to the `URL`. See section [`Marching the URL`][af0d].

Here's an example demonstrating how to use an integer `URL` parameter:

```lisp
(defroutes (*article-routes* :namespace "articles")
  (get ("/" :name "index")
       (format t "Handler for articles index was called."))
  (get ("/<int:id>" :name "article")
       (format t "Handler for article with ID ~D was called."
               id)))
```
In this example, the route will match `URL`s like `/123` and the argument `ID` will be parsed as an integer.

You can also capture the rest of the `URL` as a parameter using the `.*` regex pattern:

```lisp
(defroutes (*file-routes* :namespace "files")
  (get ("/" :name "index")
       (format t "Handler for files index was called."))
  (get ("/<.*:path>" :name "file")
       (format t "Handler for file at path ~S was called."
               path)))
```
This will match `URL`s like `/documents/reports/annual/2023.pdf` and capture the entire path
`documents/reports/annual/2023.pdf` as the `PATH` argument.

<a id="x-2840ANTS-ROUTES-DOCS-2FINDEX-3A-3A-40INCLUDING-ROUTES-2040ANTS-DOC-2FLOCATIVES-3ASECTION-29"></a>

### Including Routes

Routes from libraries can be included in application routes using
[`40ants-routes/defroutes:include`][2897] function.

This way they can form a hyerarchy:

```lisp
(defroutes (*app-routes* :namespace "app")
  (get ("/" :name "index")
       (format t "Handler for application's index page."))
  (include *blog-routes*
           :path "/blog/"))
```
In it's turn, `*blog-routes*` might also include other routes itself.

This allows to build a composable web-applications and libraries. For example,
some library might build routes to show the list of objects, show details about an object,
edit it and delete. Then such routes can be included into a more complex application.

<a id="x-2840ANTS-ROUTES-DOCS-2FINDEX-3A-3A-40MATCHING-THE-URL-2040ANTS-DOC-2FLOCATIVES-3ASECTION-29"></a>

### Marching the URL

Imagine, user have opened the `URL` with a path like this `/blog/some-post`.

Then in your web-application you might setup the context in which this route
processing should happen. Use [`40ants-routes/with-url:with-url`][1c5e] or [`40ants-routes/with-url:with-partially-matched-url`][1a23]
macros to setup the context. Inside the context you can use [`call-handler`][e530] function to call
a body of the route, matched to the `URL`:

```lisp

TEST-ROUTES> (with-url (*app-routes* "/blog/some-post")
               (call-handler))
Handler for blog post "some-post" was called.

TEST-ROUTES> (with-url (*app-routes* "/blog/")
               (call-handler))
Handler for blog index was called.

TEST-ROUTES> (with-url (*app-routes* "/")
               (call-handler))
Handler for application's index page.
```
[`40ants-routes/with-url:with-url`][1c5e] will signal [`40ants-routes/errors:no-route-for-url-error`][2977]
error if there is no route matching the whole `URL`, but [`40ants-routes/with-url:with-partially-matched-url`][1a23] will
try to do the best it can.

So, inside the [`40ants-routes/with-url:with-url`][1c5e] body you can use [`call-handler`][e530]
always, while inside the [`40ants-routes/with-url:with-partially-matched-url`][1a23] macro handler should be called only if
[`40ants-routes/route:current-route-p`][087c] function returns T.

<a id="x-2840ANTS-ROUTES-DOCS-2FINDEX-3A-3A-40GENERATING-URLS-2040ANTS-DOC-2FLOCATIVES-3ASECTION-29"></a>

### Generating URLs

Another feature of `40ants-routes` is `URL` generation.
`URL`s can be generated using the [`40ants-routes/route-url:route-url`][fe8a] function. Like
[`call-handler`][e530], it should be called when `URL` context is available.

In our application routes tree there are two `index` routes, but we can get paths to both of them
using namespaces. Route's namespace is defined as a list of names from the root route, given
to the [`with-url`][1c5e] macro up to the matched route. Each [`defroutes`][3455] form or a call to [`include`][2897] form
create an object having the name. These names are added to the current route's namespace.

Imagine we are on the blog-post page and we want to get path to all blog posts. Easiest way
to do this, is to call [`route-url`][fe8a] function with only route name:

```lisp
TEST-ROUTES> (with-url (*app-routes* "/blog/some-post")
               (route-url "index"))
"/blog/"
```
But this will not work if the user is on the root page:

```lisp
TEST-ROUTES> (with-url (*app-routes* "/")
               (route-url "index"))
"/"
```
You might want to make `URL` resolution more stable, especially if these `URL`s are used in some common
page parts such as header or footer. In this case, help `URL` resolver by giving it a namespace:

```lisp
TEST-ROUTES> (with-url (*app-routes* "/")
               (route-url "index"
                          :namespace '("app" "blog")))
"/blog/"
```
Note, when you are building a reusable component which creates it's own `40ants-routes/routes:routes` ([`1`][77f9] [`2`][cce3])
object, you should not use these absolute namespaces, because you don't know beforehand which namespace
will be used by user when including the component's routes.

Let's update our blog component routes and add one to edit the blog post:

```lisp
TEST-ROUTES> (defroutes (*blog-routes* :namespace "blog")
               (get ("/" :name "index")
                 (format t "Handler for blog index was called."))
               (get ("/<string:slug>" :name "post")
                 (format t "Handler for blog post ~S was called.~
                            To edit post go to ~S."
                         slug
                         (route-url "edit-post"
                                    :slug slug)))
               (get ("/<string:slug>/edit" :name "edit-post")
                 (format t "Handler for blog post ~S edit form was called."
                         slug)))
#<40ANTS-ROUTES/ROUTES:ROUTES "blog" 3 subroutes>
```
Note, how we did use [`route-url`][fe8a] inside the `/<string:slug>` handler to get
path to the post edit page.

Now, let's try to call this handler when this blog's routes are included
into the application routes:

```lisp
TEST-ROUTES> (with-url (*app-routes* "/blog/some-post")
               (call-handler))
Handler for blog post "some-post" was called.To edit post go to "/blog/some-post/edit".
```
See, it did return `/blog/some-post/edit` path to the edit page and there wasn't need to specify
a namespace at all!

<a id="x-2840ANTS-ROUTES-DOCS-2FINDEX-3A-3A-40GENERATING-BREADCRUMBS-2040ANTS-DOC-2FLOCATIVES-3ASECTION-29"></a>

### Generating Breadcrumbs

Breadcrumbs can be generated using the [`40ants-routes/breadcrumbs:get-breadcrumbs`][bd21] function. This function returns a list of [`40ants-routes/breadcrumbs:breadcrumb`][e419] objects that represent the path from the root to the current page.

Each [`40ants-routes/breadcrumbs:breadcrumb`][e419] object has the following properties:
- The `URL` path to the breadcrumb (accessible via [`40ants-routes/breadcrumbs:breadcrumb-path`][3f6e])
- The display title for the breadcrumb (accessible via [`40ants-routes/breadcrumbs:breadcrumb-title`][b28f])
- The route object associated with the breadcrumb (accessible via [`40ants-routes/breadcrumbs:breadcrumb-route`][920e])

To use breadcrumbs, you need to define routes with titles:

```lisp

(defroutes (*admin-users-routes* :namespace "users")
  (post ("/" :name "users"
         :title "Users")
    (format nil "Users list"))
  (get ("/<string:username>"
        :name "user"
        :title "User Profile")
    (format nil "User profile: ~A" username)))


(defroutes (*admin-routes* :namespace "admin")
  (get ("/" :name "admin-index" :title "Admin")
    (format nil "Admin index"))
  (include *admin-users-routes*
           :path "/users/"))


(defroutes (*app-routes* :namespace "app")
  (get ("/" :name "index" :title "Home")
    (format nil "App index"))
  (include *admin-routes*
           :path "/admin/"))
```
Then, you can generate breadcrumbs for a specific `URL`:

```lisp

TEST-ROUTES> (with-url (*app-routes* "/admin/users/john")
               (let ((crumbs (40ants-routes/breadcrumbs:get-breadcrumbs)))
                 ;; This way you can get all paths or titles:
                 (values
                  (mapcar #'40ants-routes/breadcrumbs:breadcrumb-path crumbs)
                  (mapcar #'40ants-routes/breadcrumbs:breadcrumb-title crumbs))))
("/" "/admin/" "/admin/users/" "/admin/users/john")
("Home" "Admin" "Users" "User Profile")
```
or to generate an `HTML` code like this:

```lisp

TEST-ROUTES> (with-url (*app-routes* "/admin/users/john")
               (let ((crumbs (40ants-routes/breadcrumbs:get-breadcrumbs)))
                 (format t "<nav aria-label=\"breadcrumb\">~%")
                 (format t "  <ol class=\"breadcrumb\">~%")
                 (loop for crumb in crumbs
                       for last-p = (eq crumb (car (last crumbs)))
                       do (format t "    <li class=\"breadcrumb-item~:[~; active~]\"~:[~; aria-current=\"page\"~]>~%" 
                                  last-p last-p)
                          (if last-p
                              (format t "      ~A~%" (40ants-routes/breadcrumbs:breadcrumb-title crumb))
                              (format t "      <a href=\"~A\">~A</a>~%" 
                                      (40ants-routes/breadcrumbs:breadcrumb-path crumb) 
                                      (40ants-routes/breadcrumbs:breadcrumb-title crumb)))
                          (format t "    </li>~%"))
                 (format t "  </ol>~%")
                 (format t "</nav>~%")))
<nav aria-label="breadcrumb">
  <ol class="breadcrumb">
    <li class="breadcrumb-item">
      <a href="/">Home</a>
    </li>
    <li class="breadcrumb-item">
      <a href="/admin/">Admin</a>
    </li>
    <li class="breadcrumb-item">
      <a href="/admin/users/">Users</a>
    </li>
    <li class="breadcrumb-item active" aria-current="page">
      User Profile
    </li>
  </ol>
</nav>
```
For more advanced usage, you can also use functions as route titles to generate dynamic titles based on `URL` parameters. This is demonstrated in the test file:

First, you need to define a function which will accept an arguments extracted from `URL`:

```lisp
(defun get-user-name (&key username &allow-other-keys)
  "A function for retrieving user display names based on username parameter"
  (cond
    ((string= username "john")
     "John Smith")
    ((string= username "jane")
     "Jane Doe")
    (t
     (format nil "User: ~A" username))))
```
Then redefine routes, to use this function as `TITLE` argument of the route:

```
(defroutes (*admin-users-routes* :namespace "users")
  (post ("/" :name "users" :title "Users")
    (format nil "Users list"))
  (get ("/<string:username>"
        :name "user"
        ;; Example of using a function for retrieving
        ;; route title dynamically at runtime:
        :title #'get-user-name)
    (format nil "User profile: ~A" username)))
```
And now you will get a real user's name as the last breadcrumb title:

```lisp

TEST-ROUTES> (with-url (*app-routes* "/admin/users/john")
               (let ((crumbs (40ants-routes/breadcrumbs:get-breadcrumbs)))
                 (values
                  (mapcar #'40ants-routes/breadcrumbs:breadcrumb-path crumbs)
                  (mapcar #'40ants-routes/breadcrumbs:breadcrumb-title crumbs))))
("/" "/admin/" "/admin/users/" "/admin/users/john")
("Home" "Admin" "Users" "John Smith")
```
This makes it easy to create meaningful breadcrumb navigation that adapts to the content being displayed.

<a id="x-2840ANTS-ROUTES-DOCS-2FINDEX-3A-3A-40API-2040ANTS-DOC-2FLOCATIVES-3ASECTION-29"></a>

## API Reference

<a id="x-2840ANTS-ROUTES-DOCS-2FINDEX-3A-3A-4040ANTS-ROUTES-2FBREADCRUMBS-3FPACKAGE-2040ANTS-DOC-2FLOCATIVES-3ASECTION-29"></a>

### 40ANTS-ROUTES/BREADCRUMBS

<a id="x-28-23A-28-2825-29-20BASE-CHAR-20-2E-20-2240ANTS-ROUTES-2FBREADCRUMBS-22-29-20PACKAGE-29"></a>

#### [package](475a) `40ants-routes/breadcrumbs`

<a id="x-2840ANTS-ROUTES-DOCS-2FINDEX-3A-3A-7C-4040ANTS-ROUTES-2FBREADCRUMBS-3FClasses-SECTION-7C-2040ANTS-DOC-2FLOCATIVES-3ASECTION-29"></a>

#### Classes

<a id="x-2840ANTS-ROUTES-DOCS-2FINDEX-3A-3A-4040ANTS-ROUTES-2FBREADCRUMBS-24BREADCRUMB-3FCLASS-2040ANTS-DOC-2FLOCATIVES-3ASECTION-29"></a>

##### BREADCRUMB

<a id="x-2840ANTS-ROUTES-2FBREADCRUMBS-3ABREADCRUMB-20CLASS-29"></a>

###### [class](9002) `40ants-routes/breadcrumbs:breadcrumb` ()

**Readers**

<a id="x-2840ANTS-ROUTES-2FBREADCRUMBS-3ABREADCRUMB-PATH-20-2840ANTS-DOC-2FLOCATIVES-3AREADER-2040ANTS-ROUTES-2FBREADCRUMBS-3ABREADCRUMB-29-29"></a>

###### [reader](824f) `40ants-routes/breadcrumbs:breadcrumb-path` (breadcrumb) (:path)

<a id="x-2840ANTS-ROUTES-2FBREADCRUMBS-3ABREADCRUMB-ROUTE-20-2840ANTS-DOC-2FLOCATIVES-3AREADER-2040ANTS-ROUTES-2FBREADCRUMBS-3ABREADCRUMB-29-29"></a>

###### [reader](1a3f) `40ants-routes/breadcrumbs:breadcrumb-route` (breadcrumb) (:route)

<a id="x-2840ANTS-ROUTES-2FBREADCRUMBS-3ABREADCRUMB-TITLE-20-2840ANTS-DOC-2FLOCATIVES-3AREADER-2040ANTS-ROUTES-2FBREADCRUMBS-3ABREADCRUMB-29-29"></a>

###### [reader](272a) `40ants-routes/breadcrumbs:breadcrumb-title` (breadcrumb) (:title)

<a id="x-2840ANTS-ROUTES-DOCS-2FINDEX-3A-3A-7C-4040ANTS-ROUTES-2FBREADCRUMBS-3FFunctions-SECTION-7C-2040ANTS-DOC-2FLOCATIVES-3ASECTION-29"></a>

#### Functions

<a id="x-2840ANTS-ROUTES-2FBREADCRUMBS-3AGET-BREADCRUMBS-20FUNCTION-29"></a>

##### [function](ffcf) `40ants-routes/breadcrumbs:get-breadcrumbs`

Generate breadcrumbs list for the current `URL` set by [`40ants-routes/with-url:with-url`][1c5e] macro.

<a id="x-2840ANTS-ROUTES-2FBREADCRUMBS-3AMAKE-BREADCRUMB-20FUNCTION-29"></a>

##### [function](e66c) `40ants-routes/breadcrumbs:make-breadcrumb` title

Creates a breadcrumb item.

<a id="x-2840ANTS-ROUTES-DOCS-2FINDEX-3A-3A-4040ANTS-ROUTES-2FDEFROUTES-3FPACKAGE-2040ANTS-DOC-2FLOCATIVES-3ASECTION-29"></a>

### 40ANTS-ROUTES/DEFROUTES

<a id="x-28-23A-28-2823-29-20BASE-CHAR-20-2E-20-2240ANTS-ROUTES-2FDEFROUTES-22-29-20PACKAGE-29"></a>

#### [package](c8d7) `40ants-routes/defroutes`

<a id="x-2840ANTS-ROUTES-DOCS-2FINDEX-3A-3A-7C-4040ANTS-ROUTES-2FDEFROUTES-3FFunctions-SECTION-7C-2040ANTS-DOC-2FLOCATIVES-3ASECTION-29"></a>

#### Functions

<a id="x-2840ANTS-ROUTES-2FDEFROUTES-3AINCLUDE-20FUNCTION-29"></a>

##### [function](ddcf) `40ants-routes/defroutes:include` routes &key (path "/")

<a id="x-2840ANTS-ROUTES-DOCS-2FINDEX-3A-3A-7C-4040ANTS-ROUTES-2FDEFROUTES-3FMacros-SECTION-7C-2040ANTS-DOC-2FLOCATIVES-3ASECTION-29"></a>

#### Macros

<a id="x-2840ANTS-ROUTES-2FDEFROUTES-3ADEFROUTES-20-2840ANTS-DOC-2FLOCATIVES-3AMACRO-29-29"></a>

##### [macro](84c5) `40ants-routes/defroutes:defroutes` (var-name &key namespace (routes-class 'routes)) &body route-definitions

Define a variable holding collection of routes and binds it to a variable `VAR-NAME`.

This macro acts like a `DEFVAR` - if there is already an `40ants-routes/routes:routes` ([`1`][77f9] [`2`][cce3])
object bound to the variable, then it is not replaced, but updated inplace.
This allows to change routes on the fly even if they were included into some routes
hierarchy.

You can use `ROUTES-CLASS` argument to supply you own class, inherited from `routes` ([`1`][77f9] [`2`][cce3]).
This way it might be possible to special processing for these routes, for example,
inject some special code for representing this routes in the "breadcrumbs".

Use [`get`][f902], [`post`][a861], [`put`][c587], `DELETE` macros in `ROUTE-DEFINITIONS` forms.

See more examples how to define routes in the
[`Defining Routes`][d39a] section.

<a id="x-2840ANTS-ROUTES-2FDEFROUTES-3AGET-20-2840ANTS-DOC-2FLOCATIVES-3AMACRO-29-29"></a>

##### [macro](fbf9) `40ants-routes/defroutes:get` (path &key name title (route-class 'route)) &body handler-body

<a id="x-2840ANTS-ROUTES-2FDEFROUTES-3APOST-20-2840ANTS-DOC-2FLOCATIVES-3AMACRO-29-29"></a>

##### [macro](de3a) `40ants-routes/defroutes:post` (path &key name title (route-class 'route)) &body handler-body

<a id="x-2840ANTS-ROUTES-2FDEFROUTES-3APUT-20-2840ANTS-DOC-2FLOCATIVES-3AMACRO-29-29"></a>

##### [macro](25b8) `40ants-routes/defroutes:put` (path &key name title (route-class 'route)) &body handler-body

<a id="x-2840ANTS-ROUTES-DOCS-2FINDEX-3A-3A-4040ANTS-ROUTES-2FERRORS-3FPACKAGE-2040ANTS-DOC-2FLOCATIVES-3ASECTION-29"></a>

### 40ANTS-ROUTES/ERRORS

<a id="x-28-23A-28-2820-29-20BASE-CHAR-20-2E-20-2240ANTS-ROUTES-2FERRORS-22-29-20PACKAGE-29"></a>

#### [package](5ad2) `40ants-routes/errors`

<a id="x-2840ANTS-ROUTES-DOCS-2FINDEX-3A-3A-7C-4040ANTS-ROUTES-2FERRORS-3FClasses-SECTION-7C-2040ANTS-DOC-2FLOCATIVES-3ASECTION-29"></a>

#### Classes

<a id="x-2840ANTS-ROUTES-DOCS-2FINDEX-3A-3A-4040ANTS-ROUTES-2FERRORS-24ARGUMENT-MISSING-ERROR-3FCLASS-2040ANTS-DOC-2FLOCATIVES-3ASECTION-29"></a>

##### ARGUMENT-MISSING-ERROR

<a id="x-2840ANTS-ROUTES-2FERRORS-3AARGUMENT-MISSING-ERROR-20CONDITION-29"></a>

###### [condition](222f) `40ants-routes/errors:argument-missing-error` (error)

**Readers**

<a id="x-2840ANTS-ROUTES-2FERRORS-3AARGUMENT-MISSING-ERROR-PARAMETER-20-2840ANTS-DOC-2FLOCATIVES-3AREADER-2040ANTS-ROUTES-2FERRORS-3AARGUMENT-MISSING-ERROR-29-29"></a>

###### [reader](222f) `40ants-routes/errors:argument-missing-error-parameter` (argument-missing-error) (:missing-parameter)

<a id="x-2840ANTS-ROUTES-2FERRORS-3AARGUMENT-MISSING-ERROR-ROUTE-NAME-20-2840ANTS-DOC-2FLOCATIVES-3AREADER-2040ANTS-ROUTES-2FERRORS-3AARGUMENT-MISSING-ERROR-29-29"></a>

###### [reader](222f) `40ants-routes/errors:argument-missing-error-route-name` (argument-missing-error) (:route-name)

<a id="x-2840ANTS-ROUTES-DOCS-2FINDEX-3A-3A-4040ANTS-ROUTES-2FERRORS-24NAMESPACE-DUPLICATION-ERROR-3FCLASS-2040ANTS-DOC-2FLOCATIVES-3ASECTION-29"></a>

##### NAMESPACE-DUPLICATION-ERROR

<a id="x-2840ANTS-ROUTES-2FERRORS-3ANAMESPACE-DUPLICATION-ERROR-20CONDITION-29"></a>

###### [condition](ff98) `40ants-routes/errors:namespace-duplication-error` (error)

**Readers**

<a id="x-2840ANTS-ROUTES-2FERRORS-3AEXISTING-NAMESPACE-20-2840ANTS-DOC-2FLOCATIVES-3AREADER-2040ANTS-ROUTES-2FERRORS-3ANAMESPACE-DUPLICATION-ERROR-29-29"></a>

###### [reader](ff98) `40ants-routes/errors:existing-namespace` (namespace-duplication-error) (:namespace)

<a id="x-2840ANTS-ROUTES-2FERRORS-3AEXISTING-ROUTE-20-2840ANTS-DOC-2FLOCATIVES-3AREADER-2040ANTS-ROUTES-2FERRORS-3ANAMESPACE-DUPLICATION-ERROR-29-29"></a>

###### [reader](ff98) `40ants-routes/errors:existing-route` (namespace-duplication-error) (:existing-route)

<a id="x-2840ANTS-ROUTES-2FERRORS-3ANEW-ROUTE-20-2840ANTS-DOC-2FLOCATIVES-3AREADER-2040ANTS-ROUTES-2FERRORS-3ANAMESPACE-DUPLICATION-ERROR-29-29"></a>

###### [reader](ff98) `40ants-routes/errors:new-route` (namespace-duplication-error) (:new-route)

<a id="x-2840ANTS-ROUTES-DOCS-2FINDEX-3A-3A-4040ANTS-ROUTES-2FERRORS-24NO-COMMON-ELEMENTS-ERROR-3FCLASS-2040ANTS-DOC-2FLOCATIVES-3ASECTION-29"></a>

##### NO-COMMON-ELEMENTS-ERROR

<a id="x-2840ANTS-ROUTES-2FERRORS-3ANO-COMMON-ELEMENTS-ERROR-20CONDITION-29"></a>

###### [condition](d36b) `40ants-routes/errors:no-common-elements-error` (error)

**Readers**

<a id="x-2840ANTS-ROUTES-2FERRORS-3AFULL-NAMESPACE-20-2840ANTS-DOC-2FLOCATIVES-3AREADER-2040ANTS-ROUTES-2FERRORS-3ANO-COMMON-ELEMENTS-ERROR-29-29"></a>

###### [reader](d36b) `40ants-routes/errors:full-namespace` (no-common-elements-error) (:full-namespace)

<a id="x-2840ANTS-ROUTES-2FERRORS-3ARELATIVE-NAMESPACE-20-2840ANTS-DOC-2FLOCATIVES-3AREADER-2040ANTS-ROUTES-2FERRORS-3ANO-COMMON-ELEMENTS-ERROR-29-29"></a>

###### [reader](d36b) `40ants-routes/errors:relative-namespace` (no-common-elements-error) (:relative-namespace)

<a id="x-2840ANTS-ROUTES-DOCS-2FINDEX-3A-3A-4040ANTS-ROUTES-2FERRORS-24NO-ROUTE-FOR-URL-ERROR-3FCLASS-2040ANTS-DOC-2FLOCATIVES-3ASECTION-29"></a>

##### NO-ROUTE-FOR-URL-ERROR

<a id="x-2840ANTS-ROUTES-2FERRORS-3ANO-ROUTE-FOR-URL-ERROR-20CONDITION-29"></a>

###### [condition](e606) `40ants-routes/errors:no-route-for-url-error` (error)

**Readers**

<a id="x-2840ANTS-ROUTES-2FERRORS-3AERROR-ROUTES-PATH-20-2840ANTS-DOC-2FLOCATIVES-3AREADER-2040ANTS-ROUTES-2FERRORS-3ANO-ROUTE-FOR-URL-ERROR-29-29"></a>

###### [reader](e606) `40ants-routes/errors:error-routes-path` (no-route-for-url-error) (:routes-path)

<a id="x-2840ANTS-ROUTES-2FERRORS-3AERROR-URL-20-2840ANTS-DOC-2FLOCATIVES-3AREADER-2040ANTS-ROUTES-2FERRORS-3ANO-ROUTE-FOR-URL-ERROR-29-29"></a>

###### [reader](e606) `40ants-routes/errors:error-url` (no-route-for-url-error) (:url)

<a id="x-2840ANTS-ROUTES-DOCS-2FINDEX-3A-3A-4040ANTS-ROUTES-2FERRORS-24PATH-DUPLICATION-ERROR-3FCLASS-2040ANTS-DOC-2FLOCATIVES-3ASECTION-29"></a>

##### PATH-DUPLICATION-ERROR

<a id="x-2840ANTS-ROUTES-2FERRORS-3APATH-DUPLICATION-ERROR-20CONDITION-29"></a>

###### [condition](ff8f) `40ants-routes/errors:path-duplication-error` (error)

**Readers**

<a id="x-2840ANTS-ROUTES-2FERRORS-3AEXISTING-PATH-20-2840ANTS-DOC-2FLOCATIVES-3AREADER-2040ANTS-ROUTES-2FERRORS-3APATH-DUPLICATION-ERROR-29-29"></a>

###### [reader](ff8f) `40ants-routes/errors:existing-path` (path-duplication-error) (:path)

<a id="x-2840ANTS-ROUTES-2FERRORS-3AEXISTING-ROUTE-20-2840ANTS-DOC-2FLOCATIVES-3AREADER-2040ANTS-ROUTES-2FERRORS-3APATH-DUPLICATION-ERROR-29-29"></a>

###### [reader](ff8f) `40ants-routes/errors:existing-route` (path-duplication-error) (:existing-route)

<a id="x-2840ANTS-ROUTES-2FERRORS-3ANEW-ROUTE-20-2840ANTS-DOC-2FLOCATIVES-3AREADER-2040ANTS-ROUTES-2FERRORS-3APATH-DUPLICATION-ERROR-29-29"></a>

###### [reader](ff8f) `40ants-routes/errors:new-route` (path-duplication-error) (:new-route)

<a id="x-2840ANTS-ROUTES-DOCS-2FINDEX-3A-3A-4040ANTS-ROUTES-2FERRORS-24URL-RESOLUTION-ERROR-3FCLASS-2040ANTS-DOC-2FLOCATIVES-3ASECTION-29"></a>

##### URL-RESOLUTION-ERROR

<a id="x-2840ANTS-ROUTES-2FERRORS-3AURL-RESOLUTION-ERROR-20CONDITION-29"></a>

###### [condition](e635) `40ants-routes/errors:url-resolution-error` (error)

**Readers**

<a id="x-2840ANTS-ROUTES-2FERRORS-3ANAMESPACE-20-2840ANTS-DOC-2FLOCATIVES-3AREADER-2040ANTS-ROUTES-2FERRORS-3AURL-RESOLUTION-ERROR-29-29"></a>

###### [reader](e635) `40ants-routes/errors:namespace` (url-resolution-error) (:namespace)

<a id="x-2840ANTS-ROUTES-2FERRORS-3AROUTE-NAME-20-2840ANTS-DOC-2FLOCATIVES-3AREADER-2040ANTS-ROUTES-2FERRORS-3AURL-RESOLUTION-ERROR-29-29"></a>

###### [reader](e635) `40ants-routes/errors:route-name` (url-resolution-error) (:route-name)

<a id="x-2840ANTS-ROUTES-DOCS-2FINDEX-3A-3A-4040ANTS-ROUTES-2FFIND-ROUTE-3FPACKAGE-2040ANTS-DOC-2FLOCATIVES-3ASECTION-29"></a>

### 40ANTS-ROUTES/FIND-ROUTE

<a id="x-28-23A-28-2824-29-20BASE-CHAR-20-2E-20-2240ANTS-ROUTES-2FFIND-ROUTE-22-29-20PACKAGE-29"></a>

#### [package](7c07) `40ants-routes/find-route`

<a id="x-2840ANTS-ROUTES-DOCS-2FINDEX-3A-3A-7C-4040ANTS-ROUTES-2FFIND-ROUTE-3FFunctions-SECTION-7C-2040ANTS-DOC-2FLOCATIVES-3ASECTION-29"></a>

#### Functions

<a id="x-2840ANTS-ROUTES-2FFIND-ROUTE-3AFIND-ROUTE-20FUNCTION-29"></a>

##### [function](312f) `40ants-routes/find-route:find-route` name &key namespace on-match

Find a route by name in the given namespace hierarchy.

If route was found, then returns it.

Additionally, it will call `ON-MATCH` callable argument
with each route node along path to the leaf route.

<a id="x-2840ANTS-ROUTES-DOCS-2FINDEX-3A-3A-4040ANTS-ROUTES-2FGENERICS-3FPACKAGE-2040ANTS-DOC-2FLOCATIVES-3ASECTION-29"></a>

### 40ANTS-ROUTES/GENERICS

<a id="x-28-23A-28-2822-29-20BASE-CHAR-20-2E-20-2240ANTS-ROUTES-2FGENERICS-22-29-20PACKAGE-29"></a>

#### [package](db29) `40ants-routes/generics`

<a id="x-2840ANTS-ROUTES-DOCS-2FINDEX-3A-3A-7C-4040ANTS-ROUTES-2FGENERICS-3FGenerics-SECTION-7C-2040ANTS-DOC-2FLOCATIVES-3ASECTION-29"></a>

#### Generics

<a id="x-2840ANTS-ROUTES-2FGENERICS-3AADD-ROUTE-20GENERIC-FUNCTION-29"></a>

##### [generic-function](c31e) `40ants-routes/generics:add-route` routes route-or-routes-to-add &key override

Add a route or included-routes object to the routes collection at runtime.
If a route with the same path or namespace already exists, an error will be signaled
unless override is set to true.

<a id="x-2840ANTS-ROUTES-2FGENERICS-3AFORMAT-URL-20GENERIC-FUNCTION-29"></a>

##### [generic-function](538e) `40ants-routes/generics:format-url` obj stream args

Should write a piece of `URL` to the `STREAM` substituting arguments from plist `ARGS`.

When called, it should write a piece of `URL` without starting backslash.

<a id="x-2840ANTS-ROUTES-2FGENERICS-3AGET-ROUTE-BREADCRUMBS-20GENERIC-FUNCTION-29"></a>

##### [generic-function](a778) `40ants-routes/generics:get-route-breadcrumbs` node

Returns a list of breadcrumbs associated with given routes node.

`NODE` argument could have [`40ants-routes/route:route`][377c] class, [`40ants-routes/routes:routes`][cce3] class or an object of other
class bound to some object of [`40ants-routes/route:route`][377c] class.

For objects of class [`40ants-routes/routes:routes`][cce3] usually the method return breadcrumbs of the
route having the `/` path.

Method can return from zero to N objects of [`40ants-routes/breadcrumbs:breadcrumb`][e419] class.
A returning of multiple breadcrumbs can be useful if route matches to some filename in a nested directory
and you want to give an ability to navigate into intermediate directories.

<a id="x-2840ANTS-ROUTES-2FGENERICS-3AHAS-NAMESPACE-P-20GENERIC-FUNCTION-29"></a>

##### [generic-function](5770) `40ants-routes/generics:has-namespace-p` routes

Returns T of node can respond to [`node-namespace`][db92] generic-function call.

<a id="x-2840ANTS-ROUTES-2FGENERICS-3AMATCH-URL-20GENERIC-FUNCTION-29"></a>

##### [generic-function](0da6) `40ants-routes/generics:match-url` obj url &key on-match

Checks for complete match of the object to `URL`.

Should return an `OBJ` if it fully matches to a given url.
May return a sub-object if `OBJ` matches to a prefix
and sub-object matches the rest of `URL`.

If match was found, the second returned value
should be a alist with matched parameters.

If `ON-MATCH` argument is given, then in any case
of match, full or prefix, calls `ON-MATCH`
function with `OBJ` as a single argument.

<a id="x-2840ANTS-ROUTES-2FGENERICS-3ANODE-NAMESPACE-20GENERIC-FUNCTION-29"></a>

##### [generic-function](a0cf) `40ants-routes/generics:node-namespace` routes

Returns a string name of node's namepace. Works only for objects for which [`has-namespace-p`][3eec] returns true.

<a id="x-2840ANTS-ROUTES-2FGENERICS-3APARTIAL-MATCH-URL-20GENERIC-FUNCTION-29"></a>

##### [generic-function](1080) `40ants-routes/generics:partial-match-url` obj url

Tests of obj matches to the a prefix of `URL`.

If match was found, should return two
values: the object which matches and position of
the character after the matched prefix.

If `OBJ` is a compound element, then
a sub-element can be returned in case of match.

<a id="x-2840ANTS-ROUTES-2FGENERICS-3AURL-PATH-20GENERIC-FUNCTION-29"></a>

##### [generic-function](343a) `40ants-routes/generics:url-path` obj

Returns the [`40ants-routes/url-pattern:url-pattern`][a13f] associated with the object.

<a id="x-2840ANTS-ROUTES-DOCS-2FINDEX-3A-3A-4040ANTS-ROUTES-2FHANDLER-3FPACKAGE-2040ANTS-DOC-2FLOCATIVES-3ASECTION-29"></a>

### 40ANTS-ROUTES/HANDLER

<a id="x-28-23A-28-2821-29-20BASE-CHAR-20-2E-20-2240ANTS-ROUTES-2FHANDLER-22-29-20PACKAGE-29"></a>

#### [package](0311) `40ants-routes/handler`

<a id="x-2840ANTS-ROUTES-DOCS-2FINDEX-3A-3A-7C-4040ANTS-ROUTES-2FHANDLER-3FFunctions-SECTION-7C-2040ANTS-DOC-2FLOCATIVES-3ASECTION-29"></a>

#### Functions

<a id="x-2840ANTS-ROUTES-2FHANDLER-3ACALL-HANDLER-20FUNCTION-29"></a>

##### [function](8de2) `40ants-routes/handler:call-handler`

Calls a handler of current route.

Should be called only during [`40ants-routes/with-url:with-url`][1c5e] macro body execution.

<a id="x-2840ANTS-ROUTES-DOCS-2FINDEX-3A-3A-4040ANTS-ROUTES-2FINCLUDED-ROUTES-3FPACKAGE-2040ANTS-DOC-2FLOCATIVES-3ASECTION-29"></a>

### 40ANTS-ROUTES/INCLUDED-ROUTES

<a id="x-28-23A-28-2829-29-20BASE-CHAR-20-2E-20-2240ANTS-ROUTES-2FINCLUDED-ROUTES-22-29-20PACKAGE-29"></a>

#### [package](2b55) `40ants-routes/included-routes`

<a id="x-2840ANTS-ROUTES-DOCS-2FINDEX-3A-3A-7C-4040ANTS-ROUTES-2FINCLUDED-ROUTES-3FClasses-SECTION-7C-2040ANTS-DOC-2FLOCATIVES-3ASECTION-29"></a>

#### Classes

<a id="x-2840ANTS-ROUTES-DOCS-2FINDEX-3A-3A-4040ANTS-ROUTES-2FINCLUDED-ROUTES-24INCLUDED-ROUTES-3FCLASS-2040ANTS-DOC-2FLOCATIVES-3ASECTION-29"></a>

##### INCLUDED-ROUTES

<a id="x-2840ANTS-ROUTES-2FINCLUDED-ROUTES-3AINCLUDED-ROUTES-20CLASS-29"></a>

###### [class](da55) `40ants-routes/included-routes:included-routes` ()

**Readers**

<a id="x-2840ANTS-ROUTES-2FINCLUDED-ROUTES-3AORIGINAL-ROUTES-20-2840ANTS-DOC-2FLOCATIVES-3AREADER-2040ANTS-ROUTES-2FINCLUDED-ROUTES-3AINCLUDED-ROUTES-29-29"></a>

###### [reader](b602) `40ants-routes/included-routes:original-routes` (included-routes) (:original-collection)

The original collection that was included

<a id="x-2840ANTS-ROUTES-2FGENERICS-3AURL-PATH-20-2840ANTS-DOC-2FLOCATIVES-3AREADER-2040ANTS-ROUTES-2FINCLUDED-ROUTES-3AINCLUDED-ROUTES-29-29"></a>

###### [reader](8ec7) `40ants-routes/generics:url-path` (included-routes) (:path)

Path to add to all routes in the collection

<a id="x-2840ANTS-ROUTES-DOCS-2FINDEX-3A-3A-7C-4040ANTS-ROUTES-2FINCLUDED-ROUTES-3FFunctions-SECTION-7C-2040ANTS-DOC-2FLOCATIVES-3ASECTION-29"></a>

#### Functions

<a id="x-2840ANTS-ROUTES-2FINCLUDED-ROUTES-3AINCLUDED-ROUTES-P-20FUNCTION-29"></a>

##### [function](cba3) `40ants-routes/included-routes:included-routes-p` obj

<a id="x-2840ANTS-ROUTES-DOCS-2FINDEX-3A-3A-4040ANTS-ROUTES-2FMATCHED-ROUTE-3FPACKAGE-2040ANTS-DOC-2FLOCATIVES-3ASECTION-29"></a>

### 40ANTS-ROUTES/MATCHED-ROUTE

<a id="x-28-23A-28-2827-29-20BASE-CHAR-20-2E-20-2240ANTS-ROUTES-2FMATCHED-ROUTE-22-29-20PACKAGE-29"></a>

#### [package](382c) `40ants-routes/matched-route`

<a id="x-2840ANTS-ROUTES-DOCS-2FINDEX-3A-3A-7C-4040ANTS-ROUTES-2FMATCHED-ROUTE-3FClasses-SECTION-7C-2040ANTS-DOC-2FLOCATIVES-3ASECTION-29"></a>

#### Classes

<a id="x-2840ANTS-ROUTES-DOCS-2FINDEX-3A-3A-4040ANTS-ROUTES-2FMATCHED-ROUTE-24MATCHED-ROUTE-3FCLASS-2040ANTS-DOC-2FLOCATIVES-3ASECTION-29"></a>

##### MATCHED-ROUTE

<a id="x-2840ANTS-ROUTES-2FMATCHED-ROUTE-3AMATCHED-ROUTE-20CLASS-29"></a>

###### [class](1172) `40ants-routes/matched-route:matched-route` ()

**Readers**

<a id="x-2840ANTS-ROUTES-2FMATCHED-ROUTE-3AMATCHED-ROUTE-PARAMETERS-20-2840ANTS-DOC-2FLOCATIVES-3AREADER-2040ANTS-ROUTES-2FMATCHED-ROUTE-3AMATCHED-ROUTE-29-29"></a>

###### [reader](e57f) `40ants-routes/matched-route:matched-route-parameters` (matched-route) (:parameters = nil)

Parameters extracted from the `URL` pattern as alist where keys are parameter names and values - parameter types.

<a id="x-2840ANTS-ROUTES-2FMATCHED-ROUTE-3AORIGINAL-ROUTE-20-2840ANTS-DOC-2FLOCATIVES-3AREADER-2040ANTS-ROUTES-2FMATCHED-ROUTE-3AMATCHED-ROUTE-29-29"></a>

###### [reader](d0e1) `40ants-routes/matched-route:original-route` (matched-route) (:original-route)

The original [`route`][377c] object which has been matched.

<a id="x-2840ANTS-ROUTES-DOCS-2FINDEX-3A-3A-7C-4040ANTS-ROUTES-2FMATCHED-ROUTE-3FFunctions-SECTION-7C-2040ANTS-DOC-2FLOCATIVES-3ASECTION-29"></a>

#### Functions

<a id="x-2840ANTS-ROUTES-2FMATCHED-ROUTE-3AMATCHED-ROUTE-P-20FUNCTION-29"></a>

##### [function](1c69) `40ants-routes/matched-route:matched-route-p` obj

<a id="x-2840ANTS-ROUTES-DOCS-2FINDEX-3A-3A-4040ANTS-ROUTES-2FROUTE-3FPACKAGE-2040ANTS-DOC-2FLOCATIVES-3ASECTION-29"></a>

### 40ANTS-ROUTES/ROUTE

<a id="x-28-23A-28-2819-29-20BASE-CHAR-20-2E-20-2240ANTS-ROUTES-2FROUTE-22-29-20PACKAGE-29"></a>

#### [package](ccaf) `40ants-routes/route`

<a id="x-2840ANTS-ROUTES-DOCS-2FINDEX-3A-3A-7C-4040ANTS-ROUTES-2FROUTE-3FClasses-SECTION-7C-2040ANTS-DOC-2FLOCATIVES-3ASECTION-29"></a>

#### Classes

<a id="x-2840ANTS-ROUTES-DOCS-2FINDEX-3A-3A-4040ANTS-ROUTES-2FROUTE-24ROUTE-3FCLASS-2040ANTS-DOC-2FLOCATIVES-3ASECTION-29"></a>

##### ROUTE

<a id="x-2840ANTS-ROUTES-2FROUTE-3AROUTE-20CLASS-29"></a>

###### [class](a90d) `40ants-routes/route:route` ()

**Readers**

<a id="x-2840ANTS-ROUTES-2FROUTE-3AROUTE-HANDLER-20-2840ANTS-DOC-2FLOCATIVES-3AREADER-2040ANTS-ROUTES-2FROUTE-3AROUTE-29-29"></a>

###### [reader](248f) `40ants-routes/route:route-handler` (route) (:handler)

Function to handle the route

<a id="x-2840ANTS-ROUTES-2FROUTE-3AROUTE-METHOD-20-2840ANTS-DOC-2FLOCATIVES-3AREADER-2040ANTS-ROUTES-2FROUTE-3AROUTE-29-29"></a>

###### [reader](06c0) `40ants-routes/route:route-method` (route) (:method = :get)

`HTTP` method (`GET`, `POST`, `PUT`, etc.)

<a id="x-2840ANTS-ROUTES-2FROUTE-3AROUTE-NAME-20-2840ANTS-DOC-2FLOCATIVES-3AREADER-2040ANTS-ROUTES-2FROUTE-3AROUTE-29-29"></a>

###### [reader](e305) `40ants-routes/route:route-name` (route) (:name)

Name of the route

<a id="x-2840ANTS-ROUTES-2FROUTE-3AROUTE-TITLE-20-2840ANTS-DOC-2FLOCATIVES-3AREADER-2040ANTS-ROUTES-2FROUTE-3AROUTE-29-29"></a>

###### [reader](b349) `40ants-routes/route:route-title` (route) (:title = nil)

Title for breadcrumbs

<a id="x-2840ANTS-ROUTES-2FGENERICS-3AURL-PATH-20-2840ANTS-DOC-2FLOCATIVES-3AREADER-2040ANTS-ROUTES-2FROUTE-3AROUTE-29-29"></a>

###### [reader](6b1c) `40ants-routes/generics:url-path` (route) (:pattern)

`URL` pattern

<a id="x-2840ANTS-ROUTES-DOCS-2FINDEX-3A-3A-7C-4040ANTS-ROUTES-2FROUTE-3FFunctions-SECTION-7C-2040ANTS-DOC-2FLOCATIVES-3ASECTION-29"></a>

#### Functions

<a id="x-2840ANTS-ROUTES-2FROUTE-3ACURRENT-ROUTE-20FUNCTION-29"></a>

##### [function](a15e) `40ants-routes/route:current-route`

Returns the current route.

Should be called only during [`40ants-routes/with-url:with-url`][1c5e] macro body execution.

<a id="x-2840ANTS-ROUTES-2FROUTE-3ACURRENT-ROUTE-P-20FUNCTION-29"></a>

##### [function](a31f) `40ants-routes/route:current-route-p`

Returns T if there current route matching the `URL` was found..

Should be called only during [`40ants-routes/with-url:with-url`][1c5e]
or [`40ants-routes/with-url:with-partially-matched-url`][1a23] macro body execution.

<a id="x-2840ANTS-ROUTES-2FROUTE-3AROUTEP-20FUNCTION-29"></a>

##### [function](a269) `40ants-routes/route:routep` obj

Checks if `OBJ` is of [`route`][377c] class.

<a id="x-2840ANTS-ROUTES-DOCS-2FINDEX-3A-3A-4040ANTS-ROUTES-2FROUTE-URL-3FPACKAGE-2040ANTS-DOC-2FLOCATIVES-3ASECTION-29"></a>

### 40ANTS-ROUTES/ROUTE-URL

<a id="x-28-23A-28-2823-29-20BASE-CHAR-20-2E-20-2240ANTS-ROUTES-2FROUTE-URL-22-29-20PACKAGE-29"></a>

#### [package](f689) `40ants-routes/route-url`

<a id="x-2840ANTS-ROUTES-DOCS-2FINDEX-3A-3A-7C-4040ANTS-ROUTES-2FROUTE-URL-3FFunctions-SECTION-7C-2040ANTS-DOC-2FLOCATIVES-3ASECTION-29"></a>

#### Functions

<a id="x-2840ANTS-ROUTES-2FROUTE-URL-3AROUTE-URL-20FUNCTION-29"></a>

##### [function](c11c) `40ants-routes/route-url:route-url` name &rest args &key namespace &allow-other-keys

Generate a `URL` for a named route with the given parameters.

<a id="x-2840ANTS-ROUTES-DOCS-2FINDEX-3A-3A-4040ANTS-ROUTES-2FROUTES-3FPACKAGE-2040ANTS-DOC-2FLOCATIVES-3ASECTION-29"></a>

### 40ANTS-ROUTES/ROUTES

<a id="x-28-23A-28-2820-29-20BASE-CHAR-20-2E-20-2240ANTS-ROUTES-2FROUTES-22-29-20PACKAGE-29"></a>

#### [package](db9b) `40ants-routes/routes`

<a id="x-2840ANTS-ROUTES-DOCS-2FINDEX-3A-3A-7C-4040ANTS-ROUTES-2FROUTES-3FClasses-SECTION-7C-2040ANTS-DOC-2FLOCATIVES-3ASECTION-29"></a>

#### Classes

<a id="x-2840ANTS-ROUTES-DOCS-2FINDEX-3A-3A-4040ANTS-ROUTES-2FROUTES-24ROUTES-3FCLASS-2040ANTS-DOC-2FLOCATIVES-3ASECTION-29"></a>

##### ROUTES

<a id="x-2840ANTS-ROUTES-2FROUTES-3AROUTES-20CLASS-29"></a>

###### [class](5adc) `40ants-routes/routes:routes` ()

**Readers**

<a id="x-2840ANTS-ROUTES-2FROUTES-3ACHILDREN-ROUTES-20-2840ANTS-DOC-2FLOCATIVES-3AREADER-2040ANTS-ROUTES-2FROUTES-3AROUTES-29-29"></a>

###### [reader](dd63) `40ants-routes/routes:children-routes` (routes) (:children = nil)

List of children in this collection.

<a id="x-2840ANTS-ROUTES-2FGENERICS-3ANODE-NAMESPACE-20-2840ANTS-DOC-2FLOCATIVES-3AREADER-2040ANTS-ROUTES-2FROUTES-3AROUTES-29-29"></a>

###### [reader](40d6) `40ants-routes/generics:node-namespace` (routes) (:namespace)

Namespace of this routes collection.

**Accessors**

<a id="x-2840ANTS-ROUTES-2FROUTES-3ACHILDREN-ROUTES-20-2840ANTS-DOC-2FLOCATIVES-3AACCESSOR-2040ANTS-ROUTES-2FROUTES-3AROUTES-29-29"></a>

###### [accessor](dd63) `40ants-routes/routes:children-routes` (routes) (:children = nil)

List of children in this collection.

<a id="x-2840ANTS-ROUTES-2FGENERICS-3ANODE-NAMESPACE-20-2840ANTS-DOC-2FLOCATIVES-3AACCESSOR-2040ANTS-ROUTES-2FROUTES-3AROUTES-29-29"></a>

###### [accessor](40d6) `40ants-routes/generics:node-namespace` (routes) (:namespace)

Namespace of this routes collection.

<a id="x-2840ANTS-ROUTES-DOCS-2FINDEX-3A-3A-7C-4040ANTS-ROUTES-2FROUTES-3FFunctions-SECTION-7C-2040ANTS-DOC-2FLOCATIVES-3ASECTION-29"></a>

#### Functions

<a id="x-2840ANTS-ROUTES-2FROUTES-3AROUTESP-20FUNCTION-29"></a>

##### [function](e2ff) `40ants-routes/routes:routesp` obj

Checks if object is of class [`routes`][cce3].

<a id="x-2840ANTS-ROUTES-DOCS-2FINDEX-3A-3A-7C-4040ANTS-ROUTES-2FROUTES-3FMacros-SECTION-7C-2040ANTS-DOC-2FLOCATIVES-3ASECTION-29"></a>

#### Macros

<a id="x-2840ANTS-ROUTES-2FROUTES-3AROUTES-20-2840ANTS-DOC-2FLOCATIVES-3AMACRO-29-29"></a>

##### [macro](9461) `40ants-routes/routes:routes` (namespace &key (routes-class 'routes)) &body route-definitions

Define a variable holding collection of routes the same way
as [`40ants-routes/defroutes:defroutes`][3455] does, but do not bind these routes to the variable.

<a id="x-2840ANTS-ROUTES-DOCS-2FINDEX-3A-3A-4040ANTS-ROUTES-2FURL-PATTERN-3FPACKAGE-2040ANTS-DOC-2FLOCATIVES-3ASECTION-29"></a>

### 40ANTS-ROUTES/URL-PATTERN

<a id="x-28-23A-28-2825-29-20BASE-CHAR-20-2E-20-2240ANTS-ROUTES-2FURL-PATTERN-22-29-20PACKAGE-29"></a>

#### [package](afcc) `40ants-routes/url-pattern`

<a id="x-2840ANTS-ROUTES-DOCS-2FINDEX-3A-3A-7C-4040ANTS-ROUTES-2FURL-PATTERN-3FClasses-SECTION-7C-2040ANTS-DOC-2FLOCATIVES-3ASECTION-29"></a>

#### Classes

<a id="x-2840ANTS-ROUTES-DOCS-2FINDEX-3A-3A-4040ANTS-ROUTES-2FURL-PATTERN-24URL-PATTERN-3FCLASS-2040ANTS-DOC-2FLOCATIVES-3ASECTION-29"></a>

##### URL-PATTERN

<a id="x-2840ANTS-ROUTES-2FURL-PATTERN-3AURL-PATTERN-20CLASS-29"></a>

###### [class](8db7) `40ants-routes/url-pattern:url-pattern` ()

**Readers**

<a id="x-2840ANTS-ROUTES-2FURL-PATTERN-3AURL-PATTERN-PARAMS-20-2840ANTS-DOC-2FLOCATIVES-3AREADER-2040ANTS-ROUTES-2FURL-PATTERN-3AURL-PATTERN-29-29"></a>

###### [reader](6e7e) `40ants-routes/url-pattern:url-pattern-params` (url-pattern) (:params)

Alist with parameter types

<a id="x-2840ANTS-ROUTES-2FURL-PATTERN-3AURL-PATTERN-PATTERN-20-2840ANTS-DOC-2FLOCATIVES-3AREADER-2040ANTS-ROUTES-2FURL-PATTERN-3AURL-PATTERN-29-29"></a>

###### [reader](333e) `40ants-routes/url-pattern:url-pattern-pattern` (url-pattern) (:pattern)

<a id="x-2840ANTS-ROUTES-2FURL-PATTERN-3AURL-PATTERN-REGEX-20-2840ANTS-DOC-2FLOCATIVES-3AREADER-2040ANTS-ROUTES-2FURL-PATTERN-3AURL-PATTERN-29-29"></a>

###### [reader](3c4b) `40ants-routes/url-pattern:url-pattern-regex` (url-pattern) (:regex)

<a id="x-2840ANTS-ROUTES-DOCS-2FINDEX-3A-3A-7C-4040ANTS-ROUTES-2FURL-PATTERN-3FFunctions-SECTION-7C-2040ANTS-DOC-2FLOCATIVES-3ASECTION-29"></a>

#### Functions

<a id="x-2840ANTS-ROUTES-2FURL-PATTERN-3APARSE-URL-PATTERN-20FUNCTION-29"></a>

##### [function](7e69) `40ants-routes/url-pattern:parse-url-pattern` pattern

Parse a `URL` pattern and extract parameter specifications.

Returns an object of class [`url-pattern`][a13f].

<a id="x-2840ANTS-ROUTES-2FURL-PATTERN-3AURL-PATTERN-EQUAL-20FUNCTION-29"></a>

##### [function](b710) `40ants-routes/url-pattern:url-pattern-equal` left right

Compares two [`url-pattern`][a13f] objects

<a id="x-2840ANTS-ROUTES-2FURL-PATTERN-3AURL-PATTERN-P-20FUNCTION-29"></a>

##### [function](c319) `40ants-routes/url-pattern:url-pattern-p` obj

<a id="x-2840ANTS-ROUTES-DOCS-2FINDEX-3A-3A-4040ANTS-ROUTES-2FWITH-URL-3FPACKAGE-2040ANTS-DOC-2FLOCATIVES-3ASECTION-29"></a>

### 40ANTS-ROUTES/WITH-URL

<a id="x-28-23A-28-2822-29-20BASE-CHAR-20-2E-20-2240ANTS-ROUTES-2FWITH-URL-22-29-20PACKAGE-29"></a>

#### [package](29a6) `40ants-routes/with-url`

<a id="x-2840ANTS-ROUTES-DOCS-2FINDEX-3A-3A-7C-4040ANTS-ROUTES-2FWITH-URL-3FMacros-SECTION-7C-2040ANTS-DOC-2FLOCATIVES-3ASECTION-29"></a>

#### Macros

<a id="x-2840ANTS-ROUTES-2FWITH-URL-3AWITH-PARTIALLY-MATCHED-URL-20-2840ANTS-DOC-2FLOCATIVES-3AMACRO-29-29"></a>

##### [macro](109c) `40ants-routes/with-url:with-partially-matched-url` (root-routes url) &body body

Execute body with the current routes object corresponding to a given `URL` argument.

Difference between this macro and [`with-url`][1c5e] macro is that [`with-url`][1c5e] signals an error
if it is unable to find a leaf route matching to the whole `URL`.

[`with-partially-matched-url`][1a23] will try to find a routes path matching as much
of `URL` as possible. As the result, [`40ants-routes/route:current-route-p`][087c] function
might return `NIL` when `URL` was not fully matched by [`with-partially-matched-url`][1a23].

<a id="x-2840ANTS-ROUTES-2FWITH-URL-3AWITH-URL-20-2840ANTS-DOC-2FLOCATIVES-3AMACRO-29-29"></a>

##### [macro](974f) `40ants-routes/with-url:with-url` (root-routes url) &body body

Execute body with the current routes object corresponding to a given `URL` argument.


[e419]: https://40ants.com/routes/#x-2840ANTS-ROUTES-2FBREADCRUMBS-3ABREADCRUMB-20CLASS-29
[3f6e]: https://40ants.com/routes/#x-2840ANTS-ROUTES-2FBREADCRUMBS-3ABREADCRUMB-PATH-20-2840ANTS-DOC-2FLOCATIVES-3AREADER-2040ANTS-ROUTES-2FBREADCRUMBS-3ABREADCRUMB-29-29
[920e]: https://40ants.com/routes/#x-2840ANTS-ROUTES-2FBREADCRUMBS-3ABREADCRUMB-ROUTE-20-2840ANTS-DOC-2FLOCATIVES-3AREADER-2040ANTS-ROUTES-2FBREADCRUMBS-3ABREADCRUMB-29-29
[b28f]: https://40ants.com/routes/#x-2840ANTS-ROUTES-2FBREADCRUMBS-3ABREADCRUMB-TITLE-20-2840ANTS-DOC-2FLOCATIVES-3AREADER-2040ANTS-ROUTES-2FBREADCRUMBS-3ABREADCRUMB-29-29
[bd21]: https://40ants.com/routes/#x-2840ANTS-ROUTES-2FBREADCRUMBS-3AGET-BREADCRUMBS-20FUNCTION-29
[3455]: https://40ants.com/routes/#x-2840ANTS-ROUTES-2FDEFROUTES-3ADEFROUTES-20-2840ANTS-DOC-2FLOCATIVES-3AMACRO-29-29
[f902]: https://40ants.com/routes/#x-2840ANTS-ROUTES-2FDEFROUTES-3AGET-20-2840ANTS-DOC-2FLOCATIVES-3AMACRO-29-29
[2897]: https://40ants.com/routes/#x-2840ANTS-ROUTES-2FDEFROUTES-3AINCLUDE-20FUNCTION-29
[a861]: https://40ants.com/routes/#x-2840ANTS-ROUTES-2FDEFROUTES-3APOST-20-2840ANTS-DOC-2FLOCATIVES-3AMACRO-29-29
[c587]: https://40ants.com/routes/#x-2840ANTS-ROUTES-2FDEFROUTES-3APUT-20-2840ANTS-DOC-2FLOCATIVES-3AMACRO-29-29
[2977]: https://40ants.com/routes/#x-2840ANTS-ROUTES-2FERRORS-3ANO-ROUTE-FOR-URL-ERROR-20CONDITION-29
[3eec]: https://40ants.com/routes/#x-2840ANTS-ROUTES-2FGENERICS-3AHAS-NAMESPACE-P-20GENERIC-FUNCTION-29
[db92]: https://40ants.com/routes/#x-2840ANTS-ROUTES-2FGENERICS-3ANODE-NAMESPACE-20GENERIC-FUNCTION-29
[e530]: https://40ants.com/routes/#x-2840ANTS-ROUTES-2FHANDLER-3ACALL-HANDLER-20FUNCTION-29
[087c]: https://40ants.com/routes/#x-2840ANTS-ROUTES-2FROUTE-3ACURRENT-ROUTE-P-20FUNCTION-29
[377c]: https://40ants.com/routes/#x-2840ANTS-ROUTES-2FROUTE-3AROUTE-20CLASS-29
[fe8a]: https://40ants.com/routes/#x-2840ANTS-ROUTES-2FROUTE-URL-3AROUTE-URL-20FUNCTION-29
[77f9]: https://40ants.com/routes/#x-2840ANTS-ROUTES-2FROUTES-3AROUTES-20-2840ANTS-DOC-2FLOCATIVES-3AMACRO-29-29
[cce3]: https://40ants.com/routes/#x-2840ANTS-ROUTES-2FROUTES-3AROUTES-20CLASS-29
[a13f]: https://40ants.com/routes/#x-2840ANTS-ROUTES-2FURL-PATTERN-3AURL-PATTERN-20CLASS-29
[1a23]: https://40ants.com/routes/#x-2840ANTS-ROUTES-2FWITH-URL-3AWITH-PARTIALLY-MATCHED-URL-20-2840ANTS-DOC-2FLOCATIVES-3AMACRO-29-29
[1c5e]: https://40ants.com/routes/#x-2840ANTS-ROUTES-2FWITH-URL-3AWITH-URL-20-2840ANTS-DOC-2FLOCATIVES-3AMACRO-29-29
[d39a]: https://40ants.com/routes/#x-2840ANTS-ROUTES-DOCS-2FINDEX-3A-3A-40DEFINING-ROUTES-2040ANTS-DOC-2FLOCATIVES-3ASECTION-29
[af0d]: https://40ants.com/routes/#x-2840ANTS-ROUTES-DOCS-2FINDEX-3A-3A-40MATCHING-THE-URL-2040ANTS-DOC-2FLOCATIVES-3ASECTION-29
[475a]: https://github.com/40ants/routes/blob/ed35b6c5e459baf815cb22cdf21856fd47860225/src/breadcrumbs.lisp#L1
[9002]: https://github.com/40ants/routes/blob/ed35b6c5e459baf815cb22cdf21856fd47860225/src/breadcrumbs.lisp#L35
[824f]: https://github.com/40ants/routes/blob/ed35b6c5e459baf815cb22cdf21856fd47860225/src/breadcrumbs.lisp#L36
[272a]: https://github.com/40ants/routes/blob/ed35b6c5e459baf815cb22cdf21856fd47860225/src/breadcrumbs.lisp#L39
[1a3f]: https://github.com/40ants/routes/blob/ed35b6c5e459baf815cb22cdf21856fd47860225/src/breadcrumbs.lisp#L42
[e66c]: https://github.com/40ants/routes/blob/ed35b6c5e459baf815cb22cdf21856fd47860225/src/breadcrumbs.lisp#L84
[ffcf]: https://github.com/40ants/routes/blob/ed35b6c5e459baf815cb22cdf21856fd47860225/src/breadcrumbs.lisp#L92
[c8d7]: https://github.com/40ants/routes/blob/ed35b6c5e459baf815cb22cdf21856fd47860225/src/defroutes.lisp#L1
[fbf9]: https://github.com/40ants/routes/blob/ed35b6c5e459baf815cb22cdf21856fd47860225/src/defroutes.lisp#L120
[de3a]: https://github.com/40ants/routes/blob/ed35b6c5e459baf815cb22cdf21856fd47860225/src/defroutes.lisp#L124
[25b8]: https://github.com/40ants/routes/blob/ed35b6c5e459baf815cb22cdf21856fd47860225/src/defroutes.lisp#L128
[ddcf]: https://github.com/40ants/routes/blob/ed35b6c5e459baf815cb22cdf21856fd47860225/src/defroutes.lisp#L140
[84c5]: https://github.com/40ants/routes/blob/ed35b6c5e459baf815cb22cdf21856fd47860225/src/defroutes.lisp#L34
[9461]: https://github.com/40ants/routes/blob/ed35b6c5e459baf815cb22cdf21856fd47860225/src/defroutes.lisp#L72
[5ad2]: https://github.com/40ants/routes/blob/ed35b6c5e459baf815cb22cdf21856fd47860225/src/errors.lisp#L1
[d36b]: https://github.com/40ants/routes/blob/ed35b6c5e459baf815cb22cdf21856fd47860225/src/errors.lisp#L24
[ff98]: https://github.com/40ants/routes/blob/ed35b6c5e459baf815cb22cdf21856fd47860225/src/errors.lisp#L35
[ff8f]: https://github.com/40ants/routes/blob/ed35b6c5e459baf815cb22cdf21856fd47860225/src/errors.lisp#L49
[e606]: https://github.com/40ants/routes/blob/ed35b6c5e459baf815cb22cdf21856fd47860225/src/errors.lisp#L63
[e635]: https://github.com/40ants/routes/blob/ed35b6c5e459baf815cb22cdf21856fd47860225/src/errors.lisp#L74
[222f]: https://github.com/40ants/routes/blob/ed35b6c5e459baf815cb22cdf21856fd47860225/src/errors.lisp#L85
[7c07]: https://github.com/40ants/routes/blob/ed35b6c5e459baf815cb22cdf21856fd47860225/src/find-route.lisp#L1
[312f]: https://github.com/40ants/routes/blob/ed35b6c5e459baf815cb22cdf21856fd47860225/src/find-route.lisp#L103
[db29]: https://github.com/40ants/routes/blob/ed35b6c5e459baf815cb22cdf21856fd47860225/src/generics.lisp#L1
[0da6]: https://github.com/40ants/routes/blob/ed35b6c5e459baf815cb22cdf21856fd47860225/src/generics.lisp#L14
[1080]: https://github.com/40ants/routes/blob/ed35b6c5e459baf815cb22cdf21856fd47860225/src/generics.lisp#L30
[538e]: https://github.com/40ants/routes/blob/ed35b6c5e459baf815cb22cdf21856fd47860225/src/generics.lisp#L42
[343a]: https://github.com/40ants/routes/blob/ed35b6c5e459baf815cb22cdf21856fd47860225/src/generics.lisp#L48
[5770]: https://github.com/40ants/routes/blob/ed35b6c5e459baf815cb22cdf21856fd47860225/src/generics.lisp#L52
[a0cf]: https://github.com/40ants/routes/blob/ed35b6c5e459baf815cb22cdf21856fd47860225/src/generics.lisp#L58
[c31e]: https://github.com/40ants/routes/blob/ed35b6c5e459baf815cb22cdf21856fd47860225/src/generics.lisp#L62
[a778]: https://github.com/40ants/routes/blob/ed35b6c5e459baf815cb22cdf21856fd47860225/src/generics.lisp#L68
[0311]: https://github.com/40ants/routes/blob/ed35b6c5e459baf815cb22cdf21856fd47860225/src/handler.lisp#L1
[8de2]: https://github.com/40ants/routes/blob/ed35b6c5e459baf815cb22cdf21856fd47860225/src/handler.lisp#L15
[2b55]: https://github.com/40ants/routes/blob/ed35b6c5e459baf815cb22cdf21856fd47860225/src/included-routes.lisp#L1
[da55]: https://github.com/40ants/routes/blob/ed35b6c5e459baf815cb22cdf21856fd47860225/src/included-routes.lisp#L20
[b602]: https://github.com/40ants/routes/blob/ed35b6c5e459baf815cb22cdf21856fd47860225/src/included-routes.lisp#L21
[8ec7]: https://github.com/40ants/routes/blob/ed35b6c5e459baf815cb22cdf21856fd47860225/src/included-routes.lisp#L25
[cba3]: https://github.com/40ants/routes/blob/ed35b6c5e459baf815cb22cdf21856fd47860225/src/included-routes.lisp#L39
[382c]: https://github.com/40ants/routes/blob/ed35b6c5e459baf815cb22cdf21856fd47860225/src/matched-route.lisp#L1
[1172]: https://github.com/40ants/routes/blob/ed35b6c5e459baf815cb22cdf21856fd47860225/src/matched-route.lisp#L22
[d0e1]: https://github.com/40ants/routes/blob/ed35b6c5e459baf815cb22cdf21856fd47860225/src/matched-route.lisp#L23
[e57f]: https://github.com/40ants/routes/blob/ed35b6c5e459baf815cb22cdf21856fd47860225/src/matched-route.lisp#L27
[1c69]: https://github.com/40ants/routes/blob/ed35b6c5e459baf815cb22cdf21856fd47860225/src/matched-route.lisp#L44
[f689]: https://github.com/40ants/routes/blob/ed35b6c5e459baf815cb22cdf21856fd47860225/src/route-url.lisp#L1
[c11c]: https://github.com/40ants/routes/blob/ed35b6c5e459baf815cb22cdf21856fd47860225/src/route-url.lisp#L27
[ccaf]: https://github.com/40ants/routes/blob/ed35b6c5e459baf815cb22cdf21856fd47860225/src/route.lisp#L1
[a90d]: https://github.com/40ants/routes/blob/ed35b6c5e459baf815cb22cdf21856fd47860225/src/route.lisp#L30
[e305]: https://github.com/40ants/routes/blob/ed35b6c5e459baf815cb22cdf21856fd47860225/src/route.lisp#L31
[6b1c]: https://github.com/40ants/routes/blob/ed35b6c5e459baf815cb22cdf21856fd47860225/src/route.lisp#L35
[248f]: https://github.com/40ants/routes/blob/ed35b6c5e459baf815cb22cdf21856fd47860225/src/route.lisp#L39
[b349]: https://github.com/40ants/routes/blob/ed35b6c5e459baf815cb22cdf21856fd47860225/src/route.lisp#L43
[06c0]: https://github.com/40ants/routes/blob/ed35b6c5e459baf815cb22cdf21856fd47860225/src/route.lisp#L48
[a269]: https://github.com/40ants/routes/blob/ed35b6c5e459baf815cb22cdf21856fd47860225/src/route.lisp#L66
[a31f]: https://github.com/40ants/routes/blob/ed35b6c5e459baf815cb22cdf21856fd47860225/src/route.lisp#L78
[a15e]: https://github.com/40ants/routes/blob/ed35b6c5e459baf815cb22cdf21856fd47860225/src/route.lisp#L86
[db9b]: https://github.com/40ants/routes/blob/ed35b6c5e459baf815cb22cdf21856fd47860225/src/routes.lisp#L1
[5adc]: https://github.com/40ants/routes/blob/ed35b6c5e459baf815cb22cdf21856fd47860225/src/routes.lisp#L21
[dd63]: https://github.com/40ants/routes/blob/ed35b6c5e459baf815cb22cdf21856fd47860225/src/routes.lisp#L22
[40d6]: https://github.com/40ants/routes/blob/ed35b6c5e459baf815cb22cdf21856fd47860225/src/routes.lisp#L26
[e2ff]: https://github.com/40ants/routes/blob/ed35b6c5e459baf815cb22cdf21856fd47860225/src/routes.lisp#L39
[afcc]: https://github.com/40ants/routes/blob/ed35b6c5e459baf815cb22cdf21856fd47860225/src/url-pattern.lisp#L1
[c319]: https://github.com/40ants/routes/blob/ed35b6c5e459baf815cb22cdf21856fd47860225/src/url-pattern.lisp#L172
[b710]: https://github.com/40ants/routes/blob/ed35b6c5e459baf815cb22cdf21856fd47860225/src/url-pattern.lisp#L179
[8db7]: https://github.com/40ants/routes/blob/ed35b6c5e459baf815cb22cdf21856fd47860225/src/url-pattern.lisp#L24
[333e]: https://github.com/40ants/routes/blob/ed35b6c5e459baf815cb22cdf21856fd47860225/src/url-pattern.lisp#L25
[3c4b]: https://github.com/40ants/routes/blob/ed35b6c5e459baf815cb22cdf21856fd47860225/src/url-pattern.lisp#L28
[6e7e]: https://github.com/40ants/routes/blob/ed35b6c5e459baf815cb22cdf21856fd47860225/src/url-pattern.lisp#L31
[7e69]: https://github.com/40ants/routes/blob/ed35b6c5e459baf815cb22cdf21856fd47860225/src/url-pattern.lisp#L46
[29a6]: https://github.com/40ants/routes/blob/ed35b6c5e459baf815cb22cdf21856fd47860225/src/with-url.lisp#L1
[109c]: https://github.com/40ants/routes/blob/ed35b6c5e459baf815cb22cdf21856fd47860225/src/with-url.lisp#L112
[974f]: https://github.com/40ants/routes/blob/ed35b6c5e459baf815cb22cdf21856fd47860225/src/with-url.lisp#L86

* * *
###### [generated by [40ANTS-DOC](https://40ants.com/doc/)]
