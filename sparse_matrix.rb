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

    def remove
      left.right = right
      right.left = left
      up.down = down
      down.up = up
      self
    end

    def insert
      left.right = right.left =
        up.down = down.up = self
    end

    def rows # yields #
      r = self
      loop do
        r = r.down
        break if r.equal? col
        yield r
      end
    end

    def cols # yields #
      c = self
      loop do
        c = c.right
        break if c.equal? row
        yield c
      end
    end
  end

  def initialize(rs, cs, &assoc)
    @head = Node.header
    @rows = build_line(rs, @head, &Node.method(:empty_row))
    @cols = build_line(cs, @head, &Node.method(:empty_col))

    @rows.each do |row|
      @cols.each do |col|
        if assoc[row.datum, col.datum]
          Node
            .entry(col.up, col, row.left, row, row, col)
            .insert
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

  def inspect
    @head.enum_for(:rows).map do |r|
      "#{r.datum}: " <<
        r.enum_for(:cols).map do |c|
          c.col.datum
        end.join(", ")
    end.join("\n")
  end

  private
  def build_line(data, head, &mk_node)
    data.reduce([head]) do |nodes, datum|
      nodes << mk_node[datum, nodes.last, head]
    end.tap { |line| line.shift }
  end
end
