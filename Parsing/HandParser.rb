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

class MahjongHandElementType
	INCOMPLETEPON = 0
	PON = 1
	INCOMPLETECHI = 2
	CHI = 3
	CONCEALEDKAN = 4
	KAN = 5
	INCOMPLETEPAIR = 6
	PAIR = 7
	TODISCARD = 8
end

class MahjongHandElement
	attr_reader :pool, :incomplete, :waits, :mode

	def initialize(tiles, mode)
		@pool = Array.new
		@waits = Array.new
		@mode = mode

		case mode
		when MahjongHandElementType::INCOMPLETEPAIR, MahjongHandElementType::INCOMPLETEPON
			@incomplete = TRUE
			@waits.push(MahjongTile.new(tiles[0].to_s))
		when MahjongHandElementType::INCOMPLETECHI
			@incomplete = TRUE
			if(tiles[1] == nil)
				@waits.push(MahjongTile.new((tiles[0].value.to_i + 1).to_s + tiles[0].suit.to_s))
			else
				@waits.push(MahjongTile.new((tiles[0].value.to_i - 1).to_s + tiles[0].suit.to_s)) if tiles[0].value.to_i > 1
				@waits.push(MahjongTile.new((tiles[0].value.to_i + 2).to_s + tiles[0].suit.to_s)) if tiles[0].value.to_i < 8
			end
		end

		tiles.delete(nil)

		tiles.each { |item|
			@pool.push(item)
		}
		#@pool.sort!
	end
end

