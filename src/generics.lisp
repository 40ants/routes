(uiop:define-package #:40ants-routes/generics
  (:use #:cl)
  (:export #:match-url
           #:partial-match-url
           #:format-url
           #:url-path
           #:add-route
           #:node-namespace
           #:has-namespace-p))
(in-package #:40ants-routes/generics)


(defgeneric match-url (obj url &key on-match)
  (:documentation
   "Checks for complete match of the object to URL.

    Should return an OBJ if it fully matches to a given url.
    May return a sub-object if OBJ matches to a prefix
    and sub-object matches the rest of URL.

    If match was found, the second returned value
    should be a alist with matched parameters.

    If ON-MATCH argument is given, then in any case
    of match, full or prefix, calls ON-MATCH
    function with OBJ as a single argument."))


(defgeneric partial-match-url (obj url)
  (:documentation
   "Tests of obj matches to the a prefix of URL.

    If match was found, should return two
    values: the object which matches and position of
    the character after the matched prefix.

    If OBJ is a compound element, then
    a sub-element can be returned in case of match."))


(defgeneric format-url (obj stream args &optional route-name)
  (:documentation "Should write a piece of URL to the STREAM substituting arguments from plist ARGS.
                   
                   When called, it should write a piece of URL without starting backslash.
                   
                   The optional ROUTE-NAME parameter is used for error reporting when a required parameter is missing."))


(defgeneric url-path (obj)
  (:documentation "Returns the 40ANTS-ROUTES/URL-PATTERN::URL-PATTERN associated with the object."))


(defgeneric has-namespace-p (routes)
  (:documentation "Returns T of node can respond to NODE-NAMESPACE generic-function call.")
  (:method ((routes t))
    (values nil)))


(defgeneric node-namespace (routes)
  (:documentation "Returns a string name of node's namepace. Works only for objects for which HAS-NAMESPACE-P returns true."))


(defgeneric add-route (routes route-or-routes-to-add &key override)
  (:documentation "Add a route or included-routes object to the routes collection at runtime.
If a route with the same path or namespace already exists, an error will be signaled
unless override is set to true."))
