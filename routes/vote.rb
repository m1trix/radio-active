post '/vote/:video' do
  begin
    if session[:user_id].nil?
      401
      'Login to to vote'
    end

    $radio.vote(session[:user_id], params[:video])
    'Voting was successful!'
  rescue Radioactive::VotingError => e
    status 409
    e.message
  rescue Error => e
    status 500
    'Voting failed! Try again'
  end
end