///|
test "wav_16bit_encoding_header" {
  let buf = AudioBuffer::new(44100, 100)
  for i = 0; i < 100; i = i + 1 {
    buf.push(0.5)
  }

  let wav = encode_wav_16bit(buf)
  // Expected size: 44 header bytes + 100 * 2 = 244 bytes
  assert_eq(wav.length(), 244)

  // Verify "RIFF" signature
  assert_eq(wav[0], b'R')
  assert_eq(wav[1], b'I')
  assert_eq(wav[2], b'F')
  assert_eq(wav[3], b'F')

  // Verify "WAVE" signature
  assert_eq(wav[8], b'W')
  assert_eq(wav[9], b'A')
  assert_eq(wav[10], b'V')
  assert_eq(wav[11], b'E')

  // Verify "fmt " signature
  assert_eq(wav[12], b'f')
  assert_eq(wav[13], b'm')
  assert_eq(wav[14], b't')
  assert_eq(wav[15], b' ')

  // Verify "data" signature
  assert_eq(wav[36], b'd')
  assert_eq(wav[37], b'a')
  assert_eq(wav[38], b't')
  assert_eq(wav[39], b'a')
}

///|
test "wav_8bit_encoding_header" {
  let buf = AudioBuffer::new(22050, 50)
  for i = 0; i < 50; i = i + 1 {
    buf.push(0.0)
  }

  let wav = encode_wav_8bit(buf)
  // Expected size: 44 header bytes + 50 * 1 = 94 bytes
  assert_eq(wav.length(), 94)
  assert_eq(wav[0], b'R')
  assert_eq(wav[36], b'd')
}

///|
test "base64_rfc_vectors" {
  let b0 = Bytes::make(0, b'\x00')
  assert_eq(to_base64(b0), "")

  let b1 = Bytes::from_array([b'f'])
  assert_eq(to_base64(b1), "Zg==")

  let b2 = Bytes::from_array([b'f', b'o'])
  assert_eq(to_base64(b2), "Zm8=")

  let b3 = Bytes::from_array([b'f', b'o', b'o'])
  assert_eq(to_base64(b3), "Zm9v")
}

///|
test "audio_buffer_to_data_uri" {
  let buf = AudioBuffer::new(44100, 10)
  for i = 0; i < 10; i = i + 1 {
    buf.push(0.0)
  }
  let uri = buf.to_data_uri()
  assert_true(uri.has_prefix("data:audio/wav;base64,"))
  assert_true(uri.length() > 30)
}
