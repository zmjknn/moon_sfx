///|
/// Pure MoonBit FM (Frequency Modulation) synthesis engine.
/// Emulates classic Yamaha OPL2/OPL3 (AdLib, Sound Blaster) and YM2612 (Sega Genesis/Mega Drive) sound chips.

///|
/// Renders a basic static 2-operator FM tone where the carrier oscillator is frequency-modulated
/// by a sinusoidal modulator oscillator.
/// - `carrier_freq`: Base pitch frequency in Hz (fc)
/// - `mod_freq`: Modulator oscillator frequency in Hz (fm)
/// - `mod_index`: Modulation index I = Delta f / fm (higher index adds more bright sideband harmonics)
pub fn render_fm_tone(
  carrier_freq : Double,
  mod_freq : Double,
  mod_index : Double,
  duration : Double,
  sample_rate : Int,
  volume : Double
) -> AudioBuffer {
  let sr = if sample_rate <= 0 { 44100 } else { sample_rate }
  let sr_d = sr.to_double()
  let dur = if duration <= 0.001 { 0.001 } else { duration }
  let num_samples = (dur * sr_d).to_int()
  let samples = Array::make(num_samples, 0.0)

  let fc = if carrier_freq < 1.0 { 1.0 } else { carrier_freq }
  let fm = if mod_freq < 1.0 { 1.0 } else { mod_freq }
  let idx = if mod_index < 0.0 { 0.0 } else { mod_index }
  let vol = if volume < 0.0 { 0.0 } else if volume > 1.0 { 1.0 } else { volume }

  let dphi_c = two_pi * fc / sr_d
  let dphi_m = two_pi * fm / sr_d

  let mut phi_c = 0.0
  let mut phi_m = 0.0

  for i = 0; i < num_samples; i = i + 1 {
    let mod_val = @math.sin(phi_m) * idx
    let s = @math.sin(phi_c + mod_val) * vol
    samples[i] = s

    phi_c = phi_c + dphi_c
    if phi_c >= two_pi {
      phi_c = phi_c - two_pi
    }
    phi_m = phi_m + dphi_m
    if phi_m >= two_pi {
      phi_m = phi_m - two_pi
    }
  }

  { sample_rate: sr, samples }
}

///|
/// Renders an expressive 2-operator dynamic FM tone with time-varying modulation index and ADSR envelope.
/// The modulation index dynamically transitions from `mod_index_start` to `mod_index_end`,
/// mimicking physical acoustic instruments where harmonic brightness decays faster than base loudness.
pub fn render_fm_dynamic(
  carrier_freq : Double,
  mod_freq : Double,
  mod_index_start : Double,
  mod_index_end : Double,
  duration : Double,
  sample_rate : Int,
  adsr : ADSR,
  volume : Double
) -> AudioBuffer {
  let sr = if sample_rate <= 0 { 44100 } else { sample_rate }
  let sr_d = sr.to_double()
  let dur = if duration <= 0.001 { 0.001 } else { duration }
  let num_samples = (dur * sr_d).to_int()
  let samples = Array::make(num_samples, 0.0)

  let fc = if carrier_freq < 1.0 { 1.0 } else { carrier_freq }
  let fm = if mod_freq < 1.0 { 1.0 } else { mod_freq }
  let vol = if volume < 0.0 { 0.0 } else if volume > 1.0 { 1.0 } else { volume }

  let dphi_c = two_pi * fc / sr_d
  let dphi_m = two_pi * fm / sr_d

  let mut phi_c = 0.0
  let mut phi_m = 0.0

  for i = 0; i < num_samples; i = i + 1 {
    let progress = i.to_double() / num_samples.to_double()
    // Exponential decay of modulation brightness
    let mod_factor = @math.exp(-progress * 3.0)
    let current_index = mod_index_end + (mod_index_start - mod_index_end) * mod_factor

    let mod_val = @math.sin(phi_m) * current_index
    let s = @math.sin(phi_c + mod_val) * vol
    samples[i] = s

    phi_c = phi_c + dphi_c
    if phi_c >= two_pi {
      phi_c = phi_c - two_pi
    }
    phi_m = phi_m + dphi_m
    if phi_m >= two_pi {
      phi_m = phi_m - two_pi
    }
  }

  let buf = { sample_rate: sr, samples }
  buf.apply_adsr(adsr, Exponential)
  buf
}

///|
/// FM Preset 1: Yamaha DX7 style retro Electric Piano (E-Piano).
/// Uses 1:1 harmonic ratio with snappy attack and warm metallic bell transient.
pub fn fm_electric_piano(freq : Double, duration : Double, sample_rate : Int) -> AudioBuffer {
  let adsr = ADSR::new(0.005, 0.4, 0.35, 0.25)
  render_fm_dynamic(
    freq,
    freq * 1.0, // 1:1 ratio
    3.2,        // Bright initial tine strike
    0.2,        // Soft acoustic sustain
    duration,
    sample_rate,
    adsr,
    0.85,
  )
}

///|
/// FM Preset 2: Crystal Chime / Metallic Church Bell.
/// Uses inharmonic ratio (1 : sqrt(2) ≈ 1 : 1.4142) to produce authentic metallic overtones.
pub fn fm_bell(freq : Double, duration : Double, sample_rate : Int) -> AudioBuffer {
  let adsr = ADSR::new(0.002, duration * 0.7, 0.1, duration * 0.3)
  render_fm_dynamic(
    freq,
    freq * 1.41421356, // Inharmonic golden ratio
    5.0,               // Heavy metallic clang
    0.05,              // Settles into pure resonant hum
    duration,
    sample_rate,
    adsr,
    0.8,
  )
}

///|
/// FM Preset 3: 80s Synth Brass / Synth Horn.
/// Features a dynamic filter swell characteristic of vintage polyphonic brass synthesizers.
pub fn fm_brass(freq : Double, duration : Double, sample_rate : Int) -> AudioBuffer {
  let adsr = ADSR::new(0.06, 0.2, 0.7, 0.15)
  render_fm_dynamic(
    freq,
    freq * 1.0,
    3.8,
    1.5,
    duration,
    sample_rate,
    adsr,
    0.85,
  )
}

///|
/// FM Preset 4: Sega Genesis 16-bit Funk Slap Bass.
/// Uses 1:2 harmonic ratio for punching second harmonic transient.
pub fn fm_slap_bass(freq : Double, duration : Double, sample_rate : Int) -> AudioBuffer {
  let adsr = ADSR::percussive(0.2)
  render_fm_dynamic(
    freq,
    freq * 2.0, // 1:2 ratio for sharp low-end slap
    6.0,        // High-energy slap transient
    0.3,
    duration,
    sample_rate,
    adsr,
    0.9,
  )
}