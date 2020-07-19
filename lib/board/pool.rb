# Copyright (c) 2009 Paolo Capriotti <p.capriotti@gmail.com>
# 
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 2 of the License, or
# (at your option) any later version.

require 'item'
require 'board/redrawable'

class Pool < Qt::GraphicsItemGroup
  BACKGROUND_ZVALUE = -10
  
  include Observable
  include ItemUtils
  include TaggableSquares
  include Redrawable
  
  attr_reader :rect, :scene, :items, :theme
  attr_reader :animator, :unit
  square_tag :premove_src, :premove, :target => :extra
  
  def initialize(scene, theme, game)
    super(nil, scene)
    @scene = scene
    @scene.add_clickable_element(self)
    
    @theme = theme
    @game = game
    
    @items = []
    @extra = ExtraItemContainer.new(self)
    @size = Point.new(3, 5)
    
    @type_values = Hash.new(-1)
    if @game.respond_to? :types
      @game.types.each_with_index do |type, index|
        @type_values[type] = index
      end
    end
    
    @animator = PoolAnimator.new(self)
    @flipped = false
  end
  
  def square_tag_container
    @extra
  end
  
  def flip(value)
    @flipped = value
  end
  
  def flipped?
    @flipped
  end
  
  def redraw
    @items.each_with_index do |item, index|
      item.reload(index)
    end
    
    @extra.redraw
  end

  def set_geometry(rect)
    @rect = rect
    
    self.pos = @rect.top_left.to_f
    
    side = (@rect.width / @size.x).floor
    @unit = Qt::Point.new(side, side)
    redraw
  end
  
  def add_piece(index, piece, opts = {})
    opts = opts.merge :name => piece,
                      :reloader => piece_reloader(piece)
    item = create_item(opts)
    items.insert(index, item)
    item.reload(index) if opts.fetch(:load, true)
    item
  end
  
  def remove_item(index, *args)
    item = items.delete_at(index)
    unless item.nil? or args.include?(:keep)
      destroy_item item
    end
    item
  end
  
  def on_click(pos, data = {})
    
  end
  
  def on_drag(pos)
    index = to_logical(pos)
    item = items[index]
    if item
      fire :drag => { :index => index,
                      :item => item }
    end
  end
  
  def on_drop(old_pos, pos, data)
    if data[:item]
      fire :drop => data
    end
  end
  
  def to_logical(p)
    y = p.y.to_f
    if @flipped
      y = rect.height - y
    end
    result = Point.new((p.x.to_f / @unit.x).floor,
                       (y / @unit.y).floor)
    y = result.y
    x = y % 2 == 0 ? result.x : @size.x - result.x - 1
    x + y * @size.x
  end
  
  def to_real(index)
    x = index % @size.x
    y = index / @size.x
    x = @size.x - x - 1 if y % 2 == 1
    
    rx = x * @unit.x
    ry = if @flipped
      rect.height - (y + 1) * @unit.y
    else
      y * @unit.y
    end
    
    Qt::PointF.new(rx, ry)
  end
  
  def compare(piece1, piece2)
    [piece1.color.to_s, @type_values[piece1.type], piece1.type.to_s] <=>
    [piece2.color.to_s, @type_values[piece2.type], piece2.type.to_s]
  end
  
  class ExtraItemContainer
    include ItemBag
    include ItemUtils
    
    attr_reader :items
    
    def initialize(pool)
      @pool = pool
      @items = { }
    end
    
    def redraw
      @items.each do |key, item|
        item.reload(key)
      end
    end
    
    def item_parent
      @pool
    end
    
    def scene
      @pool.scene
    end
  end
end
