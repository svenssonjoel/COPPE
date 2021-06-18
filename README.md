# Coppe [pronounced Cob](https://www.youtube.com/watch?v=BhuQQKCkkxs)

Coppe is an experimental EDSL for machine learning implemented in Haskell.


## Purpose and aims

1. An EDSL that gives some guarantees about "OK"-ness of neural net.
   To begin with that input output interfaces between layers are  of
   compatible shape.
2. Extensible EDSL. It must be possible to add new kinds of layers without
   rewriting the internal representation data structure for each addition.
3. Serializable/deserializable intermediate representation of networks.

