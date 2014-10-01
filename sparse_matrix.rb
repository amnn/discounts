class SparseMatrix
  class Node < Struct.new(:datum,
                          :up, :down,
                          :left, :right,
                          :row, :col)
    def self.header
      head = new
      head.left = head.right =
        head.up = head.down =
        head.row = head.col = head
    end

    def self.empty_row(datum, up, head)
      row = new(datum, up, head, nil, nil, nil, head)

      up.down = head.up = row.row =
        row.left = row.right = row
    end

    def self.empty_col(datum, left, head)
      col = new(datum, nil, nil, left, head, head, nil)

      left.right = head.left = col.col =
        col.up = col.down = col
    end

    def self.entry(up, down, left, right, row, col)
      new(nil, up, down, left, right, row, col)
    end

    def head
      row.col
    end

    def remove!
      up.down = down
      down.up = up
      self
    end

    def insert!
      left.right = right.left =
        up.down = down.up = self
    end

    def inserted?
      up.down.equal?(self) &&
        down.up.equal?(self) &&
        left.right.equal?(self) &&
        right.left.equal?(self)
    end

    def removed?
      !inserted?
    end

    def last_row?
      down.equal? col
    end

    def last_col?
      right.equal? row
    end

    def sentinel_row?
      equal? col
    end

    def sentinel_col?
      equal? row
    end

    def rows # yields #
      r = self
      loop do
        r = r.down
        break if r.sentinel_row?
        yield r
      end
    end

    def cols # yields #
      c = self
      loop do
        c = c.right
        break if c.sentinel_col?
        yield c
      end
    end
  end

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

  def rows(from = @head, &blk)
    unless from.head.equal? @head
      raise ArgumentError, "Row does not match matrix"
    end
    from.rows(&blk)
  end

  def covering_rows(from = @head)
    return [[]] if from.last_row?

    enum_for(:rows, from).flat_map do |row|
      removals = []

      row.cols do |cell_x|
        cell_x.col.rows do |cell_y|
          r = cell_y.row
          unless r.removed? || r.equal?(row)
            removals.unshift r.remove!
          end
        end
      end

      removals.unshift row.remove!

      coverings =
        covering_rows(row)
          .map { |rs| rs << row.datum }

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
