=begin
Implementation of the Sparse Matrix from Knuth's DLX algorithm (Dancing Links)
http://en.wikipedia.org/wiki/Dancing_Links
=end

class SparseMatrix
=begin
  The Matrix consists of a grid of nodes, each has a left, right, top (up),
  and bottom (down) neighbour, as well as a row and column it is associated
  with.

     H  -- C1 -- C2 -- C3 (-- H)
     |     |     |     |
     R1 -- *  ---+---- *  (-- R1)
     |     |     |     |
     R2 ---+---- *  (--+----- R2)
     |     |     |     |
     R3 -- *  ---+---- *  (-- R3)
    (| )  (| )  (| )  (| )
    (H )  (C1)  (C2)  (C3)

  The diagram above describes the structure used to represent the matrix:

     C 1 2 3
   R +-------+
   1 | 1 0 1 |
   2 | 0 1 0 |
   3 | 1 0 1 |
     +-------+

  In the diagram `H` is the header node, `Rx` and `Cx` refer to row and column
  nodes respectively. `--` and `|` are used to represent left-right and up-down
  relationships between nodes. E.g. `x -- y` means:

    x.left = y
    y.right = x

  Relationships in parentheses are used to denote a cyclic relationship. E.g.

    C3 (-- H)

  means that column node 3 wraps back round and connects to the header node.

  Relationships with arrow heads denote one-way relationships. E.g.

    x <- y -> Z

  Means:

    y.left = x
    y.right = z

  But it provides no information about `x.right` or `z.left`.

  Finally, `*` represents an internal node of the matrix (representing a `1`)
  in the matrix. The `+` signs denote relationships crossing over each other
  in the diagram (they are a feature of the diagram only, and not the actual
  structure in memory).

  This representation is used for boolean matrices only (the entries can only
  be 1 or 0) and it only stores the entries which contain `1`'s.
