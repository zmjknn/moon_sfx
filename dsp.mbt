///|
/// Filter type for digital biquad filtering.
pub(all) enum FilterType {
  LowPass
  HighPass
  BandPass
} derive(Eq, Debug)

///|
/// Digital biquad IIR filter implementing Robert Bristow-Johnson Audio EQ Cookbook algorithms.
pub struct BiquadFilter {
  mut b0 : Double
  mut b1 : Double
  mut b2 : Double
  mut a1 : Double
  mut a2 : Double
  mut x1 : Double
  mut x2 : Double
  mut y1 : Double
  mut y2 : Double
}

///|
/// Creates a new BiquadFilter with given filter type, cutoff frequency, and resonance Q factor.
pub fn BiquadFilter::new(
  filter_type : FilterType,
  cutoff_freq : Double,
  resonance_q : Double,
  sample_rate : Int
) -> BiquadFilter {
  let sr = if sample_rate <= 0 { 44100.0 } else { sample_rate.to_double() }
  let nyquist = sr * 0.5
  let cutoff = if cutoff_freq <= 10.0 {
    10.0
  } else if cutoff_freq >= nyquist - 100.0 {
    nyquist - 100.0
  } else {
    cutoff_freq
  }
  let q = if resonance_q <= 0.1 { 0.1 } else { resonance_q }

  let w0 = two_pi * cutoff / sr
  let cos_w0 = @math.cos(w0)
  let sin_w0 = @math.sin(w0)
  let alpha = sin_w0 / (2.0 * q)

  let mut b0 = 0.0
  let mut b1 = 0.0
  let mut b2 = 0.0
  let a0 = 1.0 + alpha
  let a1 = -2.0 * cos_w0
  let a2 = 1.0 - alpha

  match filter_type {
    LowPass => {
      b0 = (1.0 - cos_w0) * 0.5
      b1 = 1.0 - cos_w0
      b2 = (1.0 - cos_w0) * 0.5
    }
    HighPass => {
      b0 = (1.0 + cos_w0) * 0.5
      b1 = -(1.0 + cos_w0)
      b2 = (1.0 + cos_w0) * 0.5
    }
    BandPass => {
      b0 = alpha
      b1 = 0.0
      b2 = -alpha
    }
  }

  // Normalize by a0
  b0 = b0 / a0
  b1 = b1 / a0
  b2 = b2 / a0
  let norm_a1 = a1 / a0
  let norm_a2 = a2 / a0

  { b0, b1, b2, a1: norm_a1, a2: norm_a2, x1: 0.0, x2: 0.0, y1: 0.0, y2: 0.0 }
}

///|
/// Dynamically updates the cutoff frequency and recalculates filter coefficients.
/// Enables continuous dynamic filter sweeping during audio rendering without allocating new objects.
pub fn BiquadFilter::update_cutoff(
  self : BiquadFilter,
  filter_type : FilterType,
  cutoff_freq : Double,
  resonance_q : Double,
  sample_rate : Int
) -> Unit {
  let sr = if sample_rate <= 0 { 44100.0 } else { sample_rate.to_double() }
  let nyquist = sr * 0.5
  let cutoff = if cutoff_freq <= 10.0 {
    10.0
  } else if cutoff_freq >= nyquist - 100.0 {
    nyquist - 100.0
  } else {
    cutoff_freq
  }
  let q = if resonance_q <= 0.1 { 0.1 } else { resonance_q }

  let w0 = two_pi * cutoff / sr
  let cos_w0 = @math.cos(w0)
  let sin_w0 = @math.sin(w0)
  let alpha = sin_w0 / (2.0 * q)

  let mut b0 = 0.0
  let mut b1 = 0.0
  let mut b2 = 0.0
  let a0 = 1.0 + alpha
  let a1 = -2.0 * cos_w0
  let a2 = 1.0 - alpha

  match filter_type {
    LowPass => {
      b0 = (1.0 - cos_w0) * 0.5
      b1 = 1.0 - cos_w0
      b2 = (1.0 - cos_w0) * 0.5
    }
    HighPass => {
      b0 = (1.0 + cos_w0) * 0.5
      b1 = -(1.0 + cos_w0)
      b2 = (1.0 + cos_w0) * 0.5
    }
    BandPass => {
      b0 = alpha
      b1 = 0.0
      b2 = -alpha
    }
  }

  self.b0 = b0 / a0
  self.b1 = b1 / a0
  self.b2 = b2 / a0
  self.a1 = a1 / a0
  self.a2 = a2 / a0
}

