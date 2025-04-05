# 40ants-routes

[![](https://github-actions.40ants.com/40ants/routes/matrix.svg?only=ci.run-tests)](https://github.com/40ants/routes/actions)

Framework agnostic URL routing library for Common Lisp.

## Overview

40ants-routes is a framework-agnostic URL routing library for Common Lisp, inspired by Django's URL routing system. It provides a clean and flexible way to define URL routes, generate URLs, and handle URL parameters.

## Features

* Define routes with namespaces
* Include routes from libraries into applications
* Generate URLs based on route names
* Handle URL parameters
* Generate breadcrumbs
* Support for different types of routes (server, application, library)

## Installation

```lisp
(ql:quickload :40ants-routes)
```

## Usage

### Defining Routes

Routes can be defined using the `defroutes` macro:

```lisp
(defroutes (*blog-routes* :namespace "blog")
  (url ("/" :name "index")
       (make-all-posts-page))
  (url ("/<string:slug>" :name "post")
       (make-post-page slug)))
```

### Including Routes

Routes from libraries can be included in application routes:

```lisp
(defroutes (*app-routes* :namespace "app")
  (url ("/" :name "index")
       (make-all-posts-page))
  (include *blog-routes*))
```

### Generating URLs

URLs can be generated using the `route-url` function:

```lisp
(route-url "index")  ; => "/"
(route-url "index" :namespace "blog")  ; => "/blog/"
(route-url "post" :namespace "blog" :slug "hello-world")  ; => "/blog/hello-world"
```

### Setting Context

The current namespace can be set using the `with-routes-context` macro:

```lisp
(with-routes-context "app"
  (route-url "index"))  ; => "/"
```

### Generating Breadcrumbs

Breadcrumbs can be generated using the `get-breadcrumbs` function:

```lisp
(get-breadcrumbs "/admin/users/123")
; => ((("/" . "Home") ("/admin" . "Admin") ("/admin/users" . "Users") ("/admin/users/123" . "User Profile")))
```

## Documentation

Full documentation is available at [https://40ants.com/routes/](https://40ants.com/routes/).

## License

Unlicense
