class LineEnding
    attr_accessor :line_number, :ending

    def initialize(line_number, ending)
        @line_number = line_number
        @ending = ending
    end

    def to_s
        return "#{line_number}::#{ending}"
    end      
end

class Lines
    def self.get_endings(file)
        endings = []
    
        data = IO.binread(file)
        bytes = data.bytes
    
        i = 0
        line_number = 1
    
        loop do
            if i >= bytes.length then
                break
            end
            
            char = bytes[i]
    
            if char == 13 then
                if i < bytes.length then 
                    next_char = bytes[i + 1]
    
                    if next_char == 10 then
                        line_ending = LineEnding.new(line_number, "\r\n")
                        endings.append(line_ending)
    
                        i+= 2
                        line_number+= 1
                        next
                    end
                end
            end
    
            if char == 10 then 
                line_ending = LineEnding.new(line_number, "\n")
                endings.append(line_ending)
                line_number+= 1
            end
            
            i+= 1
          end
    
        return endings
    end
    
    def self.get_ending_type(file)
        endings = get_endings(file)
    
        windows_found = false
        linux_found = false
    
        endings.each do |e|
            if e.ending == "\\r\\n" then
                windows_found = true
                next
            end
    
            if e.ending == "\\r" then
                linux_found = true
            end
        end
    
        if windows_found && linux_found then
            return "MIXED"
        end
        
        if windows_found then
            return "CR LF"
        end
    
        return "LF"
    end 
end
