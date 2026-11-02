///|
test "audio_buffer_creation_and_basics" {
  let buf = AudioBuffer::new(44100, 100)
  assert_eq(buf.sample_rate(), 44100)
  assert_eq(buf.length(), 0)
  assert_true(buf.duration().abs() < 0.0001)

  buf.push(0.5)
  buf.push(-0.5)
  assert_eq(buf.length(), 2)
  assert_true((buf.get(0) - 0.5).abs() < 0.0001)
  assert_true((buf.get(1) - -0.5).abs() < 0.0001)
  assert_true(buf.get(999).abs() < 0.0001) // out of bounds default

  buf.set(1, 0.75)
  assert_true((buf.get(1) - 0.75).abs() < 0.0001)
}

///|
test "audio_buffer_silence" {
  let buf = AudioBuffer::with_silence(22050, 2205)
  assert_eq(buf.length(), 2205)
  assert_true((buf.duration() - 0.1).abs() < 0.001)
  for i = 0; i < buf.length(); i = i + 1 {
    assert_true(buf.get(i).abs() < 0.000001)
  }
}

///|
test "audio_buffer_clamp_and_amplify" {
  let buf = AudioBuffer::new(44100, 4)
  buf.push(-2.0)
  buf.push(-0.5)
  buf.push(0.5)
  buf.push(2.5)

  buf.clamp(-1.0, 1.0)
  assert_true((buf.get(0) - -1.0).abs() < 0.0001)
  assert_true((buf.get(3) - 1.0).abs() < 0.0001)

  buf.amplify(0.5)
  assert_true((buf.get(0) - -0.5).abs() < 0.0001)
  assert_true((buf.get(3) - 0.5).abs() < 0.0001)
}

///|
test "audio_buffer_normalize" {
  let buf = AudioBuffer::new(44100, 2)
  buf.push(0.25)
  buf.push(-0.5)

  buf.normalize(1.0)
  assert_true((buf.get(1) - -1.0).abs() < 0.0001)
  assert_true((buf.get(0) - 0.5).abs() < 0.0001)
}

///|
test "audio_buffer_mix_and_clone" {
  let buf1 = AudioBuffer::new(44100, 2)
  buf1.push(0.2)
  buf1.push(0.4)

  let buf2 = AudioBuffer::new(44100, 2)
  buf2.push(0.1)
  buf2.push(0.2)

  buf1.mix(buf2, 1, 1.0)
  assert_eq(buf1.length(), 3)
  assert_true((buf1.get(0) - 0.2).abs() < 0.0001)
  assert_true((buf1.get(1) - 0.5).abs() < 0.0001) // 0.4 + 0.1
  assert_true((buf1.get(2) - 0.2).abs() < 0.0001)

  let cloned = buf1.clone()
  assert_eq(cloned.length(), buf1.length())
  assert_true((cloned.get(1) - buf1.get(1)).abs() < 0.0001)
}

///|
test "audio_buffer_pcm_conversions" {
  let buf = AudioBuffer::new(44100, 3)
  buf.push(-1.0)
  buf.push(0.0)
  buf.push(1.0)

  let pcm16 = buf.to_16bit_pcm()
  assert_eq(pcm16.length(), 3)
  assert_eq(pcm16[0], -32767)
  assert_eq(pcm16[1], 0)
  assert_eq(pcm16[2], 32767)

  let pcm8 = buf.to_8bit_pcm()
  assert_eq(pcm8.length(), 3)
  assert_eq(pcm8[0], b'\x00')
  assert_eq(pcm8[1], b'\x7F') // 127
  assert_eq(pcm8[2], b'\xFF') // 255
}
