test "wav_inspect_header" {
  let buf = render_tone(Sine, 440.0, 0.25, 44100, 0.8)
  let bytes = encode_wav_16bit(buf)

  let info = match inspect_wav(bytes) {
    Ok(inf) => inf
    Err(e) => {
      println("Inspect failed: " + e)
      assert_true(false)
      return
    }
  }

  assert_eq(info.sample_rate, 44100)
  assert_eq(info.num_channels, 1)
  assert_eq(info.bits_per_sample, 16)
  assert_eq(info.num_samples, 11025) // 0.25s * 44100
  assert_true((info.duration - 0.25).abs() < 0.001)
}

test "wav_roundtrip_mono_16bit" {
  let original = render_tone(Triangle, 330.0, 0.1, 44100, 0.75)
  let wav_bytes = encode_wav_16bit(original)

  let decoded = match decode_wav(wav_bytes) {
    Ok(b) => b
    Err(e) => {
      println("Decode failed: " + e)
      assert_true(false)
      return
    }
  }

  assert_eq(decoded.sample_rate(), original.sample_rate())
  assert_eq(decoded.length(), original.length())

  // Samples should match original within 16-bit quantization error (+-1/32768 ≈ 0.0001)
  for i = 0; i < original.length(); i = i + 1 {
    let diff = (decoded.get(i) - original.get(i)).abs()
    assert_true(diff < 0.001)
  }
}

test "wav_roundtrip_stereo_16bit" {
  let left = render_tone(Sine, 220.0, 0.1, 44100, 0.6)
  let right = render_tone(Sawtooth, 440.0, 0.1, 44100, 0.6)
  let stereo_orig = StereoBuffer::from_channels(left, right)

  let wav_bytes = encode_wav_stereo_16bit(stereo_orig)

  let decoded = match decode_wav_stereo(wav_bytes) {
    Ok(s) => s
    Err(e) => {
      println("Stereo decode failed: " + e)
      assert_true(false)
      return
    }
  }

  assert_eq(decoded.sample_rate(), 44100)
  assert_eq(decoded.length(), 4410)

  // Verify left channel matches original left
  for i = 0; i < 4410; i = i + 1 {
    let diff_l = (decoded.left.get(i) - left.get(i)).abs()
    let diff_r = (decoded.right.get(i) - right.get(i)).abs()
    assert_true(diff_l < 0.001)
    assert_true(diff_r < 0.001)
  }
}

test "wav_decode_corrupted_header" {
  let fake_bytes = Bytes::from_array([b'X', b'Y', b'Z', b'W'])
  let res = decode_wav(fake_bytes)
  let is_error = match res {
    Err(_) => true
    Ok(_) => false
  }
  assert_true(is_error)
}