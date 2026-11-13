///|
test "play_all_presets_wav" {
  let laser = play_laser_wav(1U)
  assert_true(laser.length() > 44)

  let jump = play_jump_wav(2U)
  assert_true(jump.length() > 44)

  let coin = play_coin_wav(3U)
  assert_true(coin.length() > 44)

  let explosion = play_explosion_wav(4U)
  assert_true(explosion.length() > 44)

  let hit = play_hit_wav(5U)
  assert_true(hit.length() > 44)

  let powerup = play_powerup_wav(6U)
  assert_true(powerup.length() > 44)

  let blip = play_blip_wav(7U)
  assert_true(blip.length() > 44)

  let burst = play_burst_wav(8U)
  assert_true(burst.length() > 44)
}

///|
test "html_playground_generation" {
  let html = generate_html_playground()
  assert_true(html.contains("<!DOCTYPE html>"))
  assert_true(html.contains("moon_sfx"))
  assert_true(html.contains("data:audio/wav;base64,"))
  assert_true(html.contains("Victory Fanfare"))
}
