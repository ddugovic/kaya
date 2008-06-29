require 'games/chess/move'

module Shogi
  class Move < Chess::Move
    attr_reader :dropped
    
    def initialize(src, dst, opts = {})
      super
      @dropped = opts[:dropped]
    end
    
    def self.drop(piece, dst)
      new(nil, dst, :dropped => piece)
    end
  end
end
