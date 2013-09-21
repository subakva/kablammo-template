module Aggressive
  def hunt
    x, y = robot.x, robot.y
    return first_possible_move 'nesw' if x == 0
    return first_possible_move 'eswn' if y == @battle.board.height - 1
    return first_possible_move 'swne' if x == @battle.board.width - 1
    return first_possible_move 'wnes' if y == 0
    first_possible_move 'wsen'
  end

  def fire_at!(enemy, compensate = 0)
    direction = robot.direction_to(enemy).round
    skew = direction - robot.rotation
    distance = robot.distance_to(enemy)
    max_distance = Math.sqrt(board.height * board.height + board.width * board.width)
    compensation = ( 10 - ( (10 - 3) * (distance / max_distance) ) ).round
    compensation *= -1 if rand(0..1) == 0
    skew += compensation if compensate > rand
    fire! skew
  end

  def act_aggressively
    enemy = opponents.first
    return hunt unless enemy
    return rest if my.ammo == 0
    return move_towards! enemy if obscured? enemy
    return fire_at! enemy, 0.75 if can_fire_at? enemy
    return aim_at! enemy unless aiming_at? enemy
    move_towards! enemy
  end
end

module Defensive
  def dance
    first_possible_move %w(n s e w).shuffle
  end

  def dodge(enemy)
    toward = moves_toward enemy
    d1 = enemy.distance_to robot.target_for(toward[1])
    d2 = enemy.distance_to robot.target_for(toward[2])
    if d1 > d2
      moves = [ toward[1], toward[2], toward[3], toward[0] ]
    else
      moves = [ toward[2], toward[1], toward[3], toward[0] ]
    end
    first_possible_move moves
  end

  def act_defensively
    enemy = opponents.first
    return dance unless enemy
    return dodge enemy if enemy.can_fire_at? me
    return rest unless my.ammo_full?
    move_away_from! enemy
  end
end

extend Aggressive
extend Defensive

@current_target = nil

def killrobotkill(robot, target)
  if robot.can_fire_at?(target)
    fire!
  else
    rotate!(robot.direction_to(target).round)
  end
end

on_turn do
  if robot.ammo < 0
    rest
  elsif @current_target && @current_target.alive? && robot.can_see?(@current_target)
    killrobotkill(robot, @current_target)
  else
    @current_target = opponents.first
    if @current_target
      killrobotkill(robot, @current_target)
    elsif robot.ammo_full?
      hunt
    else
      rest
    end
  end
end