class MahjongHand
	attr_reader :pool, :shanten, :calls, :readyhands, :readytiles

	def initialize(string, recurse = nil, newelement = nil)
		if(recurse == nil)
			@shanten = -1
			@pool = Array.new
			@calls = Array.new
			@readytiles = Array.new
			@readyhands = Array.new

			string.upcase.scan(/([1-9].|E|S|W|N|H|K|C)/) { |item|
				@pool.push(MahjongTile.new(item))
			}
			self.dosort
		else
			@shanten = recurse.shanten == -1 ? 0 : recurse.shanten

			@pool = Array.new(recurse.pool)
			@calls = Array.new(recurse.calls)
			@readyhands = Array.new
			@readytiles = Array.new

			if(newelement != nil)
				newelement.pool.each { |item|
					@pool.delete_at(@pool.index(item)) unless item == nil
				}
				@calls.push(newelement)
				@shanten = @shanten + 1 if newelement.incomplete == TRUE
			else
				# We're duplicating the hand so we can do complete checking
				@shanten = 1
			end
		end
	end

	def dosort
		@pool.sort!
	end

	def revsort
		@pool.sort! { |a,b| b <=> a }
	end

	def complete
		handtocheck = MahjongHand.new("",self)
		return handtocheck.ready
	end

	def totenpai
		possiblehands = Array.new
		@pool.each { |tile|
			possiblehands.push(MahjongHand.new("",self,MahjongHandElement.new(Array[tile],MahjongHandElementType::TODISCARD)))
		}

		readyhands = Array.new

		possiblehands.each { |item|
			readyhands = readyhands + item.ready
		}
		return readyhands
	end

	def tsumo
		@calls.each { |item|
			readytiles.each { |wait|
				if item.mode == MahjongHandElementType::TODISCARD
					if wait == item.pool[0]
						return true
					end
				end
			}
		}

	end

	def ready
		# This is now designed to work on a 13 or 14 tile hand, based on the Shanten number.

		# First, sort everything
		self.dosort

		# If we have no tiles left, we're done and it's time to heac back up the chain
		if(@pool.length == 0)
			# Add together all the waits
			# return self
			@calls.each { |item|
				@readytiles = @readytiles + item.waits
			}
			readyhands = Array[self]
			return readyhands
		end

		possiblehands = Array.new
		measure = [0,0,0]
		basetile = pool[0]

		# Populate the measure array
		@pool.each { |tile|
			if((tile.suit != basetile.suit) or ((tile.value.to_i - basetile.value.to_i) > 2))
				break
			else
				measure[(tile.value.to_i - basetile.value.to_i)] += 1
			end
		}

		# Count our pairs
		pairs = 0
		@calls.each { |item|
			if(item.mode == MahjongHandElementType::PAIR or item.mode == MahjongHandElementType::INCOMPLETEPAIR)
				pairs = pairs + 1
			end
		}

		if @shanten < 1
			possiblehands.push(MahjongHand.new("",self,MahjongHandElement.new(Array[@pool[0], @pool[1], @pool[2]],MahjongHandElementType::PON))) if measure[0] >= 3
			possiblehands.push(MahjongHand.new("",self,MahjongHandElement.new(Array[@pool[0], @pool[1]],MahjongHandElementType::INCOMPLETEPON))) if measure[0] >= 2
			possiblehands.push(MahjongHand.new("",self,MahjongHandElement.new(Array[@pool[0],@pool[1]],MahjongHandElementType::PAIR))) if (measure[0] >= 2 and (pairs == 0 or pairs == @calls.count))
			if(measure[1] > 0)
				if(measure[2] > 0)
					#123
					possiblehands.push(MahjongHand.new("",self,MahjongHandElement.new(Array[@pool[0], @pool[measure[0]], @pool[measure[0] + measure[1]]],MahjongHandElementType::CHI))) if measure[0] >= 1
				end
				#12-
				possiblehands.push(MahjongHand.new("",self,MahjongHandElement.new(Array[@pool[0], @pool[measure[0]], nil],MahjongHandElementType::INCOMPLETECHI))) if measure[0] >= 1
			end
			if(measure[2] > 0)
				#1-3
				possiblehands.push(MahjongHand.new("",self,MahjongHandElement.new(Array[@pool[0], nil, @pool[measure[0]+measure[1]]],MahjongHandElementType::INCOMPLETECHI))) if measure[0] >= 1
			end
			possiblehands.push(MahjongHand.new("",self,MahjongHandElement.new(Array[@pool[0]],MahjongHandElementType::INCOMPLETEPAIR)))
		else
			possiblehands.push(MahjongHand.new("",self,MahjongHandElement.new(Array[@pool[0], @pool[1], @pool[2]],MahjongHandElementType::PON))) if measure[0] >= 3
			possiblehands.push(MahjongHand.new("",self,MahjongHandElement.new(Array[@pool[0],@pool[1]],MahjongHandElementType::PAIR))) if (measure[0] >= 2 and (pairs == 0 or pairs == @calls.count))
			if((measure[1] > 0) and (measure[2] > 0))
				#123
				possiblehands.push(MahjongHand.new("",self,MahjongHandElement.new(Array[@pool[0], @pool[measure[0]], @pool[measure[0] + measure[1]]],MahjongHandElementType::CHI))) if measure[0] >= 1
			end
		end

		readyhands = Array.new

		possiblehands.each { |item|
			readyhands = readyhands + item.ready
		}
		return readyhands

	end

	def to_s
		retval = ""
		@pool.each { |tile| retval = retval + tile.to_s }
		return retval
	end
end

class ReadyHand < MahjongHand
end

class CompleteHand < MahjongHand
	def initialize(basehand, wait=nil)
	end
end

#tim = MahjongHand.new("EE1m1m1m2m3m4m5p5p5p7o8o9o")
#tim = MahjongHand.new("EEE1m1m2m3m4m5m6m7o8o9oK")
#tim = MahjongHand.new("EE1m1m1m2m2m2m3m3m3m4m4m4m")
tim = MahjongHand.new("EE1m1m1m2o2o2o3p3p3p4m4m4m")
#tim = MahjongHand.new("E1m1m1m2o2o2o3p3p3p4m4m4mK")
output = tim.totenpai
print "----OUTPUT----\n"
output.each { |item|
	print "---------NEW HAND----------\n"
	item.calls.each { |thing|
		print "\tCalled Item - #{thing.pool}\t#{thing.mode}\n"
	}
	print "Waits: ", item.readytiles, "\n"
	print "TSUMO!\n" if item.tsumo == true
}
