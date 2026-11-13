///|
/// Boundary, invariant, and resilience tests for moon_sfx.
/// Designed to rigorously verify extreme parameters, boundary conditions,
/// and ensure zero panics, zero NaNs, and zero data leakage.

///|
test "sfxr_presets_with_edge_case_seeds" {
  // Test seeds 0, 1, 2, 42, 999999, 0xFFFFFFFF
  let test_seeds : Array[UInt32] = [0U, 1U, 2U, 42U, 999999U, 0xFFFFFFFFU]

  for seed in test_seeds {
    // 1. All 8 presets with each seed must generate valid non-empty WAV bytes
    let laser = play_laser_wav(seed)
    assert_true(laser.length() > 44)
    let jump = play_jump_wav(seed)
    assert_true(jump.length() > 44)
    let coin = play_coin_wav(seed)
    assert_true(coin.length() > 44)
    let explosion = play_explosion_wav(seed)
    assert_true(explosion.length() > 44)
    let hit = play_hit_wav(seed)
    assert_true(hit.length() > 44)
    let powerup = play_powerup_wav(seed)
    assert_true(powerup.length() > 44)
    let blip = play_blip_wav(seed)
    assert_true(blip.length() > 44)
    let burst = play_burst_wav(seed)
    assert_true(burst.length() > 44)

    // Inspect each WAV header to ensure validity
    let info = inspect_wav(laser).unwrap()
    assert_eq(info.sample_rate, 44100)
    assert_eq(info.num_channels, 1)
    assert_eq(info.bits_per_sample, 16)
    assert_true(info.num_samples > 0)
    assert_true(info.duration > 0.0)
  }
}

///|
test "sfxr_extreme_boundary_parameters_no_crash" {
  let p = SfxParams::default()
  // Extreme values: zero envelope times, negative values, extreme sweeps
  p.attack_time = 0.0
  p.sustain_time = 0.0
  p.decay_time = 0.0
  p.start_freq = -500.0
  p.min_freq = -100.0
  p.freq_slide = 10.0
  p.freq_delta_slide = 5.0
  p.phaser_offset = 50.0
  p.phaser_sweep = -100.0
  p.repeat_speed = 5.0 // Way above 1.0
  p.lpf_cutoff = 50000.0
  p.lpf_sweep = -10000.0
  p.hpf_cutoff = -500.0
  p.hpf_sweep = 10000.0
  p.vibrato_speed = 100.0
  p.vibrato_depth = 5.0

  let buf = p.synthesize(44100)
  assert_true(buf.length() > 0)

  // Verify no NaN or Inf in generated samples
  for i = 0; i < buf.length(); i = i + 1 {
    let s = buf.get(i)
    assert_true(!s.is_nan())
    assert_true(!s.is_inf())
  }
}

///|
test "mixer_mute_and_pan_invariants" {
  let sr = 44100
  let tone = render_tone(Waveform::Sine, 440.0, 0.1, sr, 0.8)

  // 1. Muted track must contribute 0.0 energy
  let mixer_muted = Mixer::new(sr)
  mixer_muted.add_track(tone, 0.0, 1.0, 0.0)
  mixer_muted.tracks[0].set_mute(true)
  let mono_muted = mixer_muted.render_mono()
  for i = 0; i < mono_muted.length(); i = i + 1 {
    assert_eq(mono_muted.get(i), 0.0)
  }

  // 2. Pure Left Pan (-1.0): Right channel must be EXACTLY 0.0
  let mixer_left = Mixer::new(sr)
  mixer_left.add_track(tone, 0.0, 1.0, -1.0)
  let stereo_left = mixer_left.render_stereo()
  assert_true(stereo_left.left.length() > 0)
  assert_true(stereo_left.right.length() > 0)
  for i = 0; i < stereo_left.right.length(); i = i + 1 {
    assert_eq(stereo_left.right.get(i), 0.0)
  }

  // 3. Pure Right Pan (1.0): Left channel must be EXACTLY 0.0
  let mixer_right = Mixer::new(sr)
  mixer_right.add_track(tone, 0.0, 1.0, 1.0)
  let stereo_right = mixer_right.render_stereo()
  for i = 0; i < stereo_right.left.length(); i = i + 1 {
    assert_eq(stereo_right.left.get(i), 0.0)
  }

  // 4. Empty mixer: must return 0 samples gracefully
  let mixer_empty = Mixer::new(sr)
  let stereo_empty = mixer_empty.render_stereo()
  assert_eq(stereo_empty.length(), 0)
  let mono_empty = mixer_empty.render_mono()
  assert_eq(mono_empty.length(), 0)
}

