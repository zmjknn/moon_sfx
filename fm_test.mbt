test "fm_tone_generation" {
  let fm = render_fm_tone(440.0, 440.0, 2.0, 0.1, 44100, 0.8)
  assert_eq(fm.length(), 4410)
  assert_eq(fm.sample_rate(), 44100)

  let mut has_non_zero = false
  for i = 0; i < fm.length(); i = i + 1 {
    if fm.get(i).abs() > 0.05 {
      has_non_zero = true
      break
    }
  }
  assert_true(has_non_zero)
}

test "fm_presets_render" {
  // Electric Piano
  let ep = fm_electric_piano(440.0, 0.2, 44100)
  assert_eq(ep.length(), 8820)
  assert_true(ep.get(50).abs() > 0.0)

  // Crystal Bell
  let bell = fm_bell(880.0, 0.2, 44100)
  assert_eq(bell.length(), 8820)

  // Synth Brass
  let brass = fm_brass(330.0, 0.2, 44100)
  assert_eq(brass.length(), 8820)

  // Slap Bass
  let bass = fm_slap_bass(110.0, 0.2, 44100)
  assert_eq(bass.length(), 8820)
}