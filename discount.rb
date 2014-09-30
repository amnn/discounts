def calculate_discount(deals, order)
  discounts =
    deals.flat_map { |d| d.apply(order) }

  discounts
end
