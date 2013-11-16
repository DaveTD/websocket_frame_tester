require "websocket"

data = "hello"
frame = WebSocket::Frame::Outgoing::Server.new(:version => 13, :data => data, :type => :text)
p frame.to_s

data = [145, 133, 67, 114]
packed = data.pack("cccc")
frame = WebSocket::Frame::Outgoing::Server.new(:version => 13, :data => packed, :type => :binary)
p frame.to_s

