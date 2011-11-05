class String
  def propercase
    self.split(/\s+/).each{|word|word.capitalize!}.join(' ')
  end
end