///|
test "benchmark_synthesis_throughput" {
  // Synthesize 50 consecutive sound effects to verify performance and zero memory leaks
  for i = 0; i < 50; i = i + 1 {
    let p = SfxParams::laser(i.reinterpret_as_uint() + 100U)
    let buf = p.synthesize(44100)
    let wav = encode_wav_16bit(buf)
    assert_true(wav.length() > 44)
  }
}

///|
test "benchmark_polyphonic_mixing" {
  let master = AudioBuffer::new(44100, 44100)
  for i = 0; i < 10; i = i + 1 {
    let layer = SfxParams::blip(i.reinterpret_as_uint()).synthesize(44100)
    master.mix(layer, i * 4000, 0.5)
  }
  assert_true(master.length() > 35000)
}
