test "mixer_multi_track_and_pan" {
  let mixer = Mixer::new(44100)
  let sfx_laser = play_laser_wav(1U)
  assert_true(sfx_laser.length() > 0)

  // Track 1: Tone at 0.0s, panned left (-0.8)
  let tone1 = render_tone(Sine, 440.0, 0.2, 44100, 0.7)
  mixer.add_track(tone1, 0.0, 0.8, -0.8)

  // Track 2: Tone at 0.1s, panned right (0.8)
  let tone2 = render_tone(Square(0.5), 880.0, 0.2, 44100, 0.7)
  mixer.add_track(tone2, 0.1, 0.8, 0.8)

  // Expected duration = 0.1 + 0.2 = 0.3s
  assert_true((mixer.duration() - 0.3).abs() < 0.01)

  // Render stereo
  let stereo = mixer.render_stereo()
  assert_eq(stereo.sample_rate(), 44100)
  assert_true(stereo.length() >= 13230) // 0.3s * 44100

  // Render mono
  let mono = mixer.render_mono()
  assert_eq(mono.sample_rate(), 44100)
  assert_true(mono.length() >= 13230)
}

test "mixer_track_muting_and_limiting" {
  let mixer = Mixer::new(44100)
  let tone1 = render_tone(Sine, 440.0, 0.1, 44100, 1.0)
  let tone2 = render_tone(Sine, 440.0, 0.1, 44100, 1.0)

  let t1 = Track::new(tone1, 0.0, 1.0, 0.0)
  let t2 = Track::new(tone2, 0.0, 1.0, 0.0)
  t2.set_mute(true)

  mixer.tracks.push(t1)
  mixer.tracks.push(t2)

  let rendered = mixer.render_mono()
  // With t2 muted, peak should be near 1.0, not doubled
  let mut max_s = 0.0
  for i = 0; i < rendered.length(); i = i + 1 {
    let a = rendered.get(i).abs()
    if a > max_s { max_s = a }
  }
  assert_true(max_s < 1.0)
}