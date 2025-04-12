(uiop:define-package #:40ants-routes/generics
  (:use #:cl))
(in-package #:40ants-routes/generics)


(defgeneric match-url (obj url)
  (:documentation
   "Checks for complete match of the object to URL.

    Should return an OBJ itself or a list like
    `(list obj sub-obj-1 sub-obj-2)` where the final
    subobjects matches to the end of the URL."))


(defgeneric partial-match-url (obj url)
  (:documentation
   "Tests of obj matches to the a prefix of URL.

    If match was found, should return two
    values: the object which matches and position of
    the character after the matched prefix.

    If OBJ is a compound element, then
    a sub-element can be returned in case of match."))
