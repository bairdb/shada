class Collection
  include Enumerable
  
  def initialize hash
    hash.each do |k,v|
      self[k] = v
    end
  end
end
