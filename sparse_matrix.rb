class SparseMatrix
  class Node < Struct.new(:datum,
                          :up, :down,
                          :left, :right,
                          :row, :col)
    def self.header
      head = new
      head.left = head.right =
        head.up = head.down =
        head.row = head.col
      head
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

    def remove
      left.right = right
      right.left = left
      up.down = down
      down.up = up
    end

    def insert
      left.right = right.left =
        up.down = down.up = self
    end
  end

  def initialize(rows, cols, &assoc)
    @head = Node.header
    @rows = build_line(rows, @head, &Node.method(:empty_row))
    @cols = build_line(cols, @head, &Node.method(:empty_col))

    @rows.each do |row|
      @cols.each do |col|
        if assoc[row.datum, col.datum]
          up = col.up; left = row.left
          node = Node.entry(up, col, left, row, row, col)
          col.up = row.left =
            up.down = left.right = node
        end
      end
    end
  end

  def inspect
    @rows.map do |sentinel|
      row_reps = []
      r = sentinel
      loop do
        r = r.right
        break if r == sentinel
        row_reps << r.col.datum
      end

      "#{sentinel.datum}: " << row_reps.join(", ")
    end.join("\n")
  end

  private
  def build_line(data, head, &mk_node)
    data.reduce([head]) do |nodes, datum|
      nodes << mk_node[datum, nodes.last, head]
    end.tap { |line| line.shift }
  end
end
