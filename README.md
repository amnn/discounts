# Discounts

A demonstration implementation of discounts in an Ordering system.

# Algorithm

The algorithm is a variant of
[Algorithm X](http://en.wikipedia.org/wiki/Knuth%27s_Algorithm_X)
using the Sparse Matrix data structure from
[Dancing Links](http://en.wikipedia.org/wiki/Dancing_Links).

Instead of solving the [Exact Cover](http://en.wikipedia.org/wiki/Exact_cover)
problem, this algorithm finds all the unique partial covers (of which the
exact covers are a subset). A partial cover is just a set of disjoint subsets.

This can be used when applying discounts to the order:

 * Consider the order as a set of items `O`.
 * Let `D ⊆ P(O)×R` be the set of discounts where each discount is a pair
   `(O',s)` where `O' ⊆ O` and `s ∈ R`. `O'` is the set of items in the
   order that the discount covers, and `s` is the savings from applying the
   discount.

We may use our algorithm to find all the partial covers of `O` in `D'`,
where `D' =  { O' | (O',s) ∈ D }`. From this we can find our solution by
producing the cover whose sum over the savings is maximal in comparison to the
others.
