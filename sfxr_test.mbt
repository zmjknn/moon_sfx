///|
test "sfxr_presets_synthesis" {
  let laser = SfxParams::laser(1U).synthesize(22050)
  assert_eq(laser.sample_rate(), 22050)
  assert_true(laser.length() > 0)
  assert_true(laser.duration() > 0.05)

  let jump = SfxParams::jump(2U).synthesize(22050)
  assert_true(jump.length() > 0)

  let explosion = SfxParams::explosion(3U).synthesize(22050)
  assert_true(explosion.length() > 0)

  let coin = SfxParams::coin(4U).synthesize(22050)
  assert_true(coin.length() > 0)

  let hit = SfxParams::hit(5U).synthesize(22050)
  assert_true(hit.length() > 0)

  let powerup = SfxParams::powerup(6U).synthesize(22050)
  assert_true(powerup.length() > 0)

  let blip = SfxParams::blip(7U).synthesize(22050)
  assert_true(blip.length() > 0)

  // Verify all samples stay well within normal range
  for i = 0; i < laser.length(); i = i + 1 {
    assert_true(laser.get(i).abs() <= 2.0)
  }
}

///|
test "sfxr_randomize_and_mutate" {
  let rnd = SfxParams::randomize(42U)
  let buf = rnd.synthesize(22050)
  assert_true(buf.length() > 0)

  let mutated = rnd.mutate(0.2, 88U)
  let buf_mut = mutated.synthesize(22050)
  assert_true(buf_mut.length() > 0)
}
