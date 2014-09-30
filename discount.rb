require './sparse_matrix'

def calculate_discount(deals, order)
  matrix =
    SparseMatrix.new(
      deals.flat_map { |d| d.apply(order) },
      order) do |discount, item|
        discount.items.include? item.item_id
      end

  matrix
end
