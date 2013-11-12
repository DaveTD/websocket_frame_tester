require 'sinatra'
require 'websocket'

get '/test' do
  @options = [0,1,2,3,4,5,6,7,8,9,10,11,12,13,75,76]

  @handshake = params[:handshake].to_i
  @type = params[:binary]=="on"? "checked" : ""
  @binary = params[:binary]=="on"? "binary" : "text"
  @binary_symbol = @binary.to_sym
  @data = params[:data]
  @original_data = params[:data]
  @mask = params[:mask]
  @quoted_mask = "\"#{@mask}\""

  if @binary == "binary"
    array_convert
    # @data = @data.pack(@quoted_mask)
    p @data
  end

  @frame = WebSocket::Frame::Outgoing::Server.new(:version => @handshake, :data => @data, :type => @binary_symbol)
  p @frame.to_s
  erb :test 
end

def array_convert
  p "Converting data to array..."
  @data = @data.split(',')
  smart_pack
end

def smart_pack
  array_position = 0
  last_action = ''
  starred = false
  @mask.each_char do |character|
    case character
    # These should only be called on integer ruby types - convert all the things
    when 'C', 'S', 'L', 'Q', 'c', 's', 'l', 'q', 'i', 'N', 'n', 'v', 'V', 'U', 'w'
      @data[array_position] = @data[array_position].to_i
      last_action = 'i'

    # These should only be called on floating point ruby types - convert all the things
    when 'D', 'd', 'F', 'f', 'E', 'e', 'G', 'g'
      @data[array_position] = @data[array_position].to_f
      last_action = 'f'

    # These should only be called on string ruby types - convert all the things
    when 'A', 'a', 'Z', 'B', 'b', 'H', 'h', 'u', 'M', 'm', 'P', 'p'
      @data[array_position] = @data[array_position].to_str
      last_action = 's'

    # These are valid, but aren't indicators of ruby type, move back the array position and move on...  
    when '_', '!', '>', '<'
      array_position = array_position - 1

    # do this to all the remaining elements in the array... check back for the last character, do that to the rest, break
    # because we're working along 
    when '*'
      starred = true
    end

    if starred 
      complete_pack(array_position, last_action)
      p "Breaking after #{array_position} in the array"
      break
    end

    array_position = array_position + 1
  end
  @data = @data.pack(@quoted_mask)
end

def complete_pack(array_position, action)
  # For the rest of the data, from array_position until the length of the array...
  until array_position >= @data.length
    case action
    when 'i'
      @data[array_position] = @data[array_position].to_i
    when 's'
      @data[array_position] = @data[array_position].to_str
    when 'f'
      @data[array_position] = @data[array_position].to_f
    end
    array_position = array_position + 1
  end
end
