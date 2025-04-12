(uiop:define-package #:40ants-routes/generics
  (:use #:cl))
(in-package #:40ants-routes/generics)


(defgeneric match-url (obj url &key on-match)
  (:documentation
   "Checks for complete match of the object to URL.

    Should return an OBJ if it fully matches to a given url.
    May return a sub-object if OBJ matches to a prefix
    and sub-object matches the rest of URL.

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
