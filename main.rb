require 'rubygems'
require 'sinatra'
require 'pry'


set :sessions, true

BLACKJACK_AMOUNT = 21
DEALER_CHOICE = 17
INITIAL_POT = 500

helpers do
  def calculate_total(cards) 
      arr = cards.map{|element| element[1]}

    total = 0
    arr.each do |a|
      if a == "A"
        total += 11
      else
        total += a.to_i == 0 ? 10 : a.to_i
      end
    end

    
    arr.select{|element| element == "A"}.count.times do
      break if total <= BLACKJACK_AMOUNT
      total -= 10
    end

    total
  end


def display_card(card)
  suit = case card[0]
    when 'H' then 'hearts'
    when 'D' then 'diamonds'
    when 'C' then 'clubs'
    when 'S' then 'spades'
  end

  value = card[1]
  if ['J', 'Q', 'K', 'A'].include?(value)
    value = case card[1]
      when 'J' then 'jack'
      when 'Q' then 'queen'
      when 'K' then 'king'
      when 'A' then 'ace'
    end
  end

    "<img src='/images/cards/#{suit}_#{value}.jpg' class='card_image'>"
  end

  def winner!(msg)
    @play_again = true
    @show_buttons = false
    session[:player_loot] = session[:player_loot] + session[:player_bet]
    @winner = "<strong>#{session[:player_name]} wins!</strong> #{msg}"
    session[:turn]= "dealer"
  end

  def loser!(msg)
    @play_again = true
    @show_buttons = false
    session[:player_loot] = session[:player_loot] - session[:player_bet]
    @loser ="<strong>#{session[:player_name]} loses.</strong> #{msg}"
    session[:turn]= "dealer"

  end

  def push!(msg)
    @play_again = true
    @show_buttons = false
   @winner = "<strong>It's a push.</strong> #{msg}"
   session[:turn]= "dealer"
  end
end

before do
  @show_buttons = true

end

get '/' do
  if session[:player_name]
    redirect '/game'
  else
   redirect '/set_name'
  end
end

get '/set_name' do
  session[:player_loot] = INITIAL_POT
  erb :set_name
end

post '/set_name' do
  if params[:player_name].empty?
    @error = "Name is required."
    halt erb(:set_name)
  end

  session[:player_name]=params[:player_name]
  redirect '/bet'
end

get '/bet' do
  session[:player_bet] = nil
 erb :bet
end

post '/bet' do
  if params[:bet_amount].nil? || params[:bet_amount].to_i == 0
    @error = "Must make a bet."
    halt erb(:bet)
  elsif  params[:bet_amount].to_i > session[:player_loot]
    @error = "Insufficient funds to make that bet."
    halt erb(:bet)
  else
    session[:player_bet] = params[:bet_amount].to_i
    redirect '/game'
  end      
end

get '/game'  do
  session[:turn] = session[:player_name]


suits = ['H', 'D', 'S', 'C']
values = ['2', '3', '4', '5', '6', '7', '8', '9', '10', 'J', 'Q', 'K', 'A']
session[:deck]=suits.product(values).shuffle!

session[:dealer_cards]=[]
session[:player_cards]=[]
session[:player_cards] << session[:deck].pop
session[:dealer_cards] << session[:deck].pop
session[:player_cards] << session[:deck].pop
session[:dealer_cards] << session[:deck].pop


player_total = calculate_total(session[:player_cards])
dealer_total = calculate_total(session[:dealer_cards])

if player_total == BLACKJACK_AMOUNT
    winner!("#{session[:player_name]} got Blackjack.") 

elsif dealer_total == BLACKJACK_AMOUNT
    loser!("Dealer hit blackjack.")

elsif player_total && dealer_total == BLACKJACK_AMOUNT
  push!("#{session[:player_name]} and the dealer have #{player_total}.")
end

  erb :game
end

post '/game/player/hit' do
  session[:player_cards] << session[:deck].pop

  player_total = calculate_total(session[:player_cards])
  if player_total > BLACKJACK_AMOUNT
     loser!("#{session[:player_name]} busted at #{player_total}.")    
  end

  erb :game, layout: false
end

post '/game/player/stay' do
  @success = "#{session[:player_name]} has decided to stay."
  @show_buttons = false
 redirect '/game/dealer'
end

get '/game/dealer' do
  session[:turn]= "dealer"
  @show_buttons = false

  dealer_total = calculate_total(session[:dealer_cards])
  
  if dealer_total > BLACKJACK_AMOUNT
    winner!("Dealer busted at #{dealer_total}." )
  elsif dealer_total >= DEALER_CHOICE
    redirect '/game/compare'
  else
    @show_dealer_hit = true
  end
  erb :game, layout: false
end

post '/game/dealer/hit' do
  session[:dealer_cards] << session[:deck].pop
  redirect '/game/dealer'

end

get '/game/compare' do
   @show_buttons = false
  player_total = calculate_total(session[:player_cards])
  dealer_total = calculate_total(session[:dealer_cards])

  if player_total < dealer_total    
    loser!("#{session[:player_name]} has #{player_total} and the dealer has #{dealer_total}.")
  elsif  player_total > dealer_total
    winner!("#{session[:player_name]} has #{player_total} and the dealer has #{dealer_total}.")
  else
    push!("Both #{session[:player_name]} and the dealer have #{player_total}.")
    end

  erb :game, layout: false

end

get '/game_over' do
 erb :game_over
end







    
    

