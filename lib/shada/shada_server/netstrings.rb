module Shada
  class NetString
    def parse ns
      #puts ns
      len, rest = ns.to_s.split(":",2)
      len = len.to_i

      [ rest[0...len], rest[(len+1)..-1] ]
    end
  end
end