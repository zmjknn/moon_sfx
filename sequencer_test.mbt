///|
test "note_to_frequency_precision" {
  // A4 = 440 Hz standard
  assert_true((note_to_frequency(A, 4) - 440.0).abs() < 0.001)

  // A3 = 220 Hz
  assert_true((note_to_frequency(A, 3) - 220.0).abs() < 0.001)

  // A5 = 880 Hz
  assert_true((note_to_frequency(A, 5) - 880.0).abs() < 0.001)

  // Middle C (C4) approx 261.63 Hz
  assert_true((note_to_frequency(C, 4) - 261.63).abs() < 0.1)

  // Rest = 0 Hz
  assert_true(note_to_frequency(Rest, 4).abs() < 0.0001)

  // Check all notes return positive frequency
  assert_true(note_to_frequency(Cs, 4) > 0.0)
  assert_true(note_to_frequency(D, 4) > 0.0)
  assert_true(note_to_frequency(Ds, 4) > 0.0)
  assert_true(note_to_frequency(E, 4) > 0.0)
  assert_true(note_to_frequency(F, 4) > 0.0)
  assert_true(note_to_frequency(Fs, 4) > 0.0)
  assert_true(note_to_frequency(G, 4) > 0.0)
  assert_true(note_to_frequency(Gs, 4) > 0.0)
  assert_true(note_to_frequency(As, 4) > 0.0)
  assert_true(note_to_frequency(B, 4) > 0.0)
}

///|
test "duration_to_seconds_scaling" {
  // At 120 BPM: 1 beat = 0.5s (Quarter note)
  assert_true((duration_to_seconds(Quarter, 120) - 0.5).abs() < 0.001)
  assert_true((duration_to_seconds(Whole, 120) - 2.0).abs() < 0.001)
  assert_true((duration_to_seconds(Half, 120) - 1.0).abs() < 0.001)
  assert_true((duration_to_seconds(Eighth, 120) - 0.25).abs() < 0.001)
  assert_true((duration_to_seconds(Sixteenth, 120) - 0.125).abs() < 0.001)
}

///|
test "score_rendering" {
  let score = Score::arpeggio_c_major()
  let rendered = render_score(score, 140, Square(0.5), ADSR::organ(), 22050)
  assert_eq(rendered.sample_rate(), 22050)
  assert_true(rendered.length() > 0)
  assert_true(rendered.duration() > 1.0)

  let fanfare = Score::victory_fanfare()
  let fanfare_buf = render_score(fanfare, 140, Sawtooth, ADSR::organ(), 22050)
  assert_true(fanfare_buf.length() > 0)
}
