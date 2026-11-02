///|
pub let pi : Double = 3.141592653589793

///|
pub let two_pi : Double = 6.283185307179586

///|
/// Fast deterministic pseudo-random number generator (Xorshift32) for reproducible audio noise and parameter mutation.
pub struct Rng {
  mut state : UInt
}

///|
/// Creates a new Rng with the given 32-bit unsigned seed.
pub fn Rng::new(seed : UInt) -> Rng {
  let s = if seed == 0U { 2463534242U } else { seed }
  { state: s }
}

///|
/// Generates the next pseudorandom 32-bit unsigned integer.
pub fn Rng::next_u32(self : Rng) -> UInt {
  let mut x = self.state
  x = x ^ (x << 13)
  x = x ^ (x >> 17)
  x = x ^ (x << 5)
  self.state = x
  x
}

///|
/// Generates a uniform float in the range [0.0, 1.0).
pub fn Rng::next_double(self : Rng) -> Double {
  let u = self.next_u32()
  let masked = (u & 0x7fffffffU).reinterpret_as_int()
  masked.to_double() / 2147483648.0
}

///|
/// Generates a uniform bipolar float in the range [-1.0, 1.0).
pub fn Rng::next_bipolar(self : Rng) -> Double {
  self.next_double() * 2.0 - 1.0
}

///|
/// Evaluates a single waveform sample at a given normalized phase in [0.0, 1.0).
pub fn sample_waveform(waveform : Waveform, phase : Double, rng : Rng) -> Double {
  // Wrap phase into [0.0, 1.0)
  let p = phase - phase.floor()
  match waveform {
    Sine => @math.sin(p * two_pi)
    Square(duty) => {
      let d = if duty < 0.01 {
        0.01
      } else if duty > 0.99 {
        0.99
      } else {
        duty
      }
      if p < d {
        1.0
      } else {
        -1.0
      }
    }
    Sawtooth => 2.0 * p - 1.0
    Triangle =>
      if p < 0.5 {
        4.0 * p - 1.0
      } else {
        3.0 - 4.0 * p
      }
    Noise => rng.next_bipolar()
  }
}

///|
/// Generates a continuous audio buffer playing a constant pitch tone for a given duration.
pub fn render_tone(
  waveform : Waveform,
  frequency : Double,
  duration_sec : Double,
  sample_rate : Int,
  volume : Double
) -> AudioBuffer {
  let sr = if sample_rate <= 0 { 44100 } else { sample_rate }
  let dur = if duration_sec < 0.0 { 0.0 } else { duration_sec }
  let num_samples = (dur * sr.to_double()).to_int()
  let buffer = AudioBuffer::new(sr, num_samples)
  let phase_inc = if frequency <= 0.0 { 0.0 } else { frequency / sr.to_double() }
  let rng = Rng::new(42U)
  let mut phase = 0.0

  for i = 0; i < num_samples; i = i + 1 {
    let s = sample_waveform(waveform, phase, rng) * volume
    buffer.push(s)
    phase = phase + phase_inc
    if phase >= 1.0 {
      phase = phase - phase.floor()
    }
  }

  buffer
}
