post '/logout' do
  session[:user_id] = nil
  redirect '/login.html'
end