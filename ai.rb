# じゃんけんの手予測AI

# https://qiita.com/sugulu_Ogawa.../items/7a14117bbd3d926eb1f2

state = []
reward = 0
$num_dizitized = 6

def to_bin(clip_min, clip_max, n)
  bins = []
  difference = (clip_max - clip_min) / (n - 1).to_f
  for i in 0..n - 1
    bins.push(difference * i)
  end
  return bins[1..6]
end

def digitize(values, bins)
  return values.map do |val|
    bins.find_index { |b| val < b } || bins.size
  end
end

def digitize_state(observation)
  digitized = digitize(observation, to_bin(-3.0, 3.0, $num_dizitized))
  ns = []
  digitized.each_with_index do |x, i|
    ns.push(x * ($num_dizitized ** i))
  end
  return ns.sum
end

def get_action(next_state, episode, q_table)
  epsilon = 0.5 * (1 / (episode + 1))
  next_action = nil
  if epsilon <= rand(0.0..1.0)
    next_action = q_table[next_state].each_with_index.max[1]
  else
    next_action = rand(0..1)
  end
  return next_action
end

def update_Qtables_sarsa(q_table, state, action, reward, next_state, next_action)
  gamma = 0.99
  alpha = 0.5
  q_table[state][action] = (1 - alpha) * q_table[state][action] +\
    alpha * (reward + gamma * q_table[next_state][next_action])

  return q_table
end

num_episodes = 30
action = 2
max_number_of_steps = 10
$num_dizitized = 6
q_table = []

for i in 1..$num_dizitized ** 6
  q_table.push([])
  for j in 1..3
    q_table[-1].push(rand(-1.0..1.0))
  end
end

observation = []
for i in 1..6
  observation.push(rand(0..2))
end
for episode in 0..num_episodes - 1
  state = digitize_state(observation)
  action = (q_table[state]).each_with_index.max[1]
  episode_reward = 0
  you_hand = 0

  for t in 0..max_number_of_steps - 1
    reward = 0
    if action == you_hand
      reward = 100
    else
      reward = -100
    end
    episode_reward += reward

    next_state = digitize_state(observation)
    next_action = get_action(next_state, episode, q_table)
    q_table = update_Qtables_sarsa(q_table, state, action, reward, next_state, next_action)
    action = next_action
    state = next_state

    puts
    puts " " * ("-------------------".length + 2) + "AIの手"
    puts " " * ("-------------------".length + 2) + "-------------------"
    print(" " * ("-------------------".length + 2))

    if action == 0
      # puts "チョキ"
    elsif action == 1
      # puts "グー"
    elsif action == 2
      # puts "パー"
    else
      puts "Error"
    end
    puts "(AIの手は見えませんが、あなたの手をよそくして手を出しています)"
    
    one_more = true
    you_hand = nil
    while one_more
      one_more = false
      puts "あなたの手"
      puts "-------------------"
      you_hand = gets.chomp
      if you_hand == "パー" or you_hand == "0"
        you_hand = 0
      elsif you_hand == "チョキ" or you_hand == "1"
        you_hand = 1
      elsif you_hand == "グー" or you_hand == "2"
        you_hand = 2
      else
        one_more = true
      end
      # if t % 3 == 0
      #   you_hand = 1
      #   puts "チョキ"
      # elsif t % 3 == 1
      #   you_hand = 2
      #   puts "グー"
      # else
      #   you_hand = 0
      #   puts "パー"
      # end
    end
    observation.push(you_hand)
    observation = observation[1..-1]
    
    puts 
    if action == you_hand
      puts "AIの勝ち!!"
    elsif you_hand - 1 == action or you_hand + 2 == action
      puts "引き分け"
    else
      puts "あなたの勝ち"
    end
    puts
  end
end

