# マス目をすすむAI

# https://qiita.com/sugulu_Ogawa.../items/7a14117bbd3d926eb1f2

effect = true


system("powershell -command \"[console]::CursorVisible = \$false\"") # 見ずらいのでテキストカーソルを非表示
def clean
  puts "\e[0m\e[H\e[2J", ""
end

def to_bin(clip_min, clip_max, n) # 離散用
  bins = []
  difference = (clip_max - clip_min) / (n - 1).to_f
  for i in 0..n - 1
    bins.push(difference * i)
  end
  return bins[1..-2]
end

def digitize(val, bins) # 離散化
  return bins.find_index { |b| val < b } || bins.size
end

def digitize_state(observation) # 状態を離散化して数値にする
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

def get_action(next_state, episode, q_table) # 現在の状態から行動を求める
  epsilon = 0.5 * (1 / (episode + 1))
  next_action = nil
  if epsilon <= rand(0.0..1.0)
    next_action = q_table[next_state].each_with_index.max[1]
  else
    next_action = rand(0..2)
  end
  return next_action
end

def update_Qtables_sarsa(q_table, state, action, reward, next_state, next_action) # Qtableを更新する
  gamma = 0.99
  alpha = 0.5
  q_table[state][action] = (1 - alpha) * q_table[state][action] +\
    alpha * (reward + gamma * q_table[next_state][next_action])

  return q_table
end

state = 0 # 状態(離散後)
reward = 0 # 報酬
$num_dizitized = 11 # 状態を11分割

num_episodes = 1000000 # 何回学習するか
action = 0 # 行動
max_number_of_steps = 200 # 1回の学習で何回ループするか
q_table = [] # Qtable(データ)生成
for i in 1..$num_dizitized ** 5
  q_table.push([])
  for j in 1..3
    q_table[-1].push(rand(-1.0..1.0))
  end
end
angle = 1 # AIの向き
$mx = 0 # AIの場所(x)
$my = 0 # AIの場所(y)

def screen(goal_x, goal_y, angle, episode, episode_reward, moves, effect) # 表示するだけ
  clean
  puts("試行回数: #{episode + 1}, 報酬#{episode_reward}\n")

  for y in 0..10
    putter = ""

    moves_yoko = nil
    if effect
      if moves.length >= 2
        moves_yoko = moves[0].zip(*moves[1..moves.length])
      else
        moves_yoko = moves[0].zip
      end
    end

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
      elsif effect and moves_yoko[0].zip(moves_yoko[1]).include?([x, y])
        if [1, 3].include?(moves_yoko[2][moves_yoko[0].zip(moves_yoko[1]).find_index([x, y])])
          putter += "-"
        else
          putter += "|"
        end
      else
        putter += " "
      end
    end
    puts putter
  end
  sleep(0.05)
end

moves = []
for episode in 0..num_episodes - 1 # 学習メインループ
  goal_x = rand(1..9) # ゴールの場所(x)
  goal_y = rand(1..9) # ゴールの場所(y)
  observation = [$mx, $my, goal_x, goal_y, angle] # 状態
  state = digitize_state(observation) # 現在の状態を離散化して1つの数値にする
  action = (q_table[state]).each_with_index.max[1] # 今までのQtableデータから、現在の状態の最適な行動を導き出す
  next_state = state # 状態の数値を次回に引き継ぐ
  next_action = action # 行動を次回に引き継ぐ
  episode_reward = 0 # 学習ごとに報酬を記録しておく(不必要)
  
  for t in 0..max_number_of_steps - 1 # 1学習ループ
    next_break = nil # 次回終了するか
    reward = 0 # 報酬をリセット
    # 行動
    # 0 右回転
    # 1 左回転
    # 2 前進
    moves.unshift([$mx, $my, angle]) # 行動の記録(effect用)
    moves = moves[0..10] # 行動は10個程度しか記録しない

    if action == 2 # 前進
      ago_mx, ago_my = $mx, $my
      case angle # 今の向きによって前進する方向が違う
      when 1
        if $mx < 10
          $mx += 1
        end
      when 2
        if $my > 0
          $my -= 1
        end
      when 3
        if $mx > 0
          $mx -= 1
        end
      when 4
        if $my < 10
          $my += 1
        end
      end

      if ($mx - ago_mx) * ($mx - goal_x) < 0 or ($my - ago_my) * ($my - goal_y) < 0
        reward = 2 # ゴールに近づけば報酬
      else
        reward = -2 # 遠ざかれば罰
      end
    else # 回転
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
      screen(goal_x, goal_y, angle, episode, episode_reward, moves, effect)
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

    
    observation = [$mx, $my, goal_x, goal_y, angle] # 状態
    episode_reward += reward # 報酬の記録(不必要)

    state = next_state # 状態の数値を次回に引き継ぐ
    action = next_action # 行動を次回に引き継ぐ

    next_state = digitize_state(observation) # 現在の状態を離散化して1つの数値にする
    next_action = get_action(next_state, episode, q_table) # 今までのQtableデータから、現在の状態の最適な行動を導き出す
    q_table = update_Qtables_sarsa(q_table, state, action, reward, next_state, next_action) # Qtableデータを更新する
    
        next_state = digitize_state(observation)
    next_action = get_action(next_state, episode, q_table)
    q_table = update_Qtables_sarsa(q_table, state, action, reward, next_state, next_action)
    
    action = next_action
    if next_break # 終了するなら今学習を終了して次の学習を始める
      break
    end
  end
end

