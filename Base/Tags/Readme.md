Tag Expressions
===============

Replaces tags in a tag expression by numbers and words.
Searches for files with a certain tagformat and returns tag ranges for them
useful to access numbered / labeled images in possibly multiple folders


Example
-------

texpr = 'this is <word, s> <count, 2>';
tags.word = 'example';
tags.count = 1;
tagExpressionToString(texpr,  tags)


Version
-------

Version 0.9 
Sep 2014

Copyright:
Christoph Kirst, 
Rockefeller University, 
ckirst@rockefeller.edu