///|
test "wav_odd_chunk_word_alignment_padding" {
  // Construct a WAV byte array with an odd-length custom metadata chunk before 'data'
  // RIFF header:
  // 00..03: 'RIFF'
  // 04..07: ChunkSize
  // 08..11: 'WAVE'
  // 12..15: 'fmt '
  // 16..19: Subchunk1Size = 16
  // 20..35: fmt data (PCM, 1 ch, 44100 sr, 88200 byte_rate, 2 block_align, 16 bps)
  // 36..39: 'JUNK'
  // 40..43: JUNK length = 3 (ODD!)
  // 44..46: 'ABC'
  // 47: 0x00 padding byte!
  // 48..51: 'data'
  // 52..55: data length = 4 (2 16-bit samples)
  // 56..59: sample data
  let total_len = 60
  let b = FixedArray::make(total_len, b'\x00')
  b[0] = b'R'
  b[1] = b'I'
  b[2] = b'F'
  b[3] = b'F'
  write_u32_le(b, 4, total_len - 8)
  b[8] = b'W'
  b[9] = b'A'
  b[10] = b'V'
  b[11] = b'E'

  // fmt
  b[12] = b'f'
  b[13] = b'm'
  b[14] = b't'
  b[15] = b' '
  write_u32_le(b, 16, 16)
  write_u16_le(b, 20, 1) // format 1
  write_u16_le(b, 22, 1) // 1 channel
  write_u32_le(b, 24, 44100) // 44100 Hz
  write_u32_le(b, 28, 88200) // byte rate
  write_u16_le(b, 32, 2) // block align
  write_u16_le(b, 34, 16) // 16 bits

  // JUNK chunk with odd length 3
  b[36] = b'J'
  b[37] = b'U'
  b[38] = b'N'
  b[39] = b'K'
  write_u32_le(b, 40, 3) // length 3 (odd)
  b[44] = b'A'
  b[45] = b'B'
  b[46] = b'C'
  b[47] = b'\x00' // RIFF word-alignment pad byte

  // data chunk
  b[48] = b'd'
  b[49] = b'a'
  b[50] = b't'
  b[51] = b'a'
  write_u32_le(b, 52, 4) // 4 bytes = 2 samples
  write_u16_le(b, 56, 16384) // sample 0 = ~0.5
  write_u16_le(b, 58, 32767) // sample 1 = ~1.0

  let list = []
  for byte in b {
    list.push(byte)
  }
  let wav_bytes = Bytes::from_array(list)

  // Verify inspect_wav successfully traverses the odd chunk and finds data
  let info = inspect_wav(wav_bytes).unwrap()
  assert_eq(info.num_samples, 2)
  assert_eq(info.sample_rate, 44100)

  // Verify decode_wav parses samples correctly
  let decoded = decode_wav(wav_bytes).unwrap()
  assert_eq(decoded.length(), 2)
  assert_true((decoded.get(0) - 0.5).abs() < 0.01)
  assert_true((decoded.get(1) - 1.0).abs() < 0.01)
}

///|
test "mml_comprehensive_syntax_and_robustness" {
  // Test case insensitive, octaves, accidentals (+, #, -), rests (R, P), durations, volume
  let mml_str = "  T160   O3 c+4 d-8 e8 | f#16 g16 a+8 b4 > c8 < r8 p16 V90 d4 "
  let (score, bpm) = parse_mml(mml_str)
  assert_eq(bpm, 160)
  assert_true(score.length() >= 8)

  // Render MML directly
  let audio = render_mml(mml_str, Waveform::Square(0.5), ADSR::organ(), 22050)
  assert_true(audio.length() > 0)
  for i = 0; i < audio.length(); i = i + 1 {
    let s = audio.get(i)
    assert_true(!s.is_nan())
    assert_true(!s.is_inf())
  }
}

///|
test "fm_boundary_and_invariants" {
  // Test 0 and extreme durations, zero carrier/mod freq
  let fm_zero = render_fm_tone(0.0, 0.0, 0.0, 0.0, 0, 0.0)
  assert_true(fm_zero.length() > 0)

  let fm_extreme = render_fm_dynamic(
    1000.0,
    500.0,
    20.0,
    0.0,
    0.05,
    44100,
    ADSR::percussive(0.05),
    1.0,
  )
  assert_true(fm_extreme.length() > 0)
  for i = 0; i < fm_extreme.length(); i = i + 1 {
    let s = fm_extreme.get(i)
    assert_true(!s.is_nan())
    assert_true(!s.is_inf())
  }
}

///|
test "readme_example_execution_verification" {
  // Verify Example 1 from README works exactly as advertised
  let wav_bytes = play_laser_wav(42U)
  assert_true(wav_bytes.length() > 0)

  // Verify Example 2 from README
  let tone = render_tone(Waveform::Square(0.5), 440.0, 0.1, 44100, 0.8)
  let adsr = ADSR::percussive(0.08)
  tone.apply_adsr(adsr, Curve::Exponential)
  tone.apply_filter(FilterType::LowPass, 1200.0, 1.0)
  tone.apply_echo(0.02, 0.4, 0.5)
  assert_true(tone.length() > 0)

  // Verify Example 3 from README
  let score = Score::victory_fanfare()
  let audio = render_score(
    score,
    140,
    Waveform::Square(0.5),
    ADSR::organ(),
    44100,
  )
  let data_uri = audio.to_data_uri()
  assert_true(data_uri.length() > 50)
}

