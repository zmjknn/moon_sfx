///|
test "rng_deterministic_properties" {
  let rng1 = Rng::new(12345U)
  let rng2 = Rng::new(12345U)

  assert_eq(rng1.next_u32(), rng2.next_u32())
  assert_eq(rng1.next_u32(), rng2.next_u32())

  for i = 0; i < 50; i = i + 1 {
    let d = rng1.next_double()
    assert_true(d >= 0.0 && d < 1.0)
    let b = rng1.next_bipolar()
    assert_true(b >= -1.0 && b <= 1.0)
  }
}

///|
test "waveform_sampling_shapes" {
  let rng = Rng::new(99U)

  // Sine tests
  assert_true(sample_waveform(Sine, 0.0, rng).abs() < 0.0001)
  assert_true((sample_waveform(Sine, 0.25, rng) - 1.0).abs() < 0.0001)
  assert_true(sample_waveform(Sine, 0.5, rng).abs() < 0.0001)
  assert_true((sample_waveform(Sine, 0.75, rng) - -1.0).abs() < 0.0001)

  // Square tests (duty 0.5)
  assert_true((sample_waveform(Square(0.5), 0.2, rng) - 1.0).abs() < 0.0001)
  assert_true((sample_waveform(Square(0.5), 0.7, rng) - -1.0).abs() < 0.0001)

  // Sawtooth tests
  assert_true((sample_waveform(Sawtooth, 0.0, rng) - -1.0).abs() < 0.0001)
  assert_true(sample_waveform(Sawtooth, 0.5, rng).abs() < 0.0001)

  // Triangle tests
  assert_true((sample_waveform(Triangle, 0.0, rng) - -1.0).abs() < 0.0001)
  assert_true((sample_waveform(Triangle, 0.25, rng) - 0.0).abs() < 0.0001)
  assert_true((sample_waveform(Triangle, 0.5, rng) - 1.0).abs() < 0.0001)

  // Noise bounds test
  for i = 0; i < 20; i = i + 1 {
    let n = sample_waveform(Noise, 0.0, rng)
    assert_true(n >= -1.0 && n <= 1.0)
  }
}

///|
test "render_tone_output" {
  let tone = render_tone(Sine, 440.0, 0.05, 44100, 0.8)
  assert_eq(tone.sample_rate(), 44100)
  assert_eq(tone.length(), 2205) // 44100 * 0.05 = 2205
  assert_true(tone.duration() >= 0.049)

  let mut has_nonzero = false
  for i = 0; i < tone.length(); i = i + 1 {
    if tone.get(i).abs() > 0.01 {
      has_nonzero = true
      break
    }
  }
  assert_true(has_nonzero)
}
