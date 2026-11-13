///|
test "mml_parser_syntax" {
  let mml_str = "T140 O5 L8 C D E F G A B > C4"
  let (score, bpm) = parse_mml(mml_str)

  assert_eq(bpm, 140)
  // 7 notes of octave 5 (C, D, E, F, G, A, B) + 1 note of octave 6 = 8 items
  assert_eq(score.items.length(), 8)

  // Verify first note is C5, Eighth
  let item0 = score.items[0]
  assert_eq(item0.note, C)
  assert_eq(item0.octave, 5)
  assert_eq(item0.duration, Eighth)

  // Verify last note is C6, Quarter
  let item7 = score.items[7]
  assert_eq(item7.note, C)
  assert_eq(item7.octave, 6)
  assert_eq(item7.duration, Quarter)
}

///|
test "mml_accidentals_and_rests" {
  let mml_str = "C#4 D+8 E-8 R4 F+2"
  let (score, _) = parse_mml(mml_str)

  assert_eq(score.items.length(), 5)
  assert_eq(score.items[0].note, Cs)
  assert_eq(score.items[0].duration, Quarter)

  assert_eq(score.items[1].note, Ds)
  assert_eq(score.items[1].duration, Eighth)

  assert_eq(score.items[2].note, Ds) // E- is Eb = D#
  assert_eq(score.items[2].duration, Eighth)

  assert_eq(score.items[3].note, Rest)
  assert_eq(score.items[3].duration, Quarter)

  assert_eq(score.items[4].note, Fs)
  assert_eq(score.items[4].duration, Half)
}

///|
test "render_mml_audio" {
  let mml_str = "T160 O4 C8 E8 G8 > C8"
  let audio = render_mml(mml_str, Square(0.5), ADSR::organ(), 44100)
  assert_eq(audio.sample_rate(), 44100)
  assert_true(audio.length() > 0)
}
