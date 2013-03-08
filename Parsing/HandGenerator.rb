#!/usr/local/bin/ruby


class MahjongTile
	include Comparable
	attr_reader :value, :suit

	def initialize(spec)
		@value = spec.to_s[/[1-9]/]
		if(value == nil)
			@suit = spec.to_s
		else
			@suit = spec.to_s[/M|P|O/]
		end
	end
	def <=>(another_tile)
		order = ["M","O","P","E","S","W","N","H","K","C"]

		if(order.index(@suit) == order.index(another_tile.suit))
			return 0 if @value == nil
			return @value <=> another_tile.value
		else
			return order.index(@suit) <=> order.index(another_tile.suit)
		end
	end
	def to_s
		return (@value.to_s + @suit.to_s) unless @value == nil
		return @suit.to_s
	end
end

class MahjongShuffleWall
	attr_reader :wall
	def initialize
		@current = 0
		@wall = Array.new
		1.upto(9) { |n|
			["M","O","P"].each { |suit| 
				4.times do @wall.push(MahjongTile.new("#{n}#{suit}")) end
			}
			["E","S","W","N","H","K","C"].each { |suit| @wall.push(MahjongTile.new(suit)) } if n < 5
		}
	end

	def drawhand
		@wall.shuffle!
		return @wall.slice(10,13)
	end
end

tim = MahjongShuffleWall.new

5.times {
	print tim.drawhand.sort.join(","), "\n"
}
