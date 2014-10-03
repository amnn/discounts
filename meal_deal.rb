require 'set'
require './discount'

##### Models #####
class OrderItem < Struct.new(:item_id, :name, :price)
  def to_s
    "Item[#{item_id}](#{name}, #{price})"
  end
end

=begin
A Discount is an application of a Deal to a particular set of items found in
an Order.
=end

class Discount < Struct.new(:name, :items, :savings)
  def to_s
    "Discount[#{name}](#{savings}) #{items.inspect}"
  end
end

=begin
A Deal is applied to an order to get a hash mapping sets of item ids to a
discount.
=end

class Deal
  @next_id = 0
  def self.next_id
    @next_id += 1
  end

  attr_reader :id, :name
  def initialize(name, &blk)
    @id = Deal.next_id
    @name = name
    @blk = blk
  end

  def apply(order)
    Hash[*instance_exec(order, &@blk).flatten]
  end

  def discount(items, savings)
    key = Set[*items.map(&:item_id)]
    [key, Discount[@name, key, savings]]
  end
end

deals = [
  Deal.new("20% off Food + Drink Combinations") do |order|
    food_items, drink_items =
      %W(Food Drink).map do  |i|
        r = /#{i}/
        order.select { |oi| r =~ oi.name }
      end

    food_items
      .product(drink_items)
      .map do |items|
        discount(items, (items.reduce(0) { |s,i| s + i.price } * 0.2).to_i)
      end
  end,

  Deal.new("2 for 1 drinks, cheapest one free.") do |order|
    order
      .select { |oi| /Drink/ =~ oi.name }
      .combination(2)
      .map do |drinks|
        discount(drinks, drinks.map(&:price).min)
      end
  end,

  Deal.new("2 for 1 anything, expensive one free.") do |order|
    order
      .combination(2)
      .map do |items|
        discount(items, items.map(&:price).max)
      end
  end]

order = [
  OrderItem[1, "Food 1", 1000],
  OrderItem[2, "Food 2", 2000],
  OrderItem[3, "Drink 1", 300],
  OrderItem[4, "Drink 2", 400]]

p calculate_discount(deals, order)
