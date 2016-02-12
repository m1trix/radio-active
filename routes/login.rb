post '/login' do
  begin
    $access.check(params[:username], params[:password])
    session[:user_id] = params[:username]
    redirect '/index.html'
  rescue Radioactive::AccessError => e
    @title = 'Login'
    erb 'frame.html'.to_sym do
      @message = e.message
      @redirect = '/login.html'
      erb 'fail.html'.to_sym
    end
  end
end