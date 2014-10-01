require './sparse_matrix'

def deal_matrix(deals, order)
  SparseMatrix.new(
    deals.flat_map { |d| d.apply(order) },
    order) do |discount, item|
      discount.items.include? item.item_id
    end
end

def calculate_discount(deals, order)
  deal_matrix(deals, order)
    .covering_rows
end