=end
  class Node < Struct.new(:datum,
                          :up, :down,
                          :left, :right,
                          :row, :col)
    # Creates a brand-new header (H) node.
    # All pointers in the node point to itself, as it represents a completely
    # empty matrix with no rows or columns:
    #
    #   H (-- H)
    #  (|)
    #  (H)

    def self.header
      head = new
      head.left = head.right =
        head.up = head.down =
        head.row = head.col = head
    end

    # Creates a new row (R) node, with `datum` as its datum element, `up` as
    # the previous row node and `head` as the head node:
    #
    #   ⋮
    #   up -- ⋯
    #   |
    #   R (-- R)
    #  (|)
    #  (H)

    def self.empty_row(datum, up, head)
      row = new(datum, up, head, nil, nil, nil, head)

      up.down = head.up = row.row =
        row.left = row.right = row
    end

    # Creates an empty column (C) node, with `datum` as its datum element,
    # `left` as the previous column node and `head` as the head node:
    #
    #    ⋯ -- left -- C (-- H)
    #           |    (|)
    #           ⋮    (C)

    def self.empty_col(datum, left, head)
      col = new(datum, nil, nil, left, head, head, nil)

      left.right = head.left = col.col =
        col.up = col.down = col
    end

    # Creates an internal entry (*) node, with the given neighbours,
    # row and column:
    #
    #           up
    #           ^
    #   left <- * -> right
    #           v
    #           down
    #
    # Because entry nodes simply represent one, they do not use their
    # `datum` field, it is just set to `nil`.

    def self.entry(up, down, left, right, row, col)
      new(nil, up, down, left, right, row, col)
    end

    # Recovers the `head` node from any node in the matrix.
    # The column node of the row node is the head.
    # Equivalently the row node of the column node (`col.row`) is
    # also the head.

    def head
      row.col
    end

    # Removes this node from its vertical relationship. I.e. it does the
    # following:
    #
    #   up             +> up
    #   |              |  |
    #   *     BECOMES  *  |
    #   |              |  |
    #   down           +> down
    #
    # So if we look at the structure from the point of view of `up` or `down`
    # it looks like this:
    #
    #   up
    #   |
    #   down
    #
    # But from the point of view of `*`, it is still as it was before.
    #
    # This allows us to recover the original structure of the matrix if we
    # keep hold of `*`, and insert it again later.

    def remove!
      up.down = down
      down.up = up
      self
    end

    # Joins the node back up to all of its neighbours (Doing the opposite of
    # `remove!`).
    def insert!
      left.right = right.left =
        up.down = down.up = self
    end

    # Checks whether the node has been inserted.
    def inserted?
      up.down.equal?(self) &&
        down.up.equal?(self) &&
        left.right.equal?(self) &&
        right.left.equal?(self)
    end

    # Checks whether the node has been removed.
    def removed?
      !inserted?
    end

    # If this entry is in the last row, then if we try to go `down`, we will
    # loop around and reach its column node, due to the cyclic linked list
    # structure.
    def last_row?
      down.equal? col
    end

    # If this entry is in the last column, then if we try to go `right`, we
    # loop round and reach its row node, due to the cyclic linked list
    # structure.
    def last_col?
      right.equal? row
    end

    # the `H`, `C` and `R` nodes are *sentinel* nodes. This means they are not
    # used to represent the data, but instead are there to aid in describing
    # the structure.

    # A node is a column sentinel node (a `C` node) if its column pointer
    # points to itself.
    def col_sentinel?
      equal? col
    end

    # A node is a row sentinel node (an `R` node) if its row pointer points
    # to itself.
    def row_sentinel?
      equal? row
    end

    # Iterate through each subsequent row from this one (not inclusive) to
    # the last row (inclusive).
    def rows # yields #
      r = self
      loop do
        r = r.down
        break if r.col_sentinel?
        yield r
      end
    end

    # Iterate through each subsequence column from this one (not inclusive) to
    # the last column (inclusive).
    def cols # yields #
      c = self
      loop do
        c = c.right
        break if c.row_sentinel?
        yield c
      end
    end
  end

  # Creates a new SparseMatrix instance.
  # Takes an `Enumerable` of data for row elements, `rs`, and equivalently
  # data for column elements, `cs` and then a 2-arity predicate block.
  #
  # It then builds an empty SparseMatrix with the appropriate rows and
  # columns, and iterates through every possible element inside the matrix,
  # passing its row and column to the block. If the block returns true,
  # an entry is added at that position.
  #
  # To create the matrix described at the top of the file, we can do the
  # following:

  #   SparseMatrix.new(1..3, 1..3) { |r,c| (r+c).even? }
  #     => 1: 1, 3
  #        2: 2
  #        3: 1, 3

  # This means that rows have elements 1 through to 3, and so do columns. Then,
  # if the sum of the row and column values is even, we want that entry
  # to be a 1.

  def initialize(rs, cs, &assoc)
    @head = Node.header
    @rows = build_axis(rs, @head, &Node.method(:empty_row))
    @cols = build_axis(cs, @head, &Node.method(:empty_col))

    @rows.each do |row|
      @cols.each do |col|
        if assoc[row.datum, col.datum]
          Node
            .entry(col.up, col, row.left, row, row, col)
            .insert!
        end
      end
    end
  end

  # Exposes the row iterator from the head node, or a provided node, as long
  # as it belongs to this matrix.
  def rows(from = @head, &blk)
    unless from.head.equal? @head
      raise ArgumentError, "Row does not match matrix"
    end
    from.rows(&blk)
  end

  # Returns an `Array` of *coverings* where a covering is an `Array` of rows.
  #
  # A *covering* has the property that none of the rows in it intersect. So,
  # if there is an entry in a column `c` in a particular row in the covering,
  # then no other row in the covering will have an entry in `c`.
  #
  # The algorithm being used here is a modification of the Exact Cover
  # algorithm (specifically, Knuth's Algorithm X), designed to be more loosely
  # constrained in that we are not looking for Exact covers: We are happy with
  # partial covers also.
  #
  # http://en.wikipedia.org/wiki/Knuth%27s_Algorithm_X

  def covering_rows(from = @head)
    # If there are no more rows, the search space is empty, the only
    # covering is the empty covering.
    return [[]] if from.last_row?

    # Otherwise iterate through the remaining rows, and for each row:
    enum_for(:rows, from).flat_map do |row|
      removals = []

      row.cols do |cell_x|                    # For each entry in the row.
        cell_x.col.rows do |cell_y|           # Find all the rows that also
          r = cell_y.row                      # have an entry in this column.
          unless r.removed? || r.equal?(row)  # And remove them, unless they
            removals.unshift r.remove!        # have already been removed.
          end                                 # (Or they are the row you are
        end                                   # currently iterating over).
      end

      # We must remove the row we are iterating over last, so that its up/down
      # pointers get updated by all the previous removals. This is important,
      # because we use its `down` pointer to find the next available row, when
      # we recurse.
      removals.unshift row.remove!

      # Recursively call our algorithm, to find all the coverings using rows
      # below the current row (taking into account the rows we removed).
      # Additionally, we add our row to each covering: We can do this because
      # we know it will not conflict with any of the coverings returned,
      # because we removed all conflicting rows above, before recursing.
      coverings =
        covering_rows(row)
          .map { |rs| rs << row.datum }

      # Reinsert the removals, in reverse order of removal
      # (Order is important). And return the coverings.
      removals.each(&:insert!)
      coverings
    end
  end

  def inspect
    @head.enum_for(:rows).map do |r|
      "#{r.datum}: " <<
        r.enum_for(:cols).map do |c|
          c.col.datum
        end.join(", ")
    end.join("\n")
  end

  private
  def build_axis(data, head, &mk_node)
    data.reduce([head]) do |nodes, datum|
      nodes << mk_node[datum, nodes.last, head]
    end.tap(&:shift)
  end
end
