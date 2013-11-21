require 'rubygems'
require 'sinatra'

set :sessions, true

BLACKJACK_AMOUNT = 21
DEALER_MUST_STAY = 17
TOTAL_START_BANK = 500

helpers do
	def calculate_total(card)
		face_values = card.map{|x| x[0] }
		total = 0
    face_values.each do |val|
      if val == "A"
        total += 11
      else
        total += (val.to_i == 0 ? 10 : val.to_i)
      end
    end

    face_values.select{|val| val == "A"}.count.times do
      break if total <= BLACKJACK_AMOUNT
      total -= 10
    end
    total		
	end

  def card_image(card)
    suit = case card[1]
      when 'H' then 'hearts'
      when 'D' then 'diamonds'
      when 'S' then 'spades'
      when 'C' then 'clubs'
    end

    value = card[0]
    if ['J', 'Q', 'K', 'A'].include?(value)
      value = case card[0]
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
    @show_hit_or_stay_buttons = false
    @winner = "<strong>#{session[:player_name]} wins $#{session[:bet]}!</strong> #{msg}"
    session[:player_bank] += session[:bet].to_i
  end

  def loser!(msg)
    @play_again = true
    @show_hit_or_stay_buttons = false
    @loser = "<strong>#{session[:player_name]} loses $#{session[:bet]}. </strong> #{msg}"
    session[:player_bank] -= session[:bet].to_i
  end

  def tie!(msg)
    @play_again = true
    @show_hit_or_stay_buttons = false
    @winner = "<strong>Its a tie!</strong> #{msg}"
  end
end

before do
 @show_hit_or_stay_buttons = true
  @show_dealer_hit_button = false
  @play_again = false
end

get '/' do
	if session[:player_name]
    redirect '/bet'
  else
    redirect '/new_player'
  end
end

get '/new_player' do
  erb :new_player
end

post '/new_player' do
  if params[:player_name].empty?
    @error = "Name is required"
    halt erb(:new_player)
  end
  session[:player_name] = params[:player_name]
  session[:player_bank] = TOTAL_START_BANK
  redirect '/bet'
end

get '/bet' do
  erb :bet
end

post '/bet' do
  if params[:bet].empty? || params[:bet].to_i == 0
    @error = "Bet is required."
    halt erb(:bet)
  elsif params[:bet].to_i > session[:player_bank]
    @error = "Sorry, you do not have that much."
    halt erb(:bet)
  else
    session[:bet] = params[:bet].to_i
    redirect '/game'
  end
end

get '/game' do
  session[:turn] = session[:player_name]

	values = ['2', '3', '4', '5', '6', '7', '8', '9', '10', 'J', 'Q', 'K', 'A']
	suits  = ['H', 'D', 'C', 'S']
	session[:deck] = values.product(suits).shuffle!

	session[:player_cards] = []
  session[:dealer_cards] = []
	session[:player_cards] << session[:deck].pop
  session[:dealer_cards] << session[:deck].pop
	session[:player_cards] << session[:deck].pop
  session[:dealer_cards] << session[:deck].pop 

  player_total = calculate_total(session[:player_cards])
  dealer_total = calculate_total(session[:dealer_cards])

  if player_total == BLACKJACK_AMOUNT && dealer_total != BLACKJACK_AMOUNT
    winner!("#{session[:player_name]} hit blackjack!")
  elsif dealer_total == BLACKJACK_AMOUNT && player_total != BLACKJACK_AMOUNT
    redirect '/game/dealer'
  end


	erb :game
end

post '/game/player/hit' do
  session[:player_cards] << session[:deck].pop

  player_total = calculate_total(session[:player_cards])
  if player_total == BLACKJACK_AMOUNT
    winner!("#{session[:player_name]} hit blackjack!")
  elsif player_total > BLACKJACK_AMOUNT
    loser!("#{session[:player_name]} busted with #{player_total}.")
  end
  erb :game#, layout: false
end

post '/game/player/double_down' do
  session[:player_cards] << session[:deck].pop
  session[:bet] += session[:bet]

  player_total = calculate_total(session[:player_cards])
  if player_total == BLACKJACK_AMOUNT
    winner!("#{session[:player_name]} hit blackjack!")
  elsif player_total > BLACKJACK_AMOUNT
    loser!("#{session[:player_name]} busted with #{player_total}.")
  end
  redirect '/game/dealer'
  erb :game#, layout: false
end

post '/game/player/stay' do
  @success = "#{session[:player_name]} has chosen to stay."
  @show_hit_or_stay_buttons = false 
  redirect '/game/dealer'
end

get '/game/dealer' do
  session[:turn] = "dealer"

  dealer_total = calculate_total(session[:dealer_cards])

  if dealer_total == BLACKJACK_AMOUNT
    loser!("Dealer hit blackjack.")
  elsif dealer_total > BLACKJACK_AMOUNT
    winner!("Dealer busted with #{dealer_total}.")
  elsif dealer_total >= DEALER_MUST_STAY
    redirect '/game/compare'
  else
    @show_dealer_hit_button = true 
    @show_hit_or_stay_buttons = false 
  end
  erb :game#, layout: false
end

post '/game/dealer/hit' do
  session[:dealer_cards] << session[:deck].pop
  redirect '/game/dealer'
end

get '/game/compare' do
  @show_hit_or_stay_buttons = false
  player_total = calculate_total(session[:player_cards])
  dealer_total = calculate_total(session[:dealer_cards])

  if player_total < dealer_total
    loser!("#{session[:player_name]} stayed at #{player_total} and dealer stayed at #{dealer_total}")
  elsif player_total > dealer_total
    winner!("#{session[:player_name]} stayed at #{player_total} and dealer stayed at #{dealer_total}")
  else
    tie!("Both #{session[:player_name]} and dealer stay at #{player_total}")
  end

  erb :game#, layout: false
end

get '/game_over' do
  erb :game_over
end
