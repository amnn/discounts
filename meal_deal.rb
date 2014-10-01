require 'set'
require './discount'

class OrderItem < Struct.new(:item_id, :name, :price)
  def to_s
    "Item[#{item_id}](#{name}, #{price})"
  end
end

class Discount < Struct.new(:items, :savings)
  def to_s
    "Discount(#{savings}) #{items.inspect}"
  end
end

class Deal
  @next_id = 0
  def self.next_id
    @next_id += 1
  end

  attr_reader :id
  def initialize(&blk)
    @id = Deal.next_id
    @blk = blk
  end

  def apply(order)
    @blk.call(order)
  end
end

deals = [
  # 20% Off Food + Drink Combinations
  Deal.new do |order|
    food_items, drink_items =
      %W(Food Drink).map do  |i|
        r = /#{i}/
        order.select { |oi| r =~ oi.name }
      end

      food_items
        .product(drink_items)
        .map do |deal|
          Discount[
            Set[*deal.map(&:item_id)],
            (deal.map(&:price).reduce(&:+) * 0.2).to_i]
        end
  end,

  # 2 for 1 drinks.
  Deal.new do |order|
    order
      .select { |oi| /Drink/ =~ oi.name }
      .combination(2)
      .map do |drinks|
        Discount[
          Set[*drinks.map(&:item_id)],
          drinks.map(&:price).min]
      end
  end]

order = [
  OrderItem[1, "Food 1", 1000],
  OrderItem[2, "Food 2", 2000],
  OrderItem[3, "Drink 1", 300],
  OrderItem[4, "Drink 2", 400]]

p calculate_discount(deals, order)
