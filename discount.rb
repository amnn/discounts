require './sparse_matrix'

=begin
Creates the Sparse Matrix representing the discount problem:

Takes each deal and applies it to `order` to get all the possible discounts
that can be achieved using that particular deal on the given order, combining
them together to get the rows of the matrix. The columns are the items in the
`order`.

The entries are determined by whether the discount in the row was applied to
the item in the column.
=end

def deal_matrix(deals, order)
  SparseMatrix.new(
    deals.each_with_object({}) do |d, h|
      h.merge!(d.apply(order)) do |k, *ds|
        ds.max_by(&:savings)
      end
    end.values,
    order) do |discount, item|
      discount.items.include? item.item_id
    end
end

=begin
Find the best group of deals to apply to the order, and the items in the order
each deal is applied to.

This is done by taking the deal_matrix, and finding all the ways to cover it.
Finally, return the Array of discounts that provides the greatest total
savings.
=end

def calculate_discount(deals, order)
  deal_matrix(deals, order)
    .covering_rows
    .max_by do |discounts|
      discounts.reduce(0) do |acc, d|
        acc + d.savings
      end
    end
end
