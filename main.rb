require 'rubygems'
require 'sinatra'
#require 'pry'

set :sessions, true

helpers do
  def calculate_total(cards) 
    arr = cards.map{|x| x[1]}

    total = 0
    arr.each do |a|
      if a == "A"
        total += 11
      else
        total += a.to_i == 0 ? 10 : a.to_i
      end
    end

    arr.select{|element| element == "A"}.count.times do
      break if total <= 21
      total -= 10
    end

    total
  end

  def card_image(jpg)

    card_name = { "J" => 'jack', "Q" => 'queen', "K" => 'king', "A" => 'ace'}
    if jpg[1].to_i != 0
      return "<img src='/images/cards/#{jpg[0]}_#{jpg[1]}.jpg' height='160' width = '112'>"
    else
      return "<img src='/images/cards/#{jpg[0]}_#{card_name[jpg[1]]}.jpg' height='160' width = '112'>"
    end 
  end

  def winner!
    @win = "#{session[:player_name]}, you won $#{session[:player_wager]}!"
    session[:player_purse] += session[:player_wager].to_i
    
  end
  def loser!
    @error = "Ouch #{session[:player_name]}, you lost $#{session[:player_wager]}."
    session[:player_purse] -= session[:player_wager].to_i
       if session[:player_purse] < 1 
          @error = "You're broke... hit the bricks." 
       end   

    
  end
end

before do
  @show_hit_or_stay_buttons = true
  @show_dealer_button = false

end

get '/' do
  if session[:player_name]
    redirect '/game'
  else
    redirect '/new_player'
  end
end

get '/new_player' do
  session[:player_purse] = 1000
  session[:player_wager] = 0
  erb :new_player
end

post '/new_player' do
   if params[:player_name].empty?
    @error = "Your name please, this is a high roller table only!"
    halt erb :new_player
   elsif params[:player_name] =~ /[^a-zA-Z]/
    @error = "Name must not contain invalid characters"
    halt erb :new_player
   end  
  session[:player_name] = params[:player_name]
  redirect '/player_wager'
end

get '/player_wager' do
  erb :player_wager
end

post '/player_wager' do  
  #if over 10,000
  #if not integer
  session[:player_wager] = params[:player_wager].to_i
  

  redirect '/game'
end


get '/game' do
  # create a deck and put it in session
  suits = ['hearts', 'diamonds', 'clubs', 'spades']
  values = ['2', '3', '4', '5', '6', '7', '8', '9', '10', 'J', 'Q', 'K', 'A']
  session[:deck] = suits.product(values).shuffle! 

  # deal cards
  session[:dealer_cards] = []
  session[:player_cards] = []
  session[:dealer_first_card] = []
  session[:dealer_first_card] << session[:deck].pop
  session[:player_cards] << session[:deck].pop
  session[:dealer_cards] << session[:deck].pop
  session[:player_cards] << session[:deck].pop
      
  if calculate_total(session[:player_cards]) == 21
      winner!
      @show_hit_or_stay_buttons = false
      end
  @hide_dealer_card = true

  erb :game
end

post '/game/player/hitme' do
  session[:player_cards] << session[:deck].pop
   if calculate_total(session[:player_cards]) > 21
    loser!
    @show_hit_or_stay_buttons = false
   elsif calculate_total(session[:player_cards]) == 21
    winner!
    @show_hit_or_stay_buttons = false
   end
   @hide_dealer_card = true
 erb :game
end

post '/game/player/istay' do  
  @show_hit_or_stay_buttons = false
  session[:dealer_cards] += session[:dealer_first_card]
  @hide_dealer_card = false
  redirect '/game/dealer'
end

get '/game/dealer' do
  @show_hit_or_stay_buttons = false
  dealer_total = calculate_total(session[:dealer_cards])

  if dealer_total == 21 
    loser!
  elsif dealer_total > 21
    winner!
  elsif dealer_total > 16
   redirect '/game/showhand'
  else 
    @show_dealer_button = true
  end

  erb :game
end 

get '/game/dealer/hit' do
  session[:dealer_cards] << session[:deck].pop  
  redirect '/game/dealer'
end

get '/game/showhand' do
   @show_hit_or_stay_buttons = false
   dealer_total = calculate_total(session[:dealer_cards])
   player_total = calculate_total(session[:player_cards])

   if dealer_total > player_total
    loser!
    #session[:player_purse] -= session[:player_wager].to_i
   elsif dealer_total < player_total
    winner!
   else dealer_total = player_total
    @win = "Its a tie"
   end
  
  erb :game 
end

post '/game/dealer_next_button' do
       redirect '/game/dealer/hit'
end