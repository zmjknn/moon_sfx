///|
test "biquad_filter_processing" {
  let lpf = BiquadFilter::new(LowPass, 1000.0, 0.707, 44100)
  let mut prev_out = 0.0
  for i = 0; i < 100; i = i + 1 {
    let inp = if i % 2 == 0 { 1.0 } else { -1.0 }
    let out = lpf.process(inp)
    // Filtered output should be bounded
    assert_true(out.abs() < 2.0)
    prev_out = out
  }
  assert_true(prev_out.abs() >= 0.0)

  let hpf = BiquadFilter::new(HighPass, 2000.0, 0.707, 44100)
  let bpf = BiquadFilter::new(BandPass, 1500.0, 1.0, 44100)
  assert_true(hpf.process(0.5).abs() < 2.0)
  assert_true(bpf.process(0.5).abs() < 2.0)
}

///|
test "audio_effects_overdrive_echo_bitcrush" {
  let buf = AudioBuffer::new(44100, 4410)
  for i = 0; i < 4410; i = i + 1 {
    buf.push(0.5 * @math.sin(i.to_double() * 0.1))
  }

  // Test overdrive
  buf.apply_overdrive(2.0)
  assert_eq(buf.length(), 4410)
  for i = 0; i < buf.length(); i = i + 1 {
    assert_true(buf.get(i).abs() <= 1.5)
  }

  // Test echo
  buf.apply_echo(0.02, 0.4, 0.5)
  assert_eq(buf.length(), 4410)

  // Test bitcrush
  buf.apply_bitcrush(4, 2)
  assert_eq(buf.length(), 4410)
}
