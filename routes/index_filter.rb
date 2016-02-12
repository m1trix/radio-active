before '/index.html' do
  redirect '/login.html' unless session[:user_id]
  pass
end