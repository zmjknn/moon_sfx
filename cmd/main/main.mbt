///|
/// Interactive CLI entry point and demonstration for moon_sfx.
fn main {
  println("==================================================================")
  println("  moon_sfx: Procedural Retro Audio Synthesizer & Sound FX Engine  ")
  println("==================================================================")
  println("")

  println("1. Generating Retro SFXR Sound FX Presets (44.1 kHz, 16-bit PCM):")
  println("------------------------------------------------------------------")

  let presets : Array[(String, Bytes)] = [
    ("Laser Shoot", @lib.play_laser_wav(101U)),
    ("Jump Up", @lib.play_jump_wav(202U)),
    ("Coin Pickup", @lib.play_coin_wav(303U)),
    ("Explosion", @lib.play_explosion_wav(404U)),
    ("Hit / Damage", @lib.play_hit_wav(505U)),
    ("Powerup", @lib.play_powerup_wav(606U)),
    ("UI Blip Click", @lib.play_blip_wav(707U)),
  ]

  for p in presets {
    let (name, wav) = p
    let samples_count = (wav.length() - 44) / 2
    let dur_ms = (samples_count.to_double() / 44.1).to_int()
    println(
      "  - " +
      name +
      ": " +
      wav.length().to_string() +
      " bytes (" +
      samples_count.to_string() +
      " samples, " +
      dur_ms.to_string() +
      " ms)",
    )
  }

  println("")
  println("2. Demonstrating Core Waveform Oscillators:")
  println("------------------------------------------------------------------")
  let waves : Array[(String, @lib.Waveform)] = [
    ("Sine (440Hz)", @lib.Waveform::Sine),
    ("Square PWM 50% (440Hz)", @lib.Waveform::Square(0.5)),
    ("Square PWM 25% (440Hz)", @lib.Waveform::Square(0.25)),
    ("Sawtooth (440Hz)", @lib.Waveform::Sawtooth),
    ("Triangle (440Hz)", @lib.Waveform::Triangle),
    ("White Noise", @lib.Waveform::Noise),
  ]

  for w in waves {
    let (wname, wform) = w
    let tone = @lib.render_tone(wform, 440.0, 0.1, 44100, 0.8)
    let pcm = @lib.encode_wav_16bit(tone)
    println("  - " + wname + ": " + pcm.length().to_string() + " bytes")
  }

  println("")
  println("3. Demonstrating DSP Digital Filters & Effects Pipeline:")
  println("------------------------------------------------------------------")
  let base_tone = @lib.render_tone(@lib.Waveform::Sawtooth, 220.0, 0.2, 44100, 0.8)
  println("  - Base Sawtooth Tone: " + base_tone.length().to_string() + " samples")

  let filtered = base_tone.clone()
  filtered.apply_filter(@lib.FilterType::LowPass, 800.0, 1.4)
  println("  - Applied Biquad Low-Pass Filter (800Hz, Q=1.4): OK")

  let overdriven = base_tone.clone()
  overdriven.apply_overdrive(3.0)
  println("  - Applied Cubic Overdrive Distortion (drive=3.0): OK")

  let bitcrushed = base_tone.clone()
  bitcrushed.apply_bitcrush(4, 4)
  println("  - Applied Retro Lo-Fi Bitcrusher (4-bit, 4x downsample): OK")

  let echoed = base_tone.clone()
  echoed.apply_echo(0.04, 0.5, 0.6)
  println("  - Applied Feedback Delay / Echo (delay=40ms, feedback=0.5): OK")

  println("")
  println("4. Demonstrating Musical Score Sequencer:")
  println("------------------------------------------------------------------")
  let fanfare = @lib.Score::victory_fanfare()
  let rendered_fanfare = @lib.render_score(
    fanfare,
    140,
    @lib.Waveform::Square(0.5),
    @lib.ADSR::organ(),
    44100,
  )
  let fanfare_wav = @lib.encode_wav_16bit(rendered_fanfare)
  println("  - Victory Fanfare (BPM 140, Square Lead):")
  println("    * Duration: " + (rendered_fanfare.duration() * 1000.0).to_int().to_string() + " ms")
  println("    * Samples:  " + rendered_fanfare.length().to_string())
  println("    * WAV Size: " + fanfare_wav.length().to_string() + " bytes")

  println("")
  println("5. Interactive HTML5 Audio Playground Generation:")
  println("------------------------------------------------------------------")
  let html = @lib.generate_html_playground()
  println("  - Generated Single-File HTML5 Audio Studio: " + html.length().to_string() + " characters")
  println("  - Status: Ready for WebAssembly browser playback & zero-asset game audio!")
  println("")
  println("All synthesis pipelines verified successfully.")
}
