get '/index.html' do
  @title = '[You]Tube radio'
  erb 'frame.html'.to_sym do
    @player = $radio.player
    erb 'index.html'.to_sym
  end
end