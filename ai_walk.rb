# マス目をすすむAI

# https://qiita.com/sugulu_Ogawa.../items/7a14117bbd3d926eb1f2

system("powershell -command \"[console]::CursorVisible = \$false\"") # 見ずらいのでテキストカーソルを非表示
def clean
  puts "\e[0m\e[H\e[2J", ""
end

def to_bin(clip_min, clip_max, n)
  bins = []
  difference = (clip_max - clip_min) / (n - 1).to_f
  for i in 0..n - 1
    bins.push(difference * i)
  end
  return bins[1..-2]
end

def digitize(val, bins)
  return bins.find_index { |b| val < b } || bins.size
end

def digitize_state(observation)
  mx, my, goal_x, goal_y, angle = observation
  digitized = [
    digitize(mx, to_bin(0.0, 11.0, $num_dizitized)), 
    digitize(my, to_bin(0.0, 11.0, $num_dizitized)), 
    digitize(goal_x, to_bin(0.0, 11.0, $num_dizitized)), 
    digitize(goal_y, to_bin(0.0, 11.0, $num_dizitized)), 
    digitize(angle, to_bin(0.0, 4.0, $num_dizitized))
  ]
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
    next_action = rand(0..2)
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

state = []
reward = 0
$num_dizitized = 10

num_episodes = 1000011
action = 0
max_number_of_steps = 200
q_table = []
for i in 1..$num_dizitized ** 5
  q_table.push([])
  for j in 1..3
    q_table[-1].push(rand(-1.0..1.0))
  end
end
angle = 1
$mx = 0
$my = 0
goal_x = 5
goal_y = 10

$mx = 0
$my = 0

def screen(goal_x, goal_y, angle, episode, episode_reward)
  clean
  puts("試行回数: #{episode + 1}, 報酬#{episode_reward}\n")

  for y in 0..10
    putter = ""
    for x in 0..10
      if x == $mx and y == $my
        case angle
        when 1
          putter += ">"
        when 2
          putter += "^"
        when 3
          putter += "<"
        when 4
          putter += "v"
        end
      elsif x == goal_x and y == goal_y
        putter += "+"
      else
        putter += " "
      end
    end
    puts putter
  end
  sleep(0.05)
end

for episode in 0..num_episodes - 1
  angle = 1
  observation = [$mx, $my, goal_x, goal_y, angle]
  state = digitize_state(observation)
  action = (q_table[state]).each_with_index.max[1]
  next_state = state
  next_action = action
  episode_reward = 0
  goal_x = rand(1..9)
  goal_y = rand(1..9)
  
  for t in 0..max_number_of_steps - 1
    next_break = nil
    reward = 0
    # action
    # 0 turn right
    # 1 turn left
    # 2 straight

    if action == 2
      ago_mx, ago_my = $mx, $my
      case angle
      when 1
        if $mx < 10
          $mx += 1
        else
          reward -= 10
        end
      when 2
        if $my > 0
          $my -= 1
        else
          reward -= 10
        end
      when 3
        if $mx > 0
          $mx -= 1
        else
          reward -= 10
        end
      when 4
        if $my < 10
          $my += 1
        else
          reward -= 10
        end
      end

      if ($mx - ago_mx) * ($mx - goal_x) < 0 or ($my - ago_my) * ($my - goal_y) < 0
        reward = 1
      else
        reward = -2
      end
    else
      if action == 0
        angle += 1
      else
        angle -= 1
      end

      if angle < 1
        angle = 4
      end
      if angle > 4
        angle = 1
      end
      reward = -3
    end
    
    if $mx == goal_x and $my == goal_y
      reward = 10
      next_break = true
    end
    
    if [0, 1, 500, 501, 1000, 1001, 2000, 2001, 5000, 5001, 8000, 8001, 10000, 10001, 10002, 10003, 30000, 50000, 70000].include?(episode) or episode >= 10000
      screen(goal_x, goal_y, angle, episode, episode_reward)
    # elsif episode % 1000 == 0
    #   puts("試行回数: #{episode}")
    elsif [2, 200, 400, 502, 700, 900, 1002, 1500, 2002, 3000, 4000, 5002, 6000, 7000, 8003, 10004, 20000, 30000, 40000, 50000, 70000, 90000].include?(episode)
      clean
      puts "試行中... 試行回数: #{episode + 1}"
    elsif episode == 100004
      clean
      puts "実験終了"
      break
    end

    
    observation = [$mx, $my, goal_x, goal_y, angle]
    episode_reward += reward

    state = next_state
    action = next_action

    next_state = digitize_state(observation)
    next_action = get_action(next_state, episode, q_table)
    q_table = update_Qtables_sarsa(q_table, state, action, reward, next_state, next_action)
    
    action = next_action
    
    if next_break
      break
    end
  end
end

