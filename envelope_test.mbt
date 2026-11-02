///|
test "adsr_gain_calculation" {
  let adsr = ADSR::new(0.01, 0.02, 0.5, 0.02)
  let total_dur = 0.1

  // Start at 0
  assert_true(adsr.gain_at(0.0, total_dur, Linear) < 0.001)

  // Peak of attack at 0.01s
  assert_true((adsr.gain_at(0.01, total_dur, Linear) - 1.0).abs() < 0.05)

  // Mid sustain around 0.05s
  assert_true((adsr.gain_at(0.05, total_dur, Linear) - 0.5).abs() < 0.05)

  // End of release at 0.1s
  assert_true(adsr.gain_at(0.1, total_dur, Linear) < 0.01)

  // Exponential curve check
  let gain_exp = adsr.gain_at(0.005, total_dur, Exponential)
  assert_true(gain_exp >= 0.0 && gain_exp <= 1.0)
}

///|
test "adsr_presets_and_application" {
  let perc = ADSR::percussive(0.2)
  assert_true(perc.gain_at(0.003, 0.2, Linear) > 0.8)

  let pad = ADSR::pad(0.1, 0.1)
  assert_true(pad.gain_at(0.05, 0.5, Linear) > 0.0)

  let organ = ADSR::organ()
  assert_true(organ.gain_at(0.03, 0.2, Linear) > 0.8)

  let buf = AudioBuffer::new(44100, 4410)
  for i = 0; i < 4410; i = i + 1 {
    buf.push(1.0)
  }
  buf.apply_adsr(perc, Linear)
  assert_true(buf.get(0) < 0.1)
  assert_true(buf.get(buf.length() - 1) < 0.05)
}