///|
/// Processes a single input sample through the biquad filter.
pub fn BiquadFilter::process(self : BiquadFilter, x : Double) -> Double {
  let y = self.b0 * x + self.b1 * self.x1 + self.b2 * self.x2 -
    self.a1 * self.y1 -
    self.a2 * self.y2
  self.x2 = self.x1
  self.x1 = x
  self.y2 = self.y1
  self.y1 = y
  y
}

///|
/// Applies a biquad filter across all samples in the AudioBuffer.
pub fn AudioBuffer::apply_filter(
  self : AudioBuffer,
  filter_type : FilterType,
  cutoff_freq : Double,
  resonance_q : Double
) -> Unit {
  let filter = BiquadFilter::new(
    filter_type,
    cutoff_freq,
    resonance_q,
    self.sample_rate,
  )
  for i = 0; i < self.samples.length(); i = i + 1 {
    self.samples[i] = filter.process(self.samples[i])
  }
}

///|
/// Applies warm cubic overdrive distortion to the buffer.
/// `drive` parameter controls intensity (1.0 = gentle saturation, 5.0+ = heavy fuzz).
pub fn AudioBuffer::apply_overdrive(self : AudioBuffer, drive : Double) -> Unit {
  let d = if drive <= 0.0 { 1.0 } else { drive }
  for i = 0; i < self.samples.length(); i = i + 1 {
    let x = self.samples[i] * d
    let y = if x > 1.5 {
      1.0
    } else if x < -1.5 {
      -1.0
    } else {
      x - x * x * x / 3.0
    }
    self.samples[i] = y / (if d > 1.0 { d * 0.7 } else { 1.0 })
  }
}

///|
/// Applies a feedback echo / delay effect to the audio buffer.
pub fn AudioBuffer::apply_echo(
  self : AudioBuffer,
  delay_seconds : Double,
  feedback : Double,
  wet_mix : Double
) -> Unit {
  if delay_seconds <= 0.001 || feedback <= 0.0 {
    return
  }
  let delay_samples = (delay_seconds * self.sample_rate.to_double()).to_int()
  if delay_samples <= 0 || delay_samples >= self.samples.length() {
    return
  }
  let fb = if feedback > 0.95 { 0.95 } else { feedback }
  let mix = if wet_mix < 0.0 { 0.0 } else if wet_mix > 1.0 { 1.0 } else { wet_mix }

  for i = delay_samples; i < self.samples.length(); i = i + 1 {
    let delayed_sample = self.samples[i - delay_samples]
    self.samples[i] = self.samples[i] * (1.0 - mix * 0.5) + delayed_sample * fb * mix
  }
}

///|
/// Bitcrushes and downsamples the audio buffer to emulate classic 8-bit / 12-bit lo-fi retro sound chips.
pub fn AudioBuffer::apply_bitcrush(
  self : AudioBuffer,
  bits : Int,
  downsample_factor : Int
) -> Unit {
  let b = if bits < 2 { 2 } else if bits > 16 { 16 } else { bits }
  let factor = if downsample_factor < 1 { 1 } else { downsample_factor }
  let steps = @math.pow(2.0, (b - 1).to_double())

  let mut hold_val = 0.0
  for i = 0; i < self.samples.length(); i = i + 1 {
    if i % factor == 0 {
      let mut s = self.samples[i]
      if s > 1.0 {
        s = 1.0
      } else if s < -1.0 {
        s = -1.0
      }
      // Quantize to discrete steps
      let quantized = (s * steps).round() / steps
      hold_val = quantized
    }
    self.samples[i] = hold_val
  }
}
