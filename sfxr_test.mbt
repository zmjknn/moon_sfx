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

///|
test "sfxr_frequency_slide_and_delta_slide" {
  let p = SfxParams::default()
  p.start_freq = 800.0
  p.freq_slide = -0.5
  p.freq_delta_slide = -0.05
  p.sustain_time = 0.1
  p.decay_time = 0.1
  let buf = p.synthesize(44100)
  assert_true(buf.length() > 0)
  // Verify audio rendered without NaN or infinity
  for i = 0; i < buf.length(); i = i + 1 {
    assert_true(buf.get(i).abs() <= 1.0)
  }
}

///|
test "sfxr_vibrato_modulation" {
  let p = SfxParams::default()
  p.start_freq = 440.0
  p.vibrato_speed = 12.0
  p.vibrato_depth = 0.25
  p.sustain_time = 0.15
  p.decay_time = 0.1
  let buf = p.synthesize(44100)
  assert_true(buf.length() > 0)
}

///|
test "sfxr_pitch_arpeggio_jump" {
  let p = SfxParams::default()
  p.start_freq = 300.0
  p.change_amount = 1.5 // 50% pitch leap
  p.change_time = 0.05
  p.sustain_time = 0.1
  p.decay_time = 0.1
  let buf = p.synthesize(44100)
  assert_true(buf.length() > 0)
}

///|
test "sfxr_cycle_repeat_speed" {
  let p = SfxParams::default()
  p.start_freq = 400.0
  p.repeat_speed = 0.7 // Periodic stuttering cycle repeat
  p.sustain_time = 0.2
  p.decay_time = 0.2
  let buf = p.synthesize(44100)
  assert_true(buf.length() > 0)
}

///|
test "sfxr_phaser_comb_filter" {
  let p = SfxParams::default()
  p.start_freq = 500.0
  p.phaser_offset = 0.15
  p.phaser_sweep = -0.08
  p.sustain_time = 0.1
  p.decay_time = 0.1
  let buf = p.synthesize(44100)
  assert_true(buf.length() > 0)
}

///|
test "sfxr_dynamic_filter_sweeps" {
  let p = SfxParams::default()
  p.start_freq = 600.0
  p.lpf_cutoff = 1500.0
  p.lpf_sweep = -1000.0 // Dynamic LPF plunge
  p.hpf_cutoff = 50.0
  p.hpf_sweep = 200.0   // Dynamic HPF rise
  p.sustain_time = 0.15
  p.decay_time = 0.15
  let buf = p.synthesize(44100)
  assert_true(buf.length() > 0)
}