///|
test "wav_empty_buffer_roundtrip" {
  let empty_buf = AudioBuffer::new(44100, 0)
  assert_eq(empty_buf.length(), 0)

  // 16-bit mono
  let wav16 = encode_wav_16bit(empty_buf)
  assert_eq(wav16.length(), 44)
  let info16 = inspect_wav(wav16).unwrap()
  assert_eq(info16.num_samples, 0)
  assert_eq(info16.duration, 0.0)
  let dec16 = decode_wav(wav16).unwrap()
  assert_eq(dec16.length(), 0)

  // 8-bit mono
  let wav8 = encode_wav_8bit(empty_buf)
  assert_eq(wav8.length(), 44)
  let info8 = inspect_wav(wav8).unwrap()
  assert_eq(info8.num_samples, 0)
  let dec8 = decode_wav(wav8).unwrap()
  assert_eq(dec8.length(), 0)

  // Stereo
  let empty_stereo = StereoBuffer::new(44100, 0)
  let wav_stereo = encode_wav_stereo_16bit(empty_stereo)
  assert_eq(wav_stereo.length(), 44)
  let info_stereo = inspect_wav(wav_stereo).unwrap()
  assert_eq(info_stereo.num_channels, 2)
  assert_eq(info_stereo.num_samples, 0)
  let dec_stereo = decode_wav_stereo(wav_stereo).unwrap()
  assert_eq(dec_stereo.length(), 0)
}

///|
fn[T, E] is_err(res : Result[T, E]) -> Bool {
  match res {
    Ok(_) => false
    Err(_) => true
  }
}

///|
test "wav_corrupted_headers_error_handling" {
  // 1. Shorter than 44 bytes
  let short_bytes = Bytes::make(20, b'\x00')
  assert_true(is_err(inspect_wav(short_bytes)))
  assert_true(is_err(decode_wav(short_bytes)))

  // 2. Invalid RIFF magic
  let bad_riff = Bytes::make(44, b'\x00')
  assert_true(is_err(inspect_wav(bad_riff)))

  // 3. Invalid WAVE magic
  let list = []
  for _ in 0..<44 {
    list.push(b'\x00')
  }
  list[0] = b'R'
  list[1] = b'I'
  list[2] = b'F'
  list[3] = b'F'
  list[8] = b'B'
  list[9] = b'A'
  list[10] = b'D'
  list[11] = b'!'
  let bad_wave = Bytes::from_array(list)
  assert_true(is_err(inspect_wav(bad_wave)))
}

///|
test "dsp_effects_boundary_parameters" {
  let buf = AudioBuffer::new(44100, 100)
  for _ in 0..<100 {
    buf.push(0.5)
  }

  // Extreme filter parameters
  buf.apply_filter(LowPass, -100.0, -1.0)
  buf.apply_filter(HighPass, 50000.0, 10.0)
  buf.apply_filter(BandPass, 1000.0, 0.05)

  // Overdrive with negative drive
  buf.apply_overdrive(-5.0)

  // Echo with boundary parameters
  buf.apply_echo(-1.0, -0.5, -0.2)
  buf.apply_echo(0.0001, 1.5, 2.0)

  // Bitcrusher with boundary parameters
  buf.apply_bitcrush(1, 0)
  buf.apply_bitcrush(32, 100)

  // Verify all samples remain finite
  for i = 0; i < buf.length(); i = i + 1 {
    let s = buf.get(i)
    assert_true(!s.is_nan())
    assert_true(!s.is_inf())
  }
}

///|
test "adsr_curves_boundary_times" {
  let adsr = ADSR::new(0.05, 0.05, 0.7, 0.05)

  // Negative time or time beyond duration
  assert_eq(adsr.gain_at(-1.0, 1.0, Linear), 0.0)
  assert_eq(adsr.gain_at(2.0, 1.0, Linear), 0.0)
  assert_eq(adsr.gain_at(0.5, 0.0, Linear), 0.0)

  // Linear and Exponential curves within [0.0, 1.0]
  for i = 0; i <= 20; i = i + 1 {
    let t = i.to_double() * 0.05
    let gl = adsr.gain_at(t, 1.0, Linear)
    let ge = adsr.gain_at(t, 1.0, Exponential)
    assert_true(gl >= 0.0 && gl <= 1.0)
    assert_true(ge >= 0.0 && ge <= 1.0)
  }
}

///|
test "mml_malformed_input_graceful" {
  // Empty MML string
  let (empty_score, empty_bpm) = parse_mml("")
  assert_eq(empty_bpm, 120)
  assert_eq(empty_score.length(), 0)

  // Malformed characters and symbols
  let (weird_score, weird_bpm) = parse_mml("!@#$%^&*()_+=~`{}[]:;'\"/?.,<>")
  assert_eq(weird_bpm, 120)
  assert_eq(weird_score.length(), 0)
}
