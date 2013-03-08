#!/usr/local/bin/ruby

def mjScore(fan, hu, d, t = false)
	print ((([(hu * (2**(fan + 2))).fdiv(1000),2,3,3,4,4,4,6,6,8].sort[[0,fan - 5,8].sort[1]] * 10).instance_exec(t,d) { |t,d| [ (t ? 2 : d ? 6 : 4) * self, (d ? 2 : 1) * self][0,t ? 2 : 1] } ).map { |i| i.ceil * 100 }).join(" / "), "\n"
	print (Array.new(2,(([(hu * (2**(fan + 2))).fdiv(1000),2,3,3,4,4,4,5,5,8].sort[[0,fan - 5,8].sort[1]] * 10))).fill { |i| ([(t ? 2 : d ? 6 : 4), (d ? 2 : 1)][i] * self[i]).ciel * 100 }).join(" / "), "\n"
end

mjScore(4,80,false,true)
