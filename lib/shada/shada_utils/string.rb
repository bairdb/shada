class String
  def propercase
    self.split(/\s+/).each{|word|word.capitalize!}.join(' ')
  end
  
  def big_chomp
    self.strip.chomp.gsub(/\n+/m," ").gsub(/\t+/m, " ").gsub(/\s+/m, ' ').gsub(/\r+/m, ' ')
  end
end