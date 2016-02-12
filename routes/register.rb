post '/register' do
  begin
    $access.register(params[:username], params[:password])
    redirect '/login.html'
  rescue Radioactive::AccessError => e
    @title = 'Registration'
    erb 'frame.html'.to_sym do
      @message = e.message
      @redirect = '/register.html'
      erb 'fail.html'.to_sym
    end
  end
end
