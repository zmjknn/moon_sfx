test "constant_power_panning_law" {
  let mono = render_tone(Sine, 440.0, 0.1, 44100, 1.0)

  // Hard Left: pan = -1.0
  let stereo_l = mono.to_stereo(-1.0)
  assert_true(stereo_l.left.get(100).abs() > 0.0)
  assert_true(stereo_l.right.get(100).abs() < 0.00001)

  // Hard Right: pan = 1.0
  let stereo_r = mono.to_stereo(1.0)
  assert_true(stereo_r.left.get(100).abs() < 0.00001)
  assert_true(stereo_r.right.get(100).abs() > 0.0)

  // Center: pan = 0.0 -> L^2 + R^2 should equal input^2
  let stereo_c = mono.to_stereo(0.0)
  let sl = stereo_c.left.get(100)
  let sr = stereo_c.right.get(100)
  let s_orig = mono.get(100)
  let power_sum = sl * sl + sr * sr
  let orig_power = s_orig * s_orig
  assert_true((power_sum - orig_power).abs() < 0.001)
}

test "stereo_wav_encoding" {
  let mono_l = render_tone(Sine, 220.0, 0.1, 44100, 0.5)
  let mono_r = render_tone(Sine, 880.0, 0.1, 44100, 0.5)
  let stereo = StereoBuffer::from_channels(mono_l, mono_r)

  let wav = encode_wav_stereo_16bit(stereo)
  // 44-byte header + 4410 samples * 4 bytes per frame = 44 + 17640 = 17684
  assert_eq(wav.length(), 44 + 4410 * 4)

  // Check RIFF header
  assert_eq(wav[0], b'R')
  assert_eq(wav[1], b'I')
  assert_eq(wav[2], b'F')
  assert_eq(wav[3], b'F')

  // Check Channels = 2 (offset 22)
  let channels = wav[22].to_int() | (wav[23].to_int() << 8)
  assert_eq(channels, 2)

  // Check Data URI
  let uri = stereo.to_data_uri()
  assert_true(uri.has_prefix("data:audio/wav;base64,"))
}

test "soft_limit_saturation" {
  let buf = AudioBuffer::with_silence(44100, 100)
  // Insert extreme loud signals exceeding 1.0
  buf.set(10, 2.5)
  buf.set(20, -3.0)
  buf.set(30, 0.5)

  buf.soft_limit(0.85)

  // Peaks must be strictly compressed within [-1.0, 1.0]
  assert_true(buf.get(10) > 0.85)
  assert_true(buf.get(10) < 1.0)

  assert_true(buf.get(20) < -0.85)
  assert_true(buf.get(20) > -1.0)

  // Sub-threshold signal remains unaltered
  assert_true((buf.get(30) - 0.5).abs() < 0.0001)
}